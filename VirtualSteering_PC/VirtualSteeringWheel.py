from lib.VirtualJoy import VirtualJoy
from lib.SpeedMonitor import SpeedMonitor

CONFIG = {  
    "MAX_ANGLE": 300,
    "SEND_PORT": 4001,
    "RECV_PORT": 20015,
}

if __name__ == "__main__":
    virtualJoy = VirtualJoy(CONFIG)
    speedMonitor = SpeedMonitor(CONFIG)
    while True:
        virtualJoy.update()
        speedMonitor.setSteeringIP(virtualJoy.getSteeringIP())
        speedMonitor.update()