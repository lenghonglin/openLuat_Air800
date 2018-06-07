module(...,package.seeall)

--[[
模块名称：“GPS应用”测试
模块功能：测试gps.lua的接口
模块最后修改时间：2017.02.16
]]

require"gps"
require"agps"
require"lbsloc"

--blat经度   blng纬度
blng = ""
blat = ""

--[[
函数名：print
功能  ：打印接口，此文件中的所有打印都会加上test前缀
参数  ：无
返回值：无
]]
local function print(...)
  _G.print("bgps",...)
end

--[[
判断是否定位成功  gps.isfix()
获取经纬度信息      gps.getgpslocation()
速度 gps.getgpsspd()
方向角 gps.getgpscog()
海拔 gps.getaltitude()
]]

local function test1cb(cause)
  print("test1cb",cause,gps.isfix(),gps.getgpslocation(),gps.getgpsspd(),gps.getgpscog(),gps.getaltitude())
end

--[[
函数名：gpsOpen
功能：开启GPS
参数：无
返回值：无
]]
local function gpsOpen()
    --默认模式 GPS就会一直开启，永远不会关闭
   gps.open(gps.DEFAULT,{cause="TEST1",cb=test1cb})
end

--[[
函数名：qrygps
功能  ：查询GPS位置请求
参数  ：无
返回值：无
]]
local function qrygps()
  qryaddr = not qryaddr
  lbsloc.request(getgps,qryaddr)
end

--[[
函数名：getgps
功能  ：获取经纬度后的回调函数
参数  ：
    result：number类型，获取结果，0表示成功，其余表示失败。此结果为0时下面的5个参数才有意义
    lat：string类型，纬度，整数部分3位，小数部分7位，例如031.2425864
    lng：string类型，经度，整数部分3位，小数部分7位，例如121.4736522
    addr：string类型，GB2312编码的位置字符串。调用lbsloc.request查询经纬度，传入的第二个参数为true时，才返回本参数
    latdm：string类型，纬度，度分格式，整数部分5位，小数部分6位，dddmm.mmmmmm，例如03114.555184
    lngdm：string类型，纬度，度分格式，整数部分5位，小数部分6位，dddmm.mmmmmm，例如12128.419132
返回值：无
]]
function getgps(result,lat,lng,addr,latdm,lngdm)
  print("getgps",result,lat,lng,addr,latdm,lngdm)
  --获取经纬度成功
  if result==0 then
  --失败
  else
  end
  blat = lat
  blng = lng
end

--[[
函数名：nemacb
功能  ：NEMA数据的处理回调函数
参数  ：
    data：一条NEMA数据
返回值：无
]]
local function nemacb(data)
  print("nemacb",data)
end

--[[
函数名：split
功能：分割字符串
参数：
    s：待分割的字符串
    sp：分割标志
返回值：table类型，分割后的字符串    
]]
function split(s, sp)  
    local res = {}  
  
    local temp = s  
    local len = 0  
    while true do  
        len = string.find(temp, sp)  
        if len ~= nil then  
            local result = string.sub(temp, 1, len-1)  
            temp = string.sub(temp, len+1)  
            table.insert(res, result)  
        else  
            table.insert(res, temp)  
            break  
        end  
    end  
    return res  
end 

--[[
函数名：gpsGet
功能：获取GPS值，如果定位成功就赋值给blng和blat。如果失败就基站定位
参数：无
返回值：无
]]
local function gpsGet()
  if gps.isfix() == true then
     print("success",gps.isfix(),gps.getgpslocation(),gps.getgpsspd(),gps.getgpscog(),gps.getaltitude())
     local gpsStr = gps.getgpslocation()
     local temp = split(gpsStr,",")
     blng = temp[2]
     blat = temp[4]
  end
  if gps.isfix() == false then
    print("failed lbs")
    sys.timer_start(qrygps,100)
  end
  
end

--[[
函数名：returnBlat
功能：返回经度
参数：无
返回值：无
]]
function returnBlat()
  return blat
end

--[[
函数名：returnBlng
功能：返回纬度
参数：无
返回值：无
]]
function returnBlng()
  return blng
end

--[[
函数：gpsInit
功能：初始化gps
参数：无
返回值：无
]]
local function gpsInit()
  gps.init()
  --设置GPS+BD定位
  --如果不调用此接口，默认也为GPS+BD定位
  --如果仅GPS定位，参数设置为1
  --如果仅BD定位，参数设置为2
  gps.setfixmode(0)
  --设置仅gps.lua内部处理NEMA数据
  --如果不调用此接口，默认也为仅gps.lua内部处理NEMA数据
  --如果gps.lua内部不处理，把nema数据通过回调函数cb提供给外部程序处理，参数设置为1,nemacb
  --如果gps.lua和外部程序都处理，参数设置为2,nemacb
  gps.setnemamode(0)
  --如果需要GPS的时间来同步模块时间，则打开下面这行注释的代码
  --gps.settimezone(gps.GPS_BEIJING_TIME)
  --gps_open()
end

sys.timer_start(gpsInit,1000)
--每过10s获取一个gps数据
sys.timer_loop_start(gpsGet,10000)

