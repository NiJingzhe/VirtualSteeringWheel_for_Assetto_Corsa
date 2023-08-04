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
                
        #print("virtual steering wheel connect success")
        self.gamepad.left_joystick_float(x_value_float = self.angle / self.MAX_ANGLE, y_value_float = 0.0)
        self.gamepad.right_trigger_float(value_float = self.throttle / 100)
        self.gamepad.left_trigger_float(value_float = self.brake / 100)
        self.gamepad.update()

    def getSteeringIP(self):
        return self.receiver.getSteeringIP()