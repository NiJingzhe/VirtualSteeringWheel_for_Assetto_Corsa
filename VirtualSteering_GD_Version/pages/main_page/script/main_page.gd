extends Node2D
class_name SteeringWheel

var throttle_value : float = 0.0
var brake_value : float = 0.0
var raw_wheel_angle : float = 0.0
var wheel_angle : float = 0.0
var wheel_angle_degree : float = 0.0

var speed : float = 0.0
var gear_num : int = 0
var rpm : float = 0
var max_rpm : float = 1
var timeout : bool = false

var car_damage : float = 0.0
var last_car_damage : float = 0.0
var slip_vibe : float = 0.0

var speed_text : String = ''
var gear_text : String = ''

var k : float = 0.9

@onready var throttle_btn : TouchScreenButton = %throttleButton
@onready var brake_btn : TouchScreenButton = %brakeButton
@onready var reset_btn : TouchScreenButton = %resetButton
@onready var speed_lab : Label = %speedLabel
@onready var gear_lab : Label = %gearLabel
@onready var connection_lab : Label = %connectionLabel
@onready var angle_lab : Label = %angleLabel
@onready var abs_lab : Label = %absLabel
@onready var rpm_progress : TextureProgressBar = %rpmProgressBar

@onready var sender : UDPSender = %UDPSender as UDPSender
@onready var receiver : UDPReceiver = %UDPReceiver as UDPReceiver
@onready var timer : Timer = %Timer as Timer


func _ready():
	sender.init_sender()
	receiver.init_receiver()
	
func _physics_process(delta):
	
	var gravity: Vector3 = Input.get_gravity()
	var roll_acc = atan2(-gravity.x, -gravity.y) 
	var gyroscope: Vector3 = Input.get_gyroscope()
	raw_wheel_angle = raw_wheel_angle + gyroscope.z * delta
	if raw_wheel_angle > PI:
		roll_acc += 2 * PI
	if raw_wheel_angle < -PI:
		roll_acc -= 2 * PI
	wheel_angle = lerp_angle(roll_acc, raw_wheel_angle, k) 
	wheel_angle_degree = wheel_angle * (180 / PI)
	
	if throttle_btn.is_pressed():
		throttle_value = 100
	else:
		throttle_value = 0
		
	if brake_btn.is_pressed():
		brake_value = 100
	else:
		brake_value = 0
	
	if reset_btn.is_pressed():
		wheel_angle = 0.0
		raw_wheel_angle = 0.0
		roll_acc = 0.0
		
		
func _process(delta):
	var message = {
		"sender" : "mobile", 
		"angle" : wheel_angle_degree,
		"throttle" : throttle_value,
		"brake" : brake_value
	}
	sender.sendto("255.255.255.255", 20015, JSON.stringify(message))
	
	var raw_data = receiver.receive()
	if raw_data != null:
		var data_obj = JSON.parse_string((raw_data as PackedByteArray).get_string_from_utf8())
		if data_obj["sender"] == 'pc':
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
		
func gear_num2str(gear_num):
	if gear_num == 0:
		return 'R'
	if gear_num == 1:
		return 'N'
	else:
		return str(gear_num-1)
		


func _on_timer_timeout():
	timeout = true
