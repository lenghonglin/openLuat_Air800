--- 模块功能：MQTT客户端处理框架
-- @author openLuat
-- @module mqtt.mqttTask
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.28

module(...,package.seeall)

require"misc"
require"mqtt"
require"ntp"
ntp.timeSync()
require"testGps"
local ready = false

--- MQTT连接是否处于激活状态
-- @return 激活状态返回true，非激活状态返回false
-- @usage mqttTask.isReady()
function isReady()
    return ready
end

local function getGps()
    Mlat,Mlng = testGps.printGps()
    log.info("testGps lat,lng",Mlat,Mlng)
    local torigin = 
      {
        datastreams = 
        {{
          id = "gps",
          datapoints = 
          {{
            at = "",
            value = 
            {
              lon = Mlng,
              lat = Mlat,
            }
          }}
        }}
      }

    local msg = json.encode(torigin)
    print("json data",msg)
    local len = msg.len(msg)
    buf = pack.pack("bbbA", 0x01,0x00,len,msg)
    return buf
end


--启动MQTT客户端任务
sys.taskInit(
    function()
        while true do
            --等待网络环境准备就绪
            while not socket.isReady() do sys.waitUntil("IP_READY_IND") end
            local imei = misc.getImei()
            --创建一个MQTT客户端
            local mqttClient = mqtt.client("31609534",600,"142601","rylXjL7yWqNlUzbOCVf4YiT9yls=")
            --阻塞执行MQTT CONNECT动作，直至成功
            --如果使用ssl连接，打开--[[,{caCert="ca.crt"}]]，根据自己的需求配置
            while not mqttClient:connect("183.230.40.39",6002,"tcp"--[[,{caCert="ca.crt"}]]) do
                sys.wait(2000)
            end
            while true do
            	local result = mqttClient:publish("$dp",getGps())
            	if result then
            		log.info("onenet send","success")
            	else
            		log.info("onenet send","failed")
                end
            	sys.wait(20000)
            end
            --断开MQTT连接
            mqttClient:disconnect()
        end
    end
)