function manifest()
    myManifest = {
        name          = "ParamStretching",
        comment       = "拉伸或压缩参数",
        author        = "天zZ",
        pluginID      = "e675f6cf-8248-0b5b-c69b-e1575cdde2f5",
        pluginVersion = "1.0.0.0",
        apiVersion    = "3.0.0.1"
    }

    return myManifest
end

-- 创建复选框函数
function setCheckBox(name,caption, val)
	local field={}
	field.name	=name
	field.caption	=caption
	field.initialVal=val
	field.type		=1
	VSDlgAddField(field)
end

-- 执行一个参数的更新
function updateParam(paramType, rate, posTick, beginPosTick, endPosTick)
	local Param_After = {}
	local retCode
	local param_Now
	local param_last
	local param_avg = 0
	local count = 0
	for posTick = beginPosTick, endPosTick do
		retCode, param_Now = VSGetControlAt(paramType, posTick)
		count = count + 1
		param_avg = param_avg + param_Now
	end
	param_avg = param_avg / count
	retCode, param_last = VSGetControlAt(paramType, endPosTick)
	-- param_last = param_last * rate
	for posTick = beginPosTick, endPosTick do
		retCode, param_Now = VSGetControlAt(paramType, posTick) -- 返回当前位置的参数大小
		if paramType=="PIT" then
			Param_After[posTick - beginPosTick] = param_Now * rate
		else
			Param_After[posTick - beginPosTick] = param_avg + (param_Now-param_avg) * rate
		end
	end
	
	for posTick = beginPosTick, endPosTick do
		VSUpdateControlAt(paramType, posTick, Param_After[posTick - beginPosTick])
	end
	if paramType=="PIT" then
		VSUpdateControlAt(paramType, endPosTick, param_last)
	else
		param_last = param_avg + (param_last-param_avg) * rate
		VSUpdateControlAt(paramType, endPosTick, param_last)
	end
end

function main(processParam, envParam)
	local beginPosTick = processParam.beginPosTick -- 选区开始时刻
	local endPosTick   = processParam.endPosTick -- 选区结束时刻
	local songPosTick  = processParam.songPosTick -- 歌曲位置

	local scriptDir  = envParam.scriptDir -- LUA文件所在的文件夹
	local scriptName = envParam.scriptName -- LUA文件的文件名
	local tempDir    = envParam.tempDir -- 空置文件夹位置
	
	-- 对话框
	VSDlgSetDialogTitle("ParamStretching") -- 设置对话框标题
	local dlgStatus
	-- 添加复选框
	local checkBoxTypes	= {"pit","dyn","bri"}
	local checkBoxItems = {"pit","dyn","bri"}
	local checkBoxCaptions = {"PIT","DYN","BRI"}

	local checkBoxArray={}
	for i, v in pairs(checkBoxTypes) do
		checkBoxArray[i]={}
		checkBoxArray[i].name	= v
		checkBoxArray[i].control = checkBoxItems[i]
		checkBoxArray[i].caption = checkBoxCaptions[i]
		checkBoxArray[i].value	= 0
		checkBoxArray[i].result	= 0
		setCheckBox(checkBoxArray[i].name,checkBoxArray[i].caption,0)
	end

	-- 添加输入框
	local field={}
	field.name = "rate" -- 选项名称
	field.caption = "倍数（以10为基准）" -- 选项提醒信息
	field.initialVal = 10 -- 初始值
	field.type = 0 -- 选项数据类型
	dlgStatus = VSDlgAddField(field) -- 添加选项
	
	dlgStatus = VSDlgDoModal() -- 显示对话框

	if  (dlgStatus ~= 1) then
		return 0
	end

	-- 获得比率
	local rate
	dlgStatus, rate = VSDlgGetIntValue("rate")
	rate = rate / 10.0

	-- 获得参数类型
	local paramTypes = {}
	for i, v in pairs(checkBoxArray) do
		v.result, v. value=VSDlgGetBoolValue(v.name)
		if (v.value==1) then
			paramTypes[v.caption] = 1
		end
	end
	local msg = ""
	for k, v in pairs(paramTypes) do
		msg = msg..k..", "
	end
	-- 弹出一个消息框
	VSMessageBox("参数为"..msg.."倍数为"..rate, 0)

	for k, v in pairs(paramTypes) do
		updateParam(k, rate, posTick, beginPosTick, endPosTick)
	end
	

	return 0
end