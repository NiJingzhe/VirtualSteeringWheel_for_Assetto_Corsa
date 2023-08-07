from lib.DataReceiver import receiver
import vgamepad

class VirtualJoy(object):

    def __init__(self, CONFIG):
        self.MAX_ANGLE = CONFIG["MAX_ANGLE"]
        self.port = CONFIG["RECV_PORT"]
        self.receiver = receiver(self.port)
        self.gamepad = vgamepad.VX360Gamepad()
        self.gamepad.reset()
        self.angle = 0
        self.throttle = 0.0
        self.brake = 0.0
        self.gear_up = False
        self.gear_down = False
        self.horn = False
        self.handbrake = 0.0

    def update(self):
        data = self.receiver.receive()
        if data:
            if data["sender"] == "mobile":
                self.angle = -data['angle']
                if self.angle > self.MAX_ANGLE:
                    self.angle = self.MAX_ANGLE
                elif self.angle < -self.MAX_ANGLE:
                    self.angle = -self.MAX_ANGLE
                
                self.throttle = data['throttle']
                self.brake = data['brake']
                self.handbrake = data['hand_brake']
                self.gear_up = data['gear_up']
                self.gear_down = data['gear_down']
                self.horn = data['horn']
                
        #print("virtual steering wheel connect success")
        self.gamepad.left_joystick_float(x_value_float = self.angle / self.MAX_ANGLE, y_value_float = 0.0)
        self.gamepad.right_trigger_float(value_float = self.throttle / 100)
        self.gamepad.left_trigger_float(value_float = self.brake / 100)
        if self.gear_down and not self.gear_up:
            self.gamepad.press_button(button = vgamepad.XUSB_BUTTON.XUSB_GAMEPAD_LEFT_SHOULDER)
        else:
            self.gamepad.release_button(button = vgamepad.XUSB_BUTTON.XUSB_GAMEPAD_LEFT_SHOULDER)
            
        if self.gear_up and not self.gear_down:
            self.gamepad.press_button(button = vgamepad.XUSB_BUTTON.XUSB_GAMEPAD_RIGHT_SHOULDER)
        else:
            self.gamepad.release_button(button = vgamepad.XUSB_BUTTON.XUSB_GAMEPAD_RIGHT_SHOULDER)

        if self.horn:
            self.gamepad.press_button(button = vgamepad.XUSB_BUTTON.XUSB_GAMEPAD_Y)
        else:
            self.gamepad.release_button(button = vgamepad.XUSB_BUTTON.XUSB_GAMEPAD_Y)

        if self.handbrake > 0.1:
            self.gamepad.press_button(button = vgamepad.XUSB_BUTTON.XUSB_GAMEPAD_B)
        else:
            self.gamepad.release_button(button = vgamepad.XUSB_BUTTON.XUSB_GAMEPAD_B)

        self.gamepad.update()

    def getSteeringIP(self):
        return self.receiver.getSteeringIP()