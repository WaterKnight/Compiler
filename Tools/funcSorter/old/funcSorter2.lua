local c
local curScope
local funcs = {}
local globalsLines = {}
local input = io.open("input.j", "r")
local linesOfFunc = {}
local requires = {}

local outError = io.open("errors.txt", "w+")
print(#linesOfFunc)
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
				funcs[curFunc] = curFunc
				c = 1
				linesOfFunc[curFunc] = {}
				requires[curFunc] = {}
			end
		else
			local pos, posEnd = line2:find("globals", 1, true)

			if (pos == 1) then
				c = 1
				curScope = "globals"
			end
		end
	end

	if (curScope == "globals") then
		globalsLines[c] = line

		if (line:find("endglobals", 1, true) == 1) then
			curScope = nil
		else
			c = c + 1
		end
	elseif (curScope == "func") then
		if (curFunc:find("jasshelper", 1, true) == 1) then
			if (line:find("st___prototype", 1, true) or line:find("sa___prototype", 1, true)) then
				line = nil
			end
		end

		if line then
			line = line:gsub("sc__", "s__")

			linesOfFunc[curFunc][c] = line

			local pos, posEnd = line:find("%b()")

			while pos do
				local i = pos - 1

				while (line:sub(i, i) == " ") do
					i = i - 1
				end

				--line = line:sub(1, i)..line:sub(pos, line:len())

				local char = line:sub(i, i)
				local funcEnd = i

				while (char and ((char >= 'a') and (char <= 'z')) or ((char >= 'A') and (char <= 'Z')) or tonumber(char) or (char == "_")) do
					i = i - 1

					char = line:sub(i, i)
				end

				local funcStart = i + 1

				local func = line:sub(funcStart, funcEnd)

				requires[curFunc][func] = func

				line = line:sub(1, pos - 1).."<"..line:sub(pos + 1, posEnd - 1)..">"..line:sub(posEnd + 1, line:len())

				pos, posEnd = line:find("%b()")
			end

			if (c ~= 1) then
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
outError:write("\n"..curFunc..": "..func)
					line = line:sub(1, pos - 1).."<"..line:sub(pos + 1, posEnd - 1)..">"..line:sub(posEnd + 1, line:len())

					pos, posEnd = line:find("function ", 1, true)
				end
			end

			if (line2:find("endfunction", 1, true) == 1) then
				curScope = nil
			else
				c = c + 1
			end
		end
	end
end

input:close()
outError:close()

for k, v in pairs(funcs) do
	for k2, v2 in pairs(requires[v]) do
		if ((funcs[v2] == nil) or (v2 == v)) then
			requires[v][k2] = nil
		end
	end
end

local curPos = 1
local isFuncReg = {}
local outCycles = io.open("outCycles.txt", "w+")
local outFuncs = io.open("outFuncs.txt", "w+")
local output = io.open("output.j", "w+")
local sortedFuncs = {}

while globalsLines[curPos] do
	output:write("\n"..globalsLines[curPos])

	curPos = curPos + 1
end

curPos = 1

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
	print("of "..func)
	local line = linesOfFunc[func][1]
	local result = {}

	local pos, posEnd = line:find("takes ")

	line = line:sub(posEnd + 1, line:len())

	if (line:find("nothing ", 1, true) == 1) then
		return result
	else
		posEnd = 0

		while line:find(",", posEnd + 1, true) do
			pos, posEnd = line:find(",", posEnd + 1, true)
		end

		pos, posEnd = line:find(" ", posEnd + 1, true)

		pos, posEnd = line:find(" ", posEnd + 1, true)

		local pos2, posEnd2 = line:find(" returns ", 1, true)

		local returnType = line:sub(posEnd2 + 1, line:len())

		if (returnType ~= "nothing") then
			result["return"] = returnType
		end

		line = line:sub(1, pos - 1)

		local t = line:split(",")

		local c = 1

		while t[c] do
			result[c] = {}

			result[c]["type"] = t[c]:sub(1, t[c]:find(" ", 1, true) - 1)
			result[c]["name"] = t[c]:sub(t[c]:find(" ", 1, true) + 1, t[c]:len())

			c = c + 1
		end

		return result
	end
end

local function isIdentifierChar(char)
	if char then
		if (((char >= 'a') and (char <= 'z')) or ((char >= 'A') and (char <= 'Z')) or tonumber(char) or (char == "_")) then
			return true
		end

		return false
	end

	return false
end

local function writeEvalFunc(func)
	local evalFunc = "eval_"..func

	if linesOfFunc[evalFunc] then
		return evalFunc
	end

	linesOfFunc[evalFunc] = {}

	linesOfFunc[evalFunc][1] = "function "..evalFunc.." "..linesOfFunc[func][1]:sub(linesOfFunc[func][1]:find(" takes "), linesOfFunc[func][1]:len())

	local c = 2
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

		local globalVarName = "f__arg_"..type..argTypeAmount[type]

		linesOfFunc[evalFunc][c] = "set "..globalVarName.." = "..params[c2]["name"]
		if paramsLine then
			paramsLine = paramsLine..", "..globalVarName
		else
			paramsLine = globalVarName
		end

		c = c + 1
		c2 = c2 + 1
	end

	linesOfFunc[evalFunc][c] = "call TriggerEvaluate(evalTrig_"..func..")"

	c = c + 1

	local pos, posEnd = linesOfFunc[func][1]:find(" returns ", 1, true)

	local globalReturnVar
	local returnType = getFuncParams(func)["return"]

	if (returnType ~= "nothing") then
		globalReturnVar = "f__result_"..returnType
	end

	if globalReturnVar then
		linesOfFunc[evalFunc][c] = "return "..globalReturnVar

		c = c + 1
	end

	linesOfFunc[evalFunc][c] = "endfunction"

	c = 1

	while linesOfFunc[evalFunc][c] do
		output:write("\n"..linesOfFunc[evalFunc][c])

		c = c + 1
	end

	c = 1
	local evalTargetFunc = "evalTarget_"..func

	while linesOfFunc[func][c] do
		c = c + 1
	end

	linesOfFunc[func][c] = "function "..evalTargetFunc.." takes nothing returns nothing"

	c = c + 1

	if globalReturnVar then
		linesOfFunc[func][c] = "set "..globalReturnVar.." = "..func.."("..paramsLine..")"
	else
		linesOfFunc[func][c] = "call "..func.."("..paramsLine..")"
	end

	c = c + 1

	linesOfFunc[func][c] = "endfunction"

	linesOfFunc[func][c + 1] = "set evalTrig_"..func.." = CreateTrigger()"
	linesOfFunc[func][c + 2] = "call TriggerAddCondition(evalTrig_"..func..", evalTarget_"..func..")"

	return evalFunc
end

local function replaceCalls(func, call)
print("search "..call.." in "..func)
	local c = 1

	while linesOfFunc[func][c] do
		local line = linesOfFunc[func][c]

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
print("line: "..line2)
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
						print("arg "..c2..": "..args[c2])

						c2 = c2 + 1
					end
				end

				line = line:sub(1, pos - 1)..writeEvalFunc(call)..line:sub(posEnd + 1, line:len())

				posEnd = posEnd + 5
			end

			pos, posEnd = line:find(call.."(", posEnd + 1, true)
		end

		linesOfFunc[func][c] = line

		c = c + 1
	end
end

local function regFunc(func, localTable, level)
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

	local reqS
	isFuncReg[func] = true
	localTable[func] = func

	for k, v in pairs(requires[func]) do
		if localTable[v] then
			outFuncs:write("\n"..indent.."cycle between "..func.." and "..v)
			outCycles:write("\n"..indent..func.." and "..v)
			outCycles:write("\n"..indent.."eval from "..func.." to "..v)
			replaceCalls(func, v)
		else
			regFunc(v, copyTable(localTable), level + 1)
		end

		if reqS then
			reqS = reqS..", "..v
		else
			reqS = v
		end
	end

	sortedFuncs[curPos] = func
	outFuncs:write("\n"..indent..func)

	local c = 1

	while linesOfFunc[func][c] do
		output:write("\n"..linesOfFunc[func][c])

		c = c + 1
	end

	if reqS then
		outFuncs:write(" Requires: "..reqS)
	end

	curPos = curPos + 1
end

regFunc("config")
regFunc("main")

for k, v in pairs(funcs) do
	local params = getFuncParams(v)

	if params[1] or params["return"] then
		--regFunc(v)
	end
end

outCycles:close()
outFuncs:close()
output:close()