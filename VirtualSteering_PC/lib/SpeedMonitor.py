from lib.DataSender import sender
from pyaccsharedmemory import accSharedMemory

class SpeedMonitor(object):

    def __init__(self, CONFIG):
        self.port = CONFIG["SEND_PORT"]
        self.sender = sender(HOST_IP="255.255.255.255", PORT=self.port)
        self.speed = 0.0
        self.gear = 1
        self.asm = accSharedMemory()

    def update(self):
        sm = self.asm.read_shared_memory()
        if (sm is not None):
            #print("memory read success")
            self.speed = sm.Physics.speed_kmh
            self.gear = sm.Physics.gear
            self.rpm = sm.Physics.rpm
            self.max_rpm = sm.Static.max_rpm
            self.car_damage_value = sm.Physics.car_damage.center
            self.slip_value = sm.Physics.wheel_slip.front_left + sm.Physics.wheel_slip.front_right + sm.Physics.wheel_slip.rear_left + sm.Physics.wheel_slip.rear_right
            #print("speed: " + str(self.speed) + " gear: " + str(self.gear))
            self.sender.send({
                "sender": "pc", 
                "speed": self.speed, 
                "gear": self.gear, 
                "rpm": self.rpm, 
                "max_rpm": self.max_rpm,
                "car_damage": self.car_damage_value,
                "slip_value" : self.slip_value
            })
        else:
            print("Please start your game!")
    
    def setSteeringIP(self, IP):
        self.sender = sender(HOST_IP=IP, PORT=self.port)
        #print("set steering IP success")
        