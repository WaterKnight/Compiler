local time = os.clock()

local params = {...}

local inputPath = params[1]..[[\war3map.j]]

local curScope
local funcHeader = {}
local funcLines = {}
local funcs = {}
local globals = {}
local globalsLines = {}
local input = io.open(inputPath, "r")
local requires = {}
local structLinks = {}

local outError = io.open("errors.txt", "w+")

local function isIdentifierChar(char)
	if char then
		if (((char >= 'a') and (char <= 'z')) or ((char >= 'A') and (char <= 'Z')) or tonumber(char) or (char == "_")) then
			return true
		end

		return false
	end

	return false
end

string.readIdentifier = function(line, pos)
	local char = line:sub(pos, pos)

	while ((isIdentifierChar(char) == false) and (pos <= line:len())) do
		pos = pos + 1

		char = line:sub(pos, pos)
	end

	if (pos > line:len()) then
		return
	end

	local posStart = pos

	while (isIdentifierChar(char) and (pos <= line:len())) do
		pos = pos + 1

		char = line:sub(pos, pos)
	end

	local posEnd = (pos - 1)

	return line:sub(posStart, posEnd), posStart, posEnd
end

local function addGlobal(line, name)
	if (name == nil) then
		local ident, posStart, posEnd = line:readIdentifier(1)

		if (ident == "constant") then
			ident, posStart, posEnd = line:readIdentifier(posEnd + 1)
		end

		varType = ident

		ident, posStart, posEnd = line:readIdentifier(posEnd + 1)

		if (ident == "array") then
			ident, posStart, posEnd = line:readIdentifier(posEnd + 1)
		end

		name = ident
	end

	if (globals[name] == nil) then
		local pos, posEnd = name:find("LinkToStruct_", 1, true)

		if pos then
			name = name:sub(1, pos - 1)..name:sub(posEnd + 1, name:len())

			structLinks[name] = name

			return
		end

		globals[name] = name
		globalsLines[#globalsLines + 1] = line
	end
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

local function replaceStructLinks(line)
	local pos, posEnd = line:find("[", 1, true)

	while pos do
		pos = pos - 1

		while isIdentifierChar(line:sub(pos, pos)) do
			pos = pos - 1
		end

		pos = pos + 1

		if structLinks[line:sub(pos, posEnd - 1)] then
			line = line:sub(1, pos - 1)..line:sub(posEnd + 1, line:len())

			local endBracketPos, endBracketPosEnd = line:findEndBracket(pos, "[", "]")

			line = line:sub(1, endBracketPos - 1)..line:sub(endBracketPosEnd + 1, line:len())

			pos, posEnd = line:find("[", 1, true)
		else
			pos, posEnd = line:find("[", posEnd + 1, true)
		end
	end

	return line
end

local function addLineToFunc(func, line, pos)
	local t = funcLines[func]

	if pos then
		for i = #t, pos, -1 do
			t[i + 1] = t[i]
		end

		t[pos] = line
	else
		t[#t + 1] = line
	end
end

identifierNegPat = "[^(A-Z,a-z,0-9,_)]"

for line in input:lines() do
	if line:find("//", 1, true) then
		line = line:sub(1, line:find("//", 1, true) - 1)
	end

	local line2 = line

	while ((line2:sub(1, 1) == " ") or (line2:sub(1, 1) == "\t")) do
		line2 = line2:sub(2, line2:len())
	end

	if (curScope == nil) then
		local pos, posEnd = line2:find("function", 1, true)

		if (pos == 1) then
			pos = posEnd + 2

			posEnd = pos

			while (line2:sub(posEnd + 1, posEnd + 1) ~= " ") do
				posEnd = posEnd + 1
			end

			curFunc = line2:sub(pos, posEnd)

			if ((curFunc:sub(1, 4) == "//sa__") or (curFunc:sub(1, 4) == "sc__")) then
				curFunc = nil
			else
				curScope = "func"
				funcHeader[curFunc] = line
				funcLines[curFunc] = {}
				funcs[curFunc] = curFunc
				requires[curFunc] = {}

				--if curFunc:find("s__.*_Event_", 1) then
				--	addLineToFunc(curFunc, "local EventResponse params = EventResponse.GetTrigger()")
				--end
			end
		else
			local pos, posEnd = line2:find("globals", 1, true)

			if (pos == 1) then
				curScope = "globals"
			end
		end
	elseif (curScope == "globals") then
		if (line2:find("endglobals", 1, true) == 1) then
			curScope = nil
		elseif line2:readIdentifier(1) then
			addGlobal(line)
		end
	elseif (curScope == "func") then
		if (curFunc:find("jasshelper", 1, true) == 1) then
			if (line:find("st___prototype", 1, true) or line:find("sa___prototype", 1, true)) then
				line = nil
			end
		end

		if line then
			if (line2:find("endfunction", 1, true) == 1) then
				curScope = nil
			else
				line = line:gsub("sc__", "s__")

				addLineToFunc(curFunc, line)

				local pos, posEnd = line:find("%b()")

				while pos do
					local i = pos - 1

					while (line:sub(i, i) == " ") do
						i = i - 1
					end

					--line = line:sub(1, i)..line:sub(pos, line:len())

					local funcEnd = i

					--[[local char = line:sub(i, i)

					while isIdentifierChar(char) do
						i = i - 1

						char = line:sub(i, i)
					end]]

					string.reverseFind = function(s, pat, i)
						local len = s:len()

						s = s:reverse()

						i = len - i + 1

						i = s:find(pat, i)

						if i then
							return len - i + 1
						end

						return
					end

					i = line:reverseFind(identifierNegPat, i)

					if (i == nil) then
						i = 0
					end

					local funcStart = i + 1

					local func = line:sub(funcStart, funcEnd)

					requires[curFunc][func] = func

					line = line:sub(1, pos - 1).."<"..line:sub(pos + 1, posEnd - 1)..">"..line:sub(posEnd + 1, line:len())

					pos, posEnd = line:find("%b()")
				end

				local pos, posEnd = line:find("function ", 1, true)

				while pos do
					local i = posEnd + 1

					local char = line:sub(i, i)

					while (char and ((char >= 'a') and (char <= 'z')) or ((char >= 'A') and (char <= 'Z')) or tonumber(char) or (char == "_")) do
						i = i + 1

						char = line:sub(i, i)
					end

					local func = line:sub(posEnd + 1, i - 1)

					requires[curFunc][func] = func
--outError:write("\n"..curFunc..": "..func)
					line = line:sub(1, pos - 1).."<"..line:sub(pos + 1, posEnd - 1)..">"..line:sub(posEnd + 1, line:len())

					pos, posEnd = line:find("function ", 1, true)
				end
			end
		end
	end
end

input:close()

for k, v in pairs(funcs) do
	for k2, v2 in pairs(requires[v]) do
		if ((funcs[v2] == nil) or (v2 == v)) then
			requires[v][k2] = nil
		end
	end
end

local evalsInitFunc = "evalsInitFunc"
local isFuncReg = {}
local sortedFuncs = {}

funcLines[evalsInitFunc] = {}

local output = {}
local outputC = 0

local function outputWrite(s)
	outputC = outputC + 1
	output[outputC] = s
end

local function outputFunc(func)
	outputWrite("\n"..funcHeader[func])

	local c = 1

	while funcLines[func][c] do
		local line = funcLines[func][c]

		line = replaceStructLinks(line)

		outputWrite(line)

		c = c + 1
	end

	outputWrite("endfunction")
end

local function copyTable(t)
	local result = {}

	for k, v in pairs(t) do
		result[k] = v
	end

	return result
end

string.split = function(s, delimiter)
	local c = 1
	local result = {}

	while s:find(delimiter, 1, true) do
		result[c] = s:sub(1, s:find(delimiter, 1, true) - 1)

		c = c + 1
		s = s:sub(s:find(delimiter, 1, true) + 1, s:len())
	end

	result[c] = s

	return result
end

local function getFuncParams(func)
	--print("of "..func)
	local header = funcHeader[func]
	local result = {}

	local pos, posEnd = header:find(" takes ")

	header = header:sub(posEnd + 1, header:len())

	identifier, pos, posEnd = header:readIdentifier(1)

	if (identifier == "nothing") then
		header = header:sub(posEnd + 2, header:len())
	else
		local searchParam = true

		while searchParam do
			local t = {}

			t["type"], pos, posEnd = header:readIdentifier(1)

			header = header:sub(posEnd + 1, header:len())

			t["name"], pos, posEnd = header:readIdentifier(1)

			header = header:sub(posEnd + 1, header:len())

			result[#result + 1] = t

			while (header:sub(1, 1) == " ") do
				header = header:sub(2, header:len())
			end

			if (header:sub(1, 1) ~= ",") then
				searchParam = false
			end
		end
	end

	local pos, posEnd = header:find("returns ", 1, true)

	header = header:sub(posEnd + 1, header:len())

	local returnType = header:readIdentifier(1)

	if (returnType ~= "nothing") then
		result["return"] = returnType
	end

	return result
end

local function sortInFunc(func)
	sortedFuncs[#sortedFuncs + 1] = func
end

local EVAL_FUNC_SOURCE_PREFIX = "eval_"
local EVAL_FUNC_TARGET_PREFIX = "evalTarget_"
local EVAL_TRIG_PREFIX = "evalTrig_"
local EVAL_VAR_ARG_PREFIX = "f__arg_"
local EVAL_VAR_RESULT_PREFIX = "f__result_"

local function writeEvalFunc(func)
	local evalFunc = EVAL_FUNC_SOURCE_PREFIX..func

	if funcLines[evalFunc] then
		return evalFunc
	end

	funcLines[evalFunc] = {}
	local header = funcHeader[func]

	funcHeader[evalFunc] = "function "..evalFunc..header:sub(header:find(" takes ", 1, true), header:len())

	local params = getFuncParams(func)

	local argTypeAmount = {}
	local c2 = 1
	local paramsLine

	while params[c2] do
		local type = params[c2]["type"]

		if argTypeAmount[type] then
			argTypeAmount[type] = argTypeAmount[type] + 1
		else
			argTypeAmount[type] = 1
		end

		local globalVarName = EVAL_VAR_ARG_PREFIX..type..argTypeAmount[type]

		addGlobal(type.." "..globalVarName)
		addLineToFunc(evalFunc, "set "..globalVarName.." = "..params[c2]["name"])
		if paramsLine then
			paramsLine = paramsLine..", "..globalVarName
		else
			paramsLine = globalVarName
		end

		c2 = c2 + 1
	end

	addLineToFunc(evalFunc, "call TriggerEvaluate("..EVAL_TRIG_PREFIX..func..")")

	local pos, posEnd = funcHeader[func]:find(" returns ", 1, true)

	local globalReturnVar
	local returnType = getFuncParams(func)["return"]

	if returnType then
		globalReturnVar = EVAL_VAR_RESULT_PREFIX..returnType

		addGlobal(returnType.." "..globalReturnVar)
	end

	if globalReturnVar then
		addLineToFunc(evalFunc, "return "..globalReturnVar)
	end

	sortInFunc(evalFunc)

	local evalTargetFunc = EVAL_FUNC_TARGET_PREFIX..func

	addLineToFunc(func, "endfunction")

	addLineToFunc(func, "function "..evalTargetFunc.." takes nothing returns nothing")

	if (paramsLine == nil) then
		paramsLine = ""
	end

	if globalReturnVar then
		addLineToFunc(func, "set "..globalReturnVar.." = "..func.."("..paramsLine..")")
	else
		addLineToFunc(func, "call "..func.."("..paramsLine..")")
	end

	addGlobal("trigger "..EVAL_TRIG_PREFIX..func)
	addLineToFunc(evalsInitFunc, "set "..EVAL_TRIG_PREFIX..func.." = CreateTrigger()")
	addLineToFunc(evalsInitFunc, "call TriggerAddCondition("..EVAL_TRIG_PREFIX..func..", Condition(function "..EVAL_FUNC_TARGET_PREFIX..func.."))")

	return evalFunc
end

local function replaceCalls(func, call)
--print("search "..call.." in "..func)
	local c = 1

	while funcLines[func][c] do
		local line = funcLines[func][c]

		local pos, posEnd = line:find(call.."(", 1, true)

		while pos do
			local args = {}
			local argsC = 0

			if (isIdentifierChar(line:sub(pos - 1, pos - 1)) == false) then
				local i = posEnd + 1
				local remainingBrackets = 1

				while ((remainingBrackets > 0) and (i <= line:len())) do
					if (line:sub(i, i) == "(") then
						remainingBrackets = remainingBrackets + 1
					elseif (line:sub(i, i) == ")") then
						remainingBrackets = remainingBrackets - 1
					end

					--[[if (remainingBrackets == 1) then
						if (line:sub(i, i) == ",") then
							argsC = argsC + 1

							args[argsC] = i
						end
					end]]

					i = i + 1
				end

				if (remainingBrackets == 0) then
					i = 1
					local line2 = line:sub(posEnd + 1, i - 3)--:gsub(" ", "")
					remainingBrackets = 0
--print("line: "..line2)
					while (i <= line2:len()) do
						if (line2:sub(i, i) == "(") then
							remainingBrackets = remainingBrackets + 1
						elseif (line2:sub(i, i) == ")") then
							remainingBrackets = remainingBrackets - 1
						end

						if (remainingBrackets == 0) then
							if (line2:sub(i, i) == ",") then
								argsC = argsC + 1

								args[argsC] = line2:sub(1, i - 1)

								line2 = line2:sub(i + 1, line2:len())

								i = 0
							end
						end

						i = i + 1
					end

					local found = false
					i = 1

					while ((found == false) and (i < line2:len())) do
						if isIdentifierChar(line2:sub(i, i)) then
							found = true
						end

						i = i + 1
					end

					if found then
						argsC = argsC + 1

						args[argsC] = line2
					end

					local c2 = 1

					while args[c2] do
						--print("arg "..c2..": "..args[c2])

						c2 = c2 + 1
					end
				end

				line = line:sub(1, pos - 1)..writeEvalFunc(call)..line:sub(posEnd, line:len())

				posEnd = posEnd + 5
			end

			pos, posEnd = line:find(call.."(", posEnd + 1, true)
		end

		local pos, posEnd = line:find("function "..call, 1, true)
--print("in "..line.." search ".."function "..call)
		while pos do
			if (isIdentifierChar(line:sub(posEnd + 1, posEnd + 1)) == false) then
				local codeVar = "code__"..call

				line = line:sub(1, pos - 1)..codeVar..line:sub(posEnd + 1, line:len())
				addGlobal("code "..codeVar)
				addLineToFunc(evalsInitFunc, "set "..codeVar.." = function "..call)

				posEnd = pos + codeVar:len() + 1
			end

			pos, posEnd = line:find("function "..call, posEnd + 1, true)
		end

		funcLines[func][c] = line

		c = c + 1
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

local function regFunc(func, localTable, level)
	if (funcs[func] == nil) then
		print("warning: func "..func.." does not exist")

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
	localTable[func] = func

	for k, v in pairs(requires[func]) do
		if localTable[v] then
			outFuncsWrite(indent.."cycle between "..func.." and "..v)
			outCyclesWrite(indent..func.." and "..v)
			outCyclesWrite(indent.."eval from "..func.." to "..v)
			replaceCalls(func, v)
		else
			regFunc(v, copyTable(localTable), level + 1)
		end

--		if reqS then
--			reqS=reqS..','..v
--		else
--			reqS=v
--		end

		reqSC = reqSC + 1
		reqS[reqSC] = v
	end

	sortInFunc(func)
	outFuncsWrite(indent..func)

	--if reqS then
	--	outFuncs:write("\n\tRequires: "..reqS)
	--end
	if (reqSC > 0) then
		outFuncsWrite(indent.."\tRequires: "..table.concat(reqS, ','))
	end
end

funcHeader[evalsInitFunc] = "function "..evalsInitFunc.." takes nothing returns nothing"

addLineToFunc("main", [[call ExecuteFunc("]]..evalsInitFunc..[[")]], 1)

regFunc("config")
regFunc("main")

for k, v in pairs(funcs) do
	local params = getFuncParams(v)

	if (params[1] == nil) then
		regFunc(v)
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

outputWrite("\nglobals")

local c = 1

while globalsLines[c] do
	outputWrite(globalsLines[c])

	c = c + 1
end

outputWrite("endglobals")

local c = 1

while sortedFuncs[c] do
	outputFunc(sortedFuncs[c])

	c = c + 1
end

outputFunc(evalsInitFunc)

outError:close()

writeTable("outFuncs.txt", outFuncs)
writeTable("outCycles.txt", outCycles)
writeTable("outputOld.j", output)

print("finished in "..(os.clock() - time).."seconds")