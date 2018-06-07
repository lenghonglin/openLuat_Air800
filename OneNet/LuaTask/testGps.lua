--- 模块功能：GPS功能测试.
-- @author openLuat
-- @module gps.testGps
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.23

module(...,package.seeall)

require"gps"
require"agps"
require"lbsLoc"
require"common"

local Rlat = ""
local Rlng = ""
--[[
功能  ：发送查询位置请求
参数  ：无
返回值：无
]]
local function reqLbsLoc()
    reqAddr = not reqAddr
    lbsLoc.request(getLocCb,reqAddr)
end

--[[
功能  ：获取基站对应的经纬度后的回调函数
参数  ：
		result：number类型，0表示成功，1表示网络环境尚未就绪，2表示连接服务器失败，3表示发送数据失败，4表示接收服务器应答超时，5表示服务器返回查询失败；为0时，后面的3个参数才有意义
		lat：string类型，纬度，整数部分3位，小数部分7位，例如031.2425864
		lng：string类型，经度，整数部分3位，小数部分7位，例如121.4736522
		addr：string类型，UCS2大端编码的位置字符串。调用lbsLoc.request时传入的第二个参数为true时，才返回本参数
返回值：无
]]
function getLocCb(result,lat,lng,addr)
    --log.info("testLbsLoc.getLocCb",result,lat,lng,result==0 and common.ucs2beToGb2312(addr) or "")
    --获取经纬度成功
    if result==0 then
    	Rlat = lat
    	Rlng = lng
    	log.info("testLbsLoc success",Rlat,Rlng)
    else
    	Rlat = ""
    	Rlng = ""
    end
    
end


function printGps()
    if gps.isFix() then
    	local tLocation = gps.getLocation()
    	Rlat = tLocation.lat
    	Rlng = tLocation.lng
	    log.info("testGps.printGps success",
        gps.isOpen(),gps.isFix(),
        tLocation.lngType,tLocation.lng,tLocation.latType,tLocation.lat,
        gps.getAltitude(),
        speed,
        gps.getCourse(),
        gps.getViewedSateCnt(),
        gps.getUsedSateCnt())
    else
    	reqLbsLoc()
    end
    return Rlat,Rlng

end

local function test1Cb(tag)
    log.info("testGps.test1Cb",tag)
    --printGps()
end


--设置GPS+BD定位
--如果不调用此接口，默认也为GPS+BD定位
--gps.setAerialMode(1,1,0,0)

--设置仅gps.lua内部处理NEMA数据
--如果不调用此接口，默认也为仅gps.lua内部处理NEMA数据
--如果gps.lua内部不处理，把NMEA数据通过回调函数cb提供给外部程序处理，参数设置为1,nmeaCb
--如果gps.lua和外部程序都处理，参数设置为2,nmeaCb
-- gps.setNmeaMode(2,nmeaCb)

-- test(testIdx)
gps.open(gps.DEFAULT,{tag="TEST1",cb=test1Cb})
--sys.timerLoopStart(printGps,20000)
