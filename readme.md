# 虚拟方向盘使用说明
---
## 一、快速入门

  - 安装一个python环境，推荐安装3.10及以上版本
  - 进入`VirtualSteering_PC`文件夹，在命令行中运行指令`pip install -r ./requirement.txt`以安装`vgamepad`库，该库会顺带安装虚拟驱动
  - 进双击运行`run.bat`文件，即可打开虚拟方向盘的PC端程序。
  - 在手机上打开虚拟方向盘APP
  - 若在PC端的控制台窗口观察到持续显示`Please start your game`字样，说明双端启动成功并开始通讯。
  - 进入`Assetto Corsa`，开始一场比赛，进入赛道界面之后应该可以看到APP数显区域左上角的`红色`的`disconnect`字样变为`绿色`的`connect`字样，说明已经成功连接到游戏，并接收到了游戏共享内存的数据。
  
## 二、配置说明
  
  - 打开`VirtualSteering_PC`文件夹下的`VirtualSteeringWheel.py`文件，可以看到如下内容：

    ```python
    
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
    
    ```
    其中`CONFIG`中的配置项含义如下：
    
    - 方向盘最大转角（单侧）
    - 发送端口
    - 接收端口
   
    根据自己的需要可以更改第一个配置，最大支持单侧450度（900度一圈半方向盘）
