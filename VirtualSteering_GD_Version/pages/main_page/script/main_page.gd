extends Node2D
class_name SteeringWheel

var throttle_value : float = 0.0
var brake_value : float = 0.0
var hand_brake_value : float = 0.0
var raw_wheel_angle : float = 0.0
var wheel_angle : float = 0.0
var wheel_angle_degree : float = 0.0
var horn_on : bool = false

var roll_acc_bias : float = 0.0
var gravity: Vector3 = Vector3.ZERO
var raw_roll_acc : float = 0.0
var roll_acc : float  = 0.0
var gyroscope: Vector3 = Vector3.ZERO

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
	
	gravity = Input.get_gravity()
	raw_roll_acc = atan2(-gravity.x, -gravity.y) 
	roll_acc = raw_roll_acc - roll_acc_bias
	gyroscope = Input.get_gyroscope()
	raw_wheel_angle = raw_wheel_angle + gyroscope.z * delta
	if nearly_is(roll_acc, 0, PI * 2 / 180) or nearly_is(roll_acc, PI / 2, PI / 180) or nearly_is(roll_acc, -PI / 2, PI / 180):
		raw_wheel_angle = roll_acc
	if raw_wheel_angle > PI:
		roll_acc += 2 * PI
	if raw_wheel_angle < -PI:
		roll_acc -= 2 * PI
	wheel_angle = lerp_angle(roll_acc, raw_wheel_angle, k) 
	wheel_angle_degree = wheel_angle * (180 / PI)
	
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
	
	var raw_data = receiver.receive()
	if raw_data != null:
		var data_obj = JSON.parse_string((raw_data as PackedByteArray).get_string_from_utf8())
		if data_obj["sender"] == 'pc':
			if (%TextEdit as TextEdit).visible:
				(%TextEdit as TextEdit).text = str(data_obj)
			connection_lab.text = "connected"
			timer.stop()
			connection_lab.label_settings.font_color = Color("b5e1ff")
			speed = data_obj["speed"]
			gear_num = data_obj["gear"]
			rpm = data_obj["rpm"]
			max_rpm = data_obj["max_rpm"]
			car_damage = data_obj["car_damage"]
			#print(rpm)
	else:
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
