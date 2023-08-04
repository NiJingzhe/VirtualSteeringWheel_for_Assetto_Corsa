// index.js
// 获取应用实例
const app = getApp()

Page({
  data: {
    wZ : 0,
    windowHeight : 0,
    angle : 0.0,
    throttle : 0.0,
    brake : 0.0,
    gear: 'N',
    speed: '0'
  },
  onLoad(){
    this.UDP = wx.createUDPSocket()
  },

  onReady(){
    this.UDP.bind(4001)
    const windowInfo = wx.getWindowInfo()
    this.setData({
        windowHeight : windowInfo.screenHeight
    })
  },

  getGearName(gearNum){
    if (gearNum == 0){
        return 'R'
    } 
    else{
        if (gearNum == 1)
            return 'N'
        else
            return (gearNum - 1).toString()
    }
        
  },    

  onShow(){
    wx.startGyroscope({
        interval : "game"
    })
    wx.onGyroscopeChange((result) => {
        this.setData({
            wZ : result.z,
            angle : this.data.angle + result.z
        })
    })
    this.BroadcastInterval = setInterval((this.Broadcast), 10)
    var that = this
    this.UDP.onMessage(
        (res) => {
            if (res.remoteInfo.size > 0) {
        
                let unit8Arr = new Uint8Array(res.message);
                let encodedString = String.fromCharCode.apply(null, unit8Arr);
                let escStr = escape(encodedString);
                let decodedString = decodeURIComponent(escStr);
                
                //console.log('str==='+decodedString)
                let data = JSON.parse(decodedString)
                if (data["sender"] == "speedMonitor"){
                    that.setData({
                        gear : that.getGearName(data["gear"]),
                        speed : parseFloat(data["speed"]).toFixed(0)
                    })
                }
            }
        } 
    )
  },    

  onHide(){
      wx.stopGyroscope()
      this.setData({
          angle : 0.0
      })
      clearInterval(this.BroadcastInterval)
  },

  Broadcast(){
    var messagePack = JSON.stringify({
        sender : "steeringAPP",
        angle : this.data.angle,
        throttle : this.data.throttle,
        brake : this.data.brake
    })
    //console.log(messagePack)

    this.UDP.send({
        address : "255.255.255.255",
        port : 20015,
        message : messagePack
    })
  },

  ResetAngle(){
      this.data.angle = 0
      this.setData({
          angle : 0.0,
      })
  },

  Throttle(){
      this.data.throttle = 100
  },

  ResetThrottle(){
      this.data.throttle = 0
  },

  Brake(){
      this.data.brake = 100
  },

  ResetBrake(){
      this.data.brake = 0
  }
})
