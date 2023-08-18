extends Node2D
class_name SteeringWheel

var throttle_value : float = 0.0
var brake_value : float = 0.0
var hand_brake_value : float = 0.0
var raw_wheel_angle : float = 0.0
var wheel_angle_bias : float = 0.0
var wheel_angle : float = 0.0
var wheel_angle_degree : float = 0.0
var horn_on : bool = false

var roll_acc_bias : float = 0.0
var gravity: Vector3 = Vector3.ZERO
var raw_roll_acc : float = 0.0
var roll_acc : float  = 0.0
var gyroscope: Vector3 = Vector3.ZERO
var half_round_counter : int = 0

var speed : float = 0.0
var gear_num : int = 0
var rpm : float = 0
var max_rpm : float = 1
var drs_allow : bool = false
var timeout : bool = false

var car_damage : float = 0.0
var last_car_damage : float = 0.0
var slip_vibe : float = 0.0

var speed_text : String = ''
var gear_text : String = ''

var k : float = 0.9

@onready var throttle_btn : TouchScreenButton = %throttleButton
@onready var brake_btn : TouchScreenButton = %brakeButton
@onready var hand_brake_btn : TouchScreenButton = %handbrakeButton
@onready var gear_up_btn : TouchScreenButton = %gearupButton
@onready var gear_down_btn : TouchScreenButton = %geardownButton 
@onready var horn_btn : TouchScreenButton = %hornButton 
@onready var reset_btn : TouchScreenButton = %resetButton
@onready var speed_lab : Label = %speedLabel
@onready var gear_lab : Label = %gearLabel
@onready var connection_lab : Label = %connectionLabel
@onready var angle_lab : Label = %angleLabel
@onready var rpm_progress : TextureProgressBar = %rpmProgressBar

@onready var sender : UDPSender = %UDPSender as UDPSender
@onready var receiver : UDPReceiver = %UDPReceiver as UDPReceiver
@onready var timer : Timer = %Timer as Timer


func _ready():
	sender.init_sender()
	receiver.init_receiver()
	
func _physics_process(delta):
	#读取重力数计算raw的重力夹角
	gravity = Input.get_gravity()
	raw_roll_acc = atan2(-gravity.x, -gravity.y)
	
	# 考虑到任意位置重置角度所以要剪掉bias，并根据半圈计数器±对应的PI才是正确的
	#这是为了能够记录任意旋转度数，实现对两侧共900度的真车方向盘角度模拟
	roll_acc = raw_roll_acc - roll_acc_bias + half_round_counter * PI
	if roll_acc >= 450 / 180.0 * PI:
		roll_acc = 450 / 180.0 * PI
	if roll_acc <= -450 / 180.0 * PI:
		roll_acc = -450 / 180.0 * PI
			
	#读取陀螺仪角速度数据
	gyroscope = Input.get_gyroscope()
	#角速度积分得到raw的角度
	raw_wheel_angle = raw_wheel_angle + gyroscope.z * delta
	#限制于450°之间
	if raw_wheel_angle >= 450 / 180.0 * PI:
		raw_wheel_angle = 450 / 180.0 * PI
	if raw_wheel_angle <= -450 / 180.0 * PI:
		raw_wheel_angle = -450 / 180.0 * PI
	#为了防止积分零飘，我们在几个关键位置附近将角度重置为重力角度数据
	if nearly_is(roll_acc, half_round_counter * PI + PI * 3 / 4, PI * 6/ 180) or  \
	   nearly_is(roll_acc, half_round_counter * PI - PI * 3 / 4, PI * 6/ 180) or  \
	   nearly_is(roll_acc, half_round_counter * PI + PI * 2 / 4, PI * 6/ 180) or  \
	   nearly_is(roll_acc, half_round_counter * PI - PI * 2 / 4, PI * 6/ 180) or  \
	   nearly_is(roll_acc, half_round_counter * PI + PI * 1 / 4, PI * 6/ 180) or  \
	   nearly_is(roll_acc, half_round_counter * PI - PI * 1 / 4, PI * 6/ 180) or  \
	   nearly_is(roll_acc, half_round_counter * PI, PI * 10 / 180):
		raw_wheel_angle = roll_acc
		
	#根据raw的wheel angle判断是不是超过了一圈，如果是，那就对半圈计数器±2		
	if raw_wheel_angle > PI * (half_round_counter + 1):                 
		half_round_counter += 2 if half_round_counter < 2 else 0
	elif raw_wheel_angle < PI * (half_round_counter - 1):                
		half_round_counter -= 2 if half_round_counter > -2 else 0
		
	if (%TextEdit as TextEdit).visible:
		(%TextEdit as TextEdit).text =                                         \
			'roll_acc : ' + '%.2f\n' % roll_acc +                              \
			'raw_wheel_angle : ' + '%.2f\n' % raw_wheel_angle +                \
			'half_round_counter : ' + '%d\n' % half_round_counter
		
	#之后我们在一般位置融合重力角度数据和角速度积分数据得到最后采用的wheel angle
	wheel_angle = raw_wheel_angle 
	wheel_angle_degree = wheel_angle * (180 / PI)
	
	#发送数据，因为该过程并不需要等待，所以可以考虑放在物理处理步骤中
	var message = {
		"sender" : "mobile", 
		"angle" : wheel_angle_degree,
		"throttle" : throttle_value,
		"brake" : brake_value,
		"hand_brake" : hand_brake_value,
		"horn" : horn_on,
		"gear_up": gear_up_btn.is_pressed(),
		"gear_down" : gear_down_btn.is_pressed()
	}
	sender.sendto("255.255.255.255", 20015, JSON.stringify(message))
	
	#UI更新放在物理步骤中是为了更流畅的更新UI
	speed_text = "%.0f" % speed
	gear_text = gear_num2str(gear_num)
	
	angle_lab.text = "%.1f" % wheel_angle_degree
	speed_lab.text = speed_text
	gear_lab.text = gear_text
	rpm_progress.value = (rpm / max_rpm) * 100
	
	if car_damage > last_car_damage:
		Input.vibrate_handheld(300)
		
	last_car_damage = car_damage
	
	if gear_text == 'R':
		gear_lab.label_settings.font_color = Color("e19b00")
	elif gear_text == 'N':
		gear_lab.label_settings.font_color = Color("00bee3")
	else:
		gear_lab.label_settings.font_color = Color("b5e1ff")
	
func _process(_delta):
	#UI事件处理就放在普通的处理函数中了
	if throttle_btn.is_pressed():
		throttle_value = 100
	else:
		throttle_value = 0
		
	if brake_btn.is_pressed():
		brake_value = 100
	else:
		brake_value = 0
		
	if hand_brake_btn.is_pressed():
		hand_brake_value = 100
	else:
		hand_brake_value = 0
	
	if horn_btn.is_pressed():
		horn_on = true
	else:
		horn_on = false
	
	if reset_btn.is_pressed():
		roll_acc_bias = raw_roll_acc
		raw_wheel_angle = 0
		half_round_counter = 0
	
	#由于接收数据包可能会需要等待，故放在普通处理过程中
	var raw_data = receiver.receive()
	if raw_data != null:
		var data_obj =                                                         \
		JSON.parse_string((raw_data as PackedByteArray).get_string_from_utf8())
		
		if data_obj["sender"] == 'pc':
			#if (%TextEdit as TextEdit).visible:
			#	(%TextEdit as TextEdit).text = str(data_obj)
			connection_lab.text = "connected"
			timer.stop()
			connection_lab.label_settings.font_color = Color("b5e1ff")
			speed = data_obj["speed"]
			gear_num = data_obj["gear"]
			rpm = data_obj["rpm"]
			max_rpm = data_obj["max_rpm"]
			car_damage = data_obj["car_damage"]
			#print(rpm)
	else: #由于数据包确实存在断续的情况，所以接收不到数据包一段时间（timer计时）才能够被判定为断开链接
		if timer.is_stopped():
			timer.start()
		if timeout:
			connection_lab.text = "disconnected"
			connection_lab.label_settings.font_color = Color("e31913")
			speed = 0
			gear_num = 1
			rpm = 0
			timer.stop()
			timeout = false

		
func gear_num2str(gear_num_):
	if gear_num_ == 0:
		return 'R'
	if gear_num_ == 1:
		return 'N'
	else:
		return str(gear_num_-1)
		
func nearly_is(src, tgt, eps):
	return src >= tgt - eps and src <= tgt + eps

func _on_timer_timeout():
	timeout = true
