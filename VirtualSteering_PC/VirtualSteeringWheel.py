from lib.VirtualJoy import VirtualJoy
from lib.SpeedMonitor import SpeedMonitor
import multiprocessing as mp
import keyboard

CONFIG = {  
    "MAX_ANGLE": 110,
    "SEND_PORT": 4001,
    "RECV_PORT": 20015,
}

if __name__ == "__main__":
    
    if not CONFIG["SEND_PORT"] or not CONFIG["RECV_PORT"]:
        print("Please set the ports in the CONFIG dictionary")
        exit(1)
    if not CONFIG["MAX_ANGLE"]:
        print("Please set the MAX_ANGLE in the CONFIG dictionary")
        exit(1)
    if CONFIG["MAX_ANGLE"] < 0 or CONFIG["MAX_ANGLE"] > 170:
        print("MAX_ANGLE should be between 0 and 170")
        exit(1)
    
    virtualJoy = VirtualJoy(CONFIG)
    speedMonitor = SpeedMonitor(CONFIG)

    while True:
        virtualJoy.update() 
        speedMonitor.setSteeringIP(virtualJoy.getSteeringIP())
        speedMonitor.update()
