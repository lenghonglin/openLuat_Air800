require"misc"
require"mqtt"
require"common"
require"uiwin"
require"prompt"
require"idle"
module(...,package.seeall)

local ssub,schar,smatch,sbyte,slen = string.sub,string.char,string.match,string.byte,string.len
--测试时请搭建自己的服务器
local PROT,ADDR,PORT = "TCP","lbsmqtt.airm2m.com",1883
local mqttclient
local msg

--[[
函数名：print
功能  ：打印接口，此文件中的所有打印都会加上test前缀
参数  ：无
返回值：无
]]
local function print(...)
	_G.print("test",...)
end

local qos0cnt,qos1cnt = 1,1

--[[
函数名：pubqos0testsndcb
功能  ：“发布1条qos为0的消息”发送结果的回调函数
参数  ：
		usertag：调用mqttclient:publish时传入的usertag
		result：true表示发送成功，false或者nil发送失败
返回值：无
]]
local function pubqos0testsndcb(usertag,result)
	print("pubqos0testsndcb",usertag,result)
	sys.timer_start(pubqos0test,10000)
	qos0cnt = qos0cnt+1
end

--[[
函数名：pubqos0test
功能  ：发布1条qos为0的消息
参数  ：无
返回值：无
]]
function pubqos0test()
	--注意：在此处自己去控制payload的内容编码，mqtt库中不会对payload的内容做任何编码转换
  mqttclient:publish("/v1/device/"..misc.getimei().."/qos0topic","qos0data",0,pubqos0testsndcb,"publish0test_"..qos0cnt) --在mqtt例程中的46行
end



--[[
函数名：subackcb
功能  ：MQTT SUBSCRIBE之后收到SUBACK的回调函数
参数  ：
		usertag：调用mqttclient:subscribe时传入的usertag
		result：true表示订阅成功，false或者nil表示失败
返回值：无
]]
local function subackcb(usertag,result)
	print("subackcb",usertag,result)
end

--[[
函数名：rcvmessage
功能  ：收到PUBLISH消息时的回调函数
参数  ：
		topic：消息主题（gb2312编码）
		payload：消息负载（原始编码，收到的payload是什么内容，就是什么内容，没有做任何编码转换）
		qos：消息质量等级
返回值：无
]]
local function rcvmessagecb(topic,payload,qos)
	print("rcvmessagecb",topic,payload,qos)
	disp.clear()
	disp.puttext("收到消息："..payload,0,0)
	disp.update()
end

--[[
函数名：discb
功能  ：MQTT连接断开后的回调
参数  ：无		
返回值：无
]]
local function discb()
	print("discb")
	--20秒后重新建立MQTT连接
	sys.timer_start(connect,20000)
end

--[[
函数名：disconnect
功能  ：断开MQTT连接
参数  ：无		
返回值：无
]]
local function disconnect()
	mqttclient:disconnect(discb)
end

--[[
函数名：connectedcb
功能  ：MQTT CONNECT成功回调函数
参数  ：无		
返回值：无
]]
local function connectedcb()
	print("connectedcb")
	disp.puttext("连接成功...",16,30)
	disp.update()
	--订阅主题
  mqttclient:subscribe({{topic="/v1/device/"..misc.getimei().."/event0",qos=0}}, subackcb, "subscribetest")   --在mqtt例程中的130行  
	--注册事件的回调函数，MESSAGE事件表示收到了PUBLISH消息
	mqttclient:regevtcb({MESSAGE=rcvmessagecb})
	--发布一条qos为0的消息
--	pubqos0test()
	--20秒后主动断开MQTT连接
	--sys.timer_start(disconnect,20000)
end

--[[
函数名：connecterrcb
功能  ：MQTT CONNECT失败回调函数
参数  ：
		r：失败原因值
			1：Connection Refused: unacceptable protocol version
			2：Connection Refused: identifier rejected
			3：Connection Refused: server unavailable
			4：Connection Refused: bad user name or password
			5：Connection Refused: not authorized
返回值：无
]]
local function connecterrcb(r)
	print("connecterrcb",r)
end

--[[
函数名：sckerrcb
功能  ：SOCKET异常回调函数（注意：此处是恢复异常的一种方式<进入飞行模式，半分钟后退出飞信模式>，如果无法满足自己的需求，可自己进行异常处理）
参数  ：
		r：string类型，失败原因值
			CONNECT：mqtt内部，socket一直连接失败，不再尝试自动重连
			SVRNODATA：mqtt内部，3倍KEEP ALIVE时间+半分钟，终端和服务器没有任何数据通信，则认为出现通信异常
返回值：无
]]
local function sckerrcb(r)
	print("sckerrcb",r)
	misc.setflymode(true)
	sys.timer_start(misc.setflymode,30000,false)
end

function connect()
	--连接mqtt服务器
	--mqtt lib中，如果socket出现异常，默认会自动重启软件
	--注意sckerrcb参数，如果打开了注释掉的sckerrcb，则mqtt lib中socket出现异常时，不再自动重启软件，而是调用sckerrcb函数
	mqttclient:connect("openluat",240,"luat","luat",connectedcb,connecterrcb--[[,sckerrcb]])
	disp.puttext("正在连接Luatyun...",16,0)
  disp.update()
end

local function statustest()
	print("statustest",mqttclient:getstatus())
end

--[[
函数名：imeirdy
功能  ：IMEI读取成功，成功后，才去创建mqtt client，连接服务器，因为用到了IMEI号
参数  ：无		
返回值：无
]]
local function imeirdy()
	--创建一个mqtt client，默认使用的MQTT协议版本是3.1，如果要使用3.1.1，打开下面的注释--[[,"3.1.1"]]即可
	mqttclient = mqtt.create(PROT,ADDR,PORT--[[,"3.1.1"]])
	--配置遗嘱参数,如果有需要，打开下面一行代码，并且根据自己的需求调整will参数
	--mqttclient:configwill(1,0,0,"/willtopic","will payload")
	--配置clean session标志，如果有需要，打开下面一行代码，并且根据自己的需求配置cleansession；如果不配置，默认为1
	--mqttclient:setcleansession(0)
	--查询client状态测试
	--sys.timer_loop_start(statustest,1000)
	connect()
end

local procer =
{
	IMEI_READY = imeirdy,
}
--注册消息的处理函数
sys.regapp(procer)
