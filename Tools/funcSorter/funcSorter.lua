local time = os.clock()

local params = {...}

local inputPath = params[1]

local input = io.open(inputPath, "r")

local inputLines = {}
local inputLinesC = 0

for line in input:lines() do
	inputLinesC = inputLinesC + 1
	inputLines[inputLinesC] = line
end

local autoRuns = {}
local autoExecs = {}
local keyMacros = {}
local structLinks = {}

local AUTO_EXEC_TRIG_PREFIX = "autoExecTrig_"

local outError = io.open("errors.txt", "w+")

require "stringLib"

identifierSymbols = {}

for i = string.byte('A'), string.byte('Z'), 1 do
	identifierSymbols[string.char(i)] = true
end

for i = string.byte('a'), string.byte('z'), 1 do
	identifierSymbols[string.char(i)] = true
end

for i = string.byte('0'), string.byte('9'), 1 do
	identifierSymbols[string.char(i)] = true
end

identifierSymbols['_'] = true

local function isIdentifierChar(char)
	if char then
		return identifierSymbols[char]
	end

	return false
end

identifierPat = "[A-Za-z0-9_$]"
identifierNegPat = "[^A-Za-z0-9_$]"

string.readIdentifier = function(line, posStart)
	posStart = line:find(identifierPat, posStart)

	if (posStart == nil) then
		return
	end

	local posEnd = line:find(identifierNegPat, posStart)

	if posEnd then
		posEnd = posEnd - 1
	else
		posEnd = line:len()
	end

	return line:sub(posStart, posEnd), posStart, posEnd
end

string.reverseReadIdentifier = function(line, pos)
	local len = line:len()

	line, posStart, posEnd = line:reverse():readIdentifier(len - pos + 1)

	return line:reverse(), len - posEnd + 1, len - posStart + 1
end

local globals = {}

function createGlobal(name, type, isArray, val, isConstant)
	if globals[name] then
		print("global", name, "already declared")

		return
	end
	
	local pos, posEnd = name:find("LinkToStruct_", 1, true)

	if pos then
		name = name:sub(1, pos - 1)..name:sub(posEnd + 1)

		structLinks[name] = name

		return
	end
	
	local pos, posEnd = name:find("GetKeyMacro_", 1, true)

	if pos then
		keyMacros[name] = val
	end
	
	local this = {}
	
	this.name = name
	this.type = type
	this.isArray = isArray
	this.val = val
	this.isConstant = isConstant
	this.reqs = {}

	this.rename = function(this, name)
		globals[this.name] = nil

		this.name = name

		globals[name] = this
	end

	this.addReq = function(this, reqName)
		if this.reqs[reqName] then
			return
		end

		if (this.name == reqName) then
			return
		end

		this.reqs[reqName] = reqName
		this.reqs[#this.reqs + 1] = reqName
	end

	this.removeReq = function(this, reqName)
		this.reqs[reqName] = nil
		for i = 1, #this.reqs, 1 do 
			if (this.reqs[i] == reqName) then
				table.remove(this.reqs, i)
			end
		end
	end

	this.output = function(this, outputWrite)
		local t = {}
	
		if this.isConstant then
			table.insert(t, "constant")
		end
	
		table.insert(t, this.type)
	
		if this.isArray then
			table.insert(t, "array")
		end
	
		table.insert(t, this.name)
	
		if this.val then
			table.insert(t, "=")
	
			table.insert(t, this.val)
		end
	
		outputWrite("\t"..table.concat(t, " "))
	end

	globals[name] = this
	globals[#globals + 1] = this

	return this
end

function getGlobalByName(name)
	local result = globals[name]

	if (result == nil) then
		--print("warning: global "..name.." does not exist")
	end

	return result
end

local funcs = {}

function createFunc(name)
	local this = {}

	this.name = name
	this.params = {}
	this.lines = {}
	this.reqs = {}

	this.rename = function(this, name)
		funcs[this.name] = nil

		this.name = name

		funcs[name] = this
	end

	this.addLine = function(this, line, index)
		if index then
			table.insert(this.lines, index, line)
		else
			this.lines[#this.lines + 1] = line
		end
	end

	this.addReq = function(this, reqName)
		if this.reqs[reqName] then
			return
		end

		if (this.name == reqName) then
			return
		end

		this.reqs[reqName] = reqName
		this.reqs[#this.reqs + 1] = reqName
	end

	this.removeReq = function(this, reqName)
		this.reqs[reqName] = nil
		for i = 1, #this.reqs, 1 do 
			if (this.reqs[i] == reqName) then
				table.remove(this.reqs, i)
			end
		end
	end

	this.addParam = function(this, name, type)
		local t = {}

		t.name = name
		t.type = type

		this.params[#this.params + 1] = t
	end

	this.scanHeader = function(this, line)	
		local pos, posEnd = line:find(" takes ")
	
		line = line:sub(posEnd + 1)
	
		local name, pos, posEnd = line:readIdentifier()
	
		if (name == "nothing") then
			line = line:sub(posEnd + 1)
		else
			local pos, posEnd = line:find(" returns ")
	
			local paramsLine = line:sub(1, pos - 1)
	
			local t = paramsLine:split(",")
	
			for i = 1, #t, 1 do
				local line = t[i]

				local var = {}

				local type, pos, posEnd = line:readIdentifier()

				local name, pos, posEnd = line:readIdentifier(posEnd + 1)

				this:addParam(name, type)
			end

			line = line:sub(pos - 1)
		end
	
		local pos, posEnd = line:find(" returns ")
	
		line = line:sub(posEnd + 1)
	
		local returnType = line:readIdentifier()
	
		if (returnType ~= "nothing") then
			this.returnType = returnType
		end
	end

	this.replaceStructLinks = function(this)
		for i = 1, #this.lines, 1 do
			local line = this.lines[i]

			local pos, posEnd = line:find("[", 1, true)
		
			while pos do
				pos = pos - 1
		
				local name, namePos = line:reverseReadIdentifier(pos)
		
				if structLinks[name] then
					line = line:sub(1, namePos - 1)..line:sub(posEnd + 1, line:len())
		
					local endBracketPos, endBracketPosEnd = line:findEndBracket(namePos, "[", "]")
		
					line = line:sub(1, endBracketPos - 1)..line:sub(endBracketPosEnd + 1, line:len())
		
					pos, posEnd = line:find("[", 1, true)
				else
					pos, posEnd = line:find("[", posEnd + 1, true)
				end
			end

			this.lines[i] = line
		end
	end

	this.setAsEvalFunc = function(this)
		this.params = {}
		this.returnType = "boolean"
		this.isEvalFunc = true
	end

	this.output = function(this, outputWrite)
		local t = {}
	
		table.insert(t, "function")
		table.insert(t, this.name)
		table.insert(t, "takes")
	
		if (#this.params > 0) then
			local t2 = {}
	
			for i = 1, #this.params, 1 do
				table.insert(t2, this.params[i].type.." "..this.params[i].name)
			end
	
			table.insert(t, table.concat(t2, ","))
		else
			table.insert(t, "nothing")
		end
	
		table.insert(t, "returns")
	
		if this.returnType then
			table.insert(t, this.returnType)
		else
			table.insert(t, "nothing")
		end
	
		outputWrite(table.concat(t, " "))
	
		for i = 1, #this.lines, 1 do
			if ((this.lines[i] == "return") and this.isEvalFunc) then
				outputWrite("\t".."return true")
			else
				outputWrite("\t"..this.lines[i])
			end
		end
	
		if this.isEvalFunc then
			outputWrite("\t".."return true")
		end
	
		outputWrite("endfunction")
	end

	funcs[name] = this
	funcs[#funcs + 1] = this

	return this
end

function getFuncByName(name)
	local result = funcs[name]

	if (result == nil) then
		--print("warning: func "..name.." does not exist")
	end

	return result
end

local function scanGlobal(line)
	local isConstant
	local type, pos, posEnd = line:readIdentifier()
	
	if (type == "constant") then
		isConstant = true

		type, pos, posEnd = line:readIdentifier(posEnd + 1)
	end
	
	local isArray
	local name, pos, posEnd = line:readIdentifier(posEnd + 1)
	
	if (name == "array") then
		isArray = true

		name, pos, posEnd = line:readIdentifier(posEnd + 1)
	end

	if (name:find("st__", 1, true) == 1) then
		return
	end
	if (name:find("si__", 1, true) == 1) then
		return
	end

	line = line:sub(posEnd + 1)
	
	local val
	local pos, posEnd = line:find("=")
	
	if pos then
		val = line:sub(posEnd + 1)
	end

	createGlobal(name, type, isArray, val, isConstant)
end

string.findEndBracket = function(line, pos, startBracket, endBracket)
	local endBracketPos, endBracketPosEnd = line:find(endBracket, pos, true)

	if (endBracketPos == nil) then
		return line:len(), line:len()
	end

	local remaining = 1

	while ((remaining > 0) and endBracketPos) do
		pos, posEnd = line:find(startBracket, pos, true)

		while (pos and (pos < endBracketPos)) do
			pos, posEnd = line:find(startBracket, posEnd + 1, true)
			remaining = remaining + 1
		end

		pos, posEnd = endBracketPosEnd + 1
		remaining = remaining - 1

		if (remaining > 0) then
			endBracketPos, endBracketPosEnd = line:find(endBracket, endBracketPosEnd + 1, true)
		end
	end

	return endBracketPos, endBracketPosEnd
end

local curScope

for i = 1, #inputLines, 1 do
	local line = inputLines[i]

	line = line:gsub([[//autoExec]], [[autoExec]])

	if line:find("//", 1, true) then
		line = line:sub(1, line:find("//", 1, true) - 1)
	end

	local pos, posEnd = line:find("[^ \t]")

	if pos then
		line = line:sub(pos)

		if (curScope == nil) then
			local pos, posEnd = line:find("function")
	
			if (pos == 1) then
				pos = posEnd + 2
	
				local name = line:readIdentifier(pos)
	
				if ((name:sub(1, 4) == "sa__") or (name:sub(1, 4) == "sc__")) then
					curFunc = nil
				else
					curScope = "func"
	
					curFunc = createFunc(name)
	
					curFunc:scanHeader(line)
	
					if (name:find("jasshelper") == 1) then
						isJassHelperInit = true
					end
	
					if name:endsWith("_autoRun") then
						autoRuns[#autoRuns + 1] = curFunc
					elseif name:endsWith("_debugInit") then
						debugInit = curFunc
					end
				end
			else
				local pos, posEnd = line:find("globals")
	
				if (pos == 1) then
					curScope = "globals"
				end
			end
		elseif (curScope == "globals") then
			if (line:find("endglobals") == 1) then
				curScope = nil
			elseif line:readIdentifier() then
				scanGlobal(line)
			end
		elseif (curScope == "func") then
			local function regFunc()
				if (line:find("endfunction") == 1) then
					curScope = nil
					if isJassHelperInit then
						isJassHelperInit = false
					end
				else
					line = line:gsub("sc__", "s__")
	
					local stPos, stPosEnd = line:find("TriggerEvaluate(st__", 1, true)

					if stPos then
						local endBracketPos = line:findEndBracket(stPosEnd, "(", ")")
	
						local newLine = line:sub(1, stPos - 1).."s__"..line:sub(stPosEnd + 1, endBracketPos - 1).."()"
	
						line = newLine
					end
	
					if not line:find("jasshelper") then
						if (line == [[autoExec]]) then
							local name = curFunc.name

							curFunc:rename(name.."_autoExec_final")

							local evalFunc = createFunc(name)
							local evalTargetFunc = createFunc(name.."_autoExec_evalTarget")

							evalFunc:addReq(evalTargetFunc.name)
							evalTargetFunc:addReq(curFunc.name)

							evalFunc.params = curFunc.params
							evalFunc.returnType = curFunc.returnType

							local typeC = {}
							local paramsT = {}

							for i = 1, #curFunc.params, 1 do
								local param = curFunc.params[i]

								local type = curFunc.params[i].type
				
								if typeC[type] then
									typeC[type] = typeC[type] + 1
								else
									typeC[type] = 0
								end
				
								local varName = "autoExec_arg_"..type..typeC[type]
				
								local var = getGlobalByName(varName)
				
								if (var == nil) then
									var = createGlobal(varName, type)

									evalFunc:addReq(varName)
									evalTargetFunc:addReq(varName)
								end
				
								evalFunc:addLine([[set ]]..var.name..[[ = ]]..param.name)
				
								paramsT[#paramsT + 1] = varName
							end

							autoExecs[#autoExecs + 1] = evalTargetFunc

							local trigName = AUTO_EXEC_TRIG_PREFIX..evalTargetFunc.name

							createGlobal(trigName, [[trigger]])
							evalFunc:addReq(trigName)

							evalFunc:addLine([[call IncStack(GetHandleId(Condition(function ]]..evalTargetFunc.name..[[)))]])

							evalFunc:addLine([[call TriggerEvaluate(]]..trigName..[[)]])

							evalFunc:addLine([[call DecStack()]])

							if curFunc.returnType then
								local varName = "autoExec_result_"..curFunc.returnType
				
								local var = getGlobalByName(varName)
				
								if (var == nil) then
									var = createGlobal(varName, curFunc.returnType)

									evalFunc:addReq(varName)
									evalTargetFunc:addReq(varName)
								end
				
								evalTargetFunc:addLine([[set ]]..var.name..[[ = ]]..curFunc.name..[[(]]..table.concat(paramsT, ",")..[[)]])

								evalFunc:addLine([[return ]]..var.name)
							else
								evalTargetFunc:addLine([[call ]]..curFunc.name..[[(]]..table.concat(paramsT, ",")..[[)]])
							end
--printTable(curFunc)
--printTable(evalFunc)

for i=1, #curFunc.lines, 1 do
	print(curFunc.lines[i])
end
os.execute("pause")
						else
							curFunc:addLine(line)
		
							local name, pos, posEnd = line:readIdentifier()
							local isExecuteFunc
		
							if name then
								if (line:readIdentifier(posEnd + 1) == "ExecuteFunc") then
									isExecuteFunc = true
								end
							end
		
							while name do
								if not line:insideQuote(pos) or isExecuteFunc then
									curFunc:addReq(name)
								end
	
								name, pos, posEnd = line:readIdentifier(posEnd + 1)
							end
		
							--[[local pos, posEnd = line:find("%b()")
			
							while pos do
								local i = pos - 1
			
								local funcName = line:reverseReadIdentifier(i)
		
								curFunc:addReq(funcName)
			
								line = line:sub(1, pos - 1).."<"..line:sub(pos + 1, posEnd - 1)..">"..line:sub(posEnd + 1)
			
								pos, posEnd = line:find("%b()")
							end
			
							local pos, posEnd = line:find("function ")
			
							while pos do
								local funcName = line:readIdentifier(posEnd + 1)
			
								curFunc:addReq(funcName)
			--outError:write("\n"..curFunc..": "..funcName)
								line = line:sub(1, pos - 1).."<"..line:sub(pos + 1, posEnd - 1)..">"..line:sub(posEnd + 1)
			
								pos, posEnd = line:find("function ")
							end
	
							local pos, posEnd = line:find("ExecuteFunc")
	
							if pos then
								curFunc:addReq(line:readIdentifier(posEnd + 1))
							end]]
						end
					end
				end
			end
	
			if isJassHelperInit then
				if (line:find("st___prototype", 1, true) or line:find("sa___prototype", 1, true)) then
				elseif line:find("call ExecuteFunc") then
					regFunc()
				end
			else
				regFunc()
			end
		end
	end
end

input:close()

for i = 1, #funcs, 1 do
	local func = funcs[i]

	for i2 = #func.reqs, 1, -1 do
		local req = func.reqs[i2]

		if (((getFuncByName(req) == nil) or (getFuncByName(req) == func)) and (getGlobalByName(req) == nil)) then
			func:removeReq(req)
		end
	end
end

for i = 1, #globals, 1 do
	local global = globals[i]

	if global.val then
		local line = global.val

		local name, pos, posEnd = line:readIdentifier()

		while name do
			if getGlobalByName(name) then
				global:addReq(name)
			end

			name, pos, posEnd = line:readIdentifier(posEnd + 1)
		end
	end
end

local runProtFunc = createFunc("runProtFunc")

local funcsTableInitFunc = createFunc("funcsTableInitFunc")
local evalsInitFunc = createFunc("evalsInitFunc")
local keyMacrosInitFunc = createFunc("keyMacrosInitFunc")
local autoRunsFunc = createFunc("autoRunsFunc")
local autoExecsInitFunc = createFunc("autoExecsInitFunc")

for i = 1, #funcs, 1 do
	funcs[i]:replaceStructLinks()
end

local sortedFuncs = {}

local function sortInFunc(func)
	sortedFuncs[#sortedFuncs + 1] = func
end

local sortedGlobals = {}

local function sortInGlobal(global)
	if (global == nil) then
		return
	end

	sortedGlobals[#sortedGlobals + 1] = global
end

local EVAL_FUNC_SOURCE_PREFIX = "eval_"
local EVAL_FUNC_TARGET_PREFIX = "evalTarget_"
local EVAL_TRIG_PREFIX = "evalTrig_"
local EVAL_VAR_ARG_PREFIX = "evalArg_"
local EVAL_VAR_RESULT_PREFIX = "evalResult_"

local function writeEvalFunc(funcName)
	local func = getFuncByName(funcName)

	local thisName = EVAL_FUNC_SOURCE_PREFIX..func.name

	local this = getFuncByName(thisName)

	if this then
		return thisName
	end

	local this = createFunc(thisName)

	--func:addReq(thisName)
	--sortIn

	local argTypeAmount = {}
	local paramsLine

	for i = 1, #func.params, 1 do
		local name = func.params[i].name
		local type = func.params[i].type

		if argTypeAmount[type] then
			argTypeAmount[type] = argTypeAmount[type] + 1
		else
			argTypeAmount[type] = 1
		end

		local globalVarName = EVAL_VAR_ARG_PREFIX..type..argTypeAmount[type]

		sortInGlobal(createGlobal(globalVarName, type))

		this:addLine("set "..globalVarName.." = "..name)

		--this:addReq(globalVarName)

		if paramsLine then
			paramsLine = paramsLine..", "..globalVarName
		else
			paramsLine = globalVarName
		end

		this:addParam(name, type)
	end
	this.returnType = func.returnType

	this:addLine("call TriggerEvaluate("..EVAL_TRIG_PREFIX..func.name..")")

	local globalReturnVar
	local returnType = func.returnType

	if returnType then
		globalReturnVar = EVAL_VAR_RESULT_PREFIX..returnType

		sortInGlobal(createGlobal(globalReturnVar, returnType))

		--this:addReq(globalReturnVar)
	end

	if globalReturnVar then
		this:addLine("return "..globalReturnVar)
	end

	sortInFunc(this)

	local evalTargetFuncName = EVAL_FUNC_TARGET_PREFIX..func.name

	--func:addLine("endfunction")

	local targetFunc = createFunc(evalTargetFuncName)

	--func:addLine("function "..evalTargetFunc.." takes nothing returns nothing")

	if (paramsLine == nil) then
		paramsLine = ""
	end

	if globalReturnVar then
		targetFunc:addLine("set "..globalReturnVar.." = "..func.name.."("..paramsLine..")")
	else
		targetFunc:addLine("call "..func.name.."("..paramsLine..")")
	end

	sortInGlobal(createGlobal(EVAL_TRIG_PREFIX..func.name, "trigger"))

	evalsInitFunc:addLine("set "..EVAL_TRIG_PREFIX..func.name.." = CreateTrigger()")
	evalsInitFunc:addLine("call TriggerAddCondition("..EVAL_TRIG_PREFIX..func.name..", Condition(function "..evalTargetFuncName.."))")

	evalsInitFunc:addReq(evalTargetFuncName)

	return thisName
end

local function replaceCalls(func, call)
	for i = 1, #func.lines, 1 do
		local line = func.lines[i]

		local name, pos, posEnd = line:readIdentifier()

		while name do
			if not line:insideQuote(pos) then
				if (name == call) then
					local functionWord, pos2, pos2End = line:reverseReadIdentifier(pos - 1)
	
					if (functionWord == "function") then
						local codeVar = "code__"..call
	
						createGlobal(codeVar, "code")
	
						if (call ~= "main") then
							evalsInitFunc:addLine("set "..codeVar.." = function "..call)
						end
	
						line = line:sub(1, pos2 - 1)..codeVar..line:sub(posEnd + 1)
	
						posEnd = pos + codeVar:len() - 1
					else
						local eval = writeEvalFunc(call)
	
						line = line:sub(1, pos - 1)..eval..line:sub(posEnd + 1)
	
						posEnd = pos + eval:len() - 1
					end
				end
			end

			name, pos, posEnd = line:readIdentifier(posEnd + 1)
		end

		func.lines[i] = line
	end
end

local outCycles = {}
local outCyclesC = 0

local function outCyclesWrite(s)
	outCyclesC = outCyclesC + 1
	outCycles[outCyclesC] = s
end

local outFuncsC = 0
local outFuncs = {}

local function outFuncsWrite(s)
	outFuncsC = outFuncsC + 1
	outFuncs[outFuncsC] = s
end

local function copyTable(t)
	local result = {}

	for k, v in pairs(t) do
		result[k] = v
	end

	return result
end

local isGlobalReg = {}

local function regGlobal(global, localTable)
	if (global == nil) then
		print("regGlobal: global is nil")

		return
	end

	if isGlobalReg[global] then
		return
	end

	if (localTable == nil) then
		localTable = {}
	end

	isGlobalReg[global] = true
	localTable[global.name] = global

	for i = 1, #global.reqs, 1 do
		local req = global.reqs[i]

		regGlobal(getGlobalByName(req), copyTable(localTable))
	end

	sortInGlobal(global)
end

local isFuncReg = {}

local function regFunc(func, localTable, level)
	if (func == nil) then
		print("regFunc: func is nil")

		return
	end

	if isFuncReg[func] then
		return
	end

	if (level == nil) then
		level = 0
	end
	if (localTable == nil) then
		localTable = {}
	end

	local indent = string.rep("\t", level)

	local reqS = {0, 0, 0, 0, 0, 0, 0, 0, 0}
	local reqSC = 0
	isFuncReg[func] = true
	localTable[func.name] = func

	for i = 1, #func.reqs, 1 do
		local req = func.reqs[i]

		if getFuncByName(req) then
			if localTable[req] then
				outFuncsWrite(indent.."cycle between "..func.name.." and "..req)
				outCyclesWrite(indent..func.name.." and "..req)
				outCyclesWrite(indent.."eval from "..func.name.." to "..req)
	
				replaceCalls(func, req)
			else
				regFunc(getFuncByName(req), copyTable(localTable), level + 1)
			end
		elseif getGlobalByName(req) then
			regGlobal(getGlobalByName(req), copyTable(localTable))
		end

		reqSC = reqSC + 1
		reqS[reqSC] = req
	end

	sortInFunc(func)
	outFuncsWrite(indent..func.name)

	if (reqSC > 0) then
		outFuncsWrite(indent.."\tRequires: "..table.concat(reqS, ','))
	end
end

runProtFunc:scanHeader([[function "..runProtFunc.." takes code c, string name returns boolean]])

runProtFunc:addReq("IncStack")
runProtFunc:addReq("DecStack")

runProtFunc:addLine([[    local trigger t = CreateTrigger()]])
runProtFunc:addLine([[    local boolean result]])
runProtFunc:addLine([[    call TriggerAddCondition(t, Condition(c))]])
runProtFunc:addLine([[    call IncStack(GetHandleId(Condition(c)))]])
runProtFunc:addLine([[    set result = TriggerEvaluate(t)]])
runProtFunc:addLine([[    if not result then]])
runProtFunc:addLine([[        call DebugEx(null, "runProtFunc", "compilefunc " + name + " has been broken")]])
runProtFunc:addLine([[    endif]])
runProtFunc:addLine([[    call DecStack()]])
runProtFunc:addLine([[    set t = null]])
runProtFunc:addLine([[    return result]])

local main = getFuncByName("main")

--createGlobal("FUNCS_TABLE", "hashtable")

funcsTableInitFunc.notListedInFuncsTableInit = true
main.notListedInFuncsTableInit = true
evalsInitFunc.notListedInFuncsTableInit = true
keyMacrosInitFunc.notListedInFuncsTableInit = true
autoRunsFunc.notListedInFuncsTableInit = true
autoExecsInitFunc.notListedInFuncsTableInit = true

funcsTableInitFunc:addLine([[set FUNCS_TABLE = InitHashtable()]])

createGlobal("KEY_MACROS_TABLE", "hashtable")

keyMacrosInitFunc:addLine("set KEY_MACROS_TABLE = InitHashtable()")

for name, val in pairs(keyMacros) do
	keyMacrosInitFunc:addLine([[call SaveStr(KEY_MACROS_TABLE, 0, ]]..val..[[, ]]..name:quote()..[[)]])
end

for _, func in pairs(autoRuns) do
	func:addReq(runProtFunc.name)
	func:setAsEvalFunc()

	autoRunsFunc:addReq(func.name)

	autoRunsFunc:addLine([[call ]]..runProtFunc.name..[[(function ]]..func.name..[[, ]]..func.name:sub(1, 1):quote()..[[+]]..func.name:sub(2):quote()..[[)]])
end

for _, func in pairs(autoExecs) do
	autoExecsInitFunc:addReq(func.name)

	autoExecsInitFunc:addLine([[set ]]..AUTO_EXEC_TRIG_PREFIX..func.name..[[ = CreateTrigger()]])
	autoExecsInitFunc:addLine([[call TriggerAddCondition(]]..AUTO_EXEC_TRIG_PREFIX..func.name..[[, Condition(function ]]..func.name..[[))]])
end

print(main, main.name)

main:addLine([[call ]]..runProtFunc.name..[[(function ]]..debugInit.name..[[, ]]..(debugInit.name.."test"):quote()..[[)]], 1)

main:addLine([[call ]]..runProtFunc.name..[[(function ]]..funcsTableInitFunc.name..[[, ]]..(funcsTableInitFunc.name.."test"):quote()..[[)]], 2)
main:addLine([[call ]]..runProtFunc.name..[[(function ]]..evalsInitFunc.name..[[, ]]..(evalsInitFunc.name.."test"):quote()..[[)]], 3)
main:addLine([[call ]]..runProtFunc.name..[[(function ]]..keyMacrosInitFunc.name..[[, ]]..(keyMacrosInitFunc.name.."test"):quote()..[[)]], 4)
main:addLine([[call ]]..runProtFunc.name..[[(function ]]..autoRunsFunc.name..[[, ]]..(autoRunsFunc.name.."test"):quote()..[[)]], 5)
main:addLine([[call ]]..runProtFunc.name..[[(function ]]..autoExecsInitFunc.name..[[, ]]..(autoExecsInitFunc.name.."test"):quote()..[[)]], 6)
main:addLine([[call InfoEx("init ok")]])

debugInit:setAsEvalFunc()

funcsTableInitFunc:setAsEvalFunc()
evalsInitFunc:setAsEvalFunc()
keyMacrosInitFunc:setAsEvalFunc()
autoRunsFunc:setAsEvalFunc()
autoExecsInitFunc:setAsEvalFunc()

main:addReq(debugInit.name)
main:addReq(runProtFunc.name)
main:addReq(keyMacrosInitFunc.name)
main:addReq(autoRunsFunc.name)
main:addReq(autoExecsInitFunc.name)
main:addReq(evalsInitFunc.name)

main:addReq(funcsTableInitFunc.name)

local config = getFuncByName("config")

regFunc(config)
regFunc(main)

for i = 1, #sortedFuncs, 1 do
	local func = sortedFuncs[i]

	local name = func.name

	if (not func.notListedInFuncsTableInit and (#func.params == 0)) then
		funcsTableInitFunc:addReq(name)
		funcsTableInitFunc:addLine([[call SaveStr(FUNCS_TABLE, GetHandleId(Condition(function ]]..name..[[)), 0, ]]..name:sub(1, 1):quote()..[[+]]..name:sub(2):quote()..[[)]])
	end
end

for k, func in pairs(funcs) do
	if (#func.params == 0) then
		--regFunc(func)
	end
end

local function writeTable(path, t)
	local f = io.open(path, "w+")

	if (f == nil) then
		assert(nil, 'cannot write to '..path)
	end

	f:write(table.concat(t, '\n'))

	f:close()
end

local output = {}
local outputC = 0

local function outputWrite(s)
	outputC = outputC + 1
	output[outputC] = s
end

outputWrite("globals")

for i = 1, #sortedGlobals, 1 do
	local var = sortedGlobals[i]

	var:output(outputWrite)
end

print(#sortedGlobals.." globals")

outputWrite("endglobals")

for i = 1, #sortedFuncs, 1 do
	local func = sortedFuncs[i]

	func:output(outputWrite)
end

print(#sortedFuncs.." functions")

outError:close()

writeTable("outFuncs.txt", outFuncs)
writeTable("outCycles.txt", outCycles)
writeTable("output.j", output)

print("finished in "..(os.clock() - time).."seconds")