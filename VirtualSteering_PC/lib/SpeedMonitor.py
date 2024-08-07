from lib.DataSender import sender
from pyaccsharedmemory import accSharedMemory
import sys
import time

class SpeedMonitor(object):

    def __init__(self, CONFIG):
        self.port = CONFIG["SEND_PORT"]
        self.sender = sender(HOST_IP="255.255.255.255", PORT=self.port)
        self.speed = 0.0
        self.gear = 1
        self.asm = accSharedMemory()

    def update(self):
        sm = self.asm.read_shared_memory()
        if sm is not None:
            # 读取所需的参数
            self.speed = sm.Physics.speed_kmh
            self.gear = sm.Physics.gear
            self.rpm = sm.Physics.rpm
            self.max_rpm = sm.Static.max_rpm
            self.car_damage_value = sm.Physics.car_damage.center
            self.slip_value = (
                sm.Physics.wheel_slip.front_left +
                sm.Physics.wheel_slip.front_right +
                sm.Physics.wheel_slip.rear_left +
                sm.Physics.wheel_slip.rear_right
            )

            # 发送数据
            self.sender.send({
                "sender": "pc",
                "speed": self.speed,
                "gear": self.gear,
                "rpm": self.rpm,
                "max_rpm": self.max_rpm,
                "car_damage": self.car_damage_value,
                "slip_value": self.slip_value,
            })

            # # 准备输出字符串
            # output = (
            #     f"Speed: {self.speed:.2f} km/h\n"
            #     f"Gear: {self.gear}\n"
            #     f"RPM: {self.rpm}\n"
            #     f"Max RPM: {self.max_rpm}\n"
            #     f"Car Damage: {self.car_damage_value}\n"
            #     f"Slip Value: {self.slip_value:.2f}\n"
            # )

            # # 清除控制台并输出最新参数
            # sys.stdout.write("\033[2J\033[H")  # 清除控制台并移动光标到左上角
            # print(output)

        else:
            sys.stdout.write("\033[F\033[K")
            print("Please start your game!")

    def setSteeringIP(self, IP):
        self.sender = sender(HOST_IP=IP, PORT=self.port)
        #print("set steering IP success")
