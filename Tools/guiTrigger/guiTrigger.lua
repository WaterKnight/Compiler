local params = {...}

local buildPath = params[1]

local path = buildPath..[[\war3map.wtg]]
local path = [[D:\war3map4.wtg]]

funcArgs = {}

local cat
local f = io.open("TriggerData.txt")

local catArgsOffset = {}

catArgsOffset["TriggerEvents"] = 2
catArgsOffset["TriggerConditions"] = 2
catArgsOffset["TriggerActions"] = 2
catArgsOffset["TriggerCalls"] = 4

require "stringLib"

for line in f:lines() do
	if ((line ~= "") and (line:find("//", 1, true) ~= true)) then
		if (line:sub(1, 1) == "[") then
			cat = line:sub(2, line:find("]", 1, true) - 1)
		end
		if ((cat == "TriggerEvents") or (cat == "TriggerConditions") or (cat == "TriggerActions") or (cat == "TriggerCalls")) then
			if ((line:sub(1, 1) ~= "_") and line:find("=", 1, true)) then
				local field = line:sub(1, line:find("=", 1, true) - 1)
				local args = line:sub(line:find("=", 1, true) + 1, line:len()):split(",")

				local function add(...)
					local arg = {...}
					local n = select('#', ...)
					local t = {}

					for c = 1, n, 1 do
						if (arg[c] ~= "nothing") then
							t[c] = arg[c]
						end
					end

					return t
				end

				args = add(unpack(args, catArgsOffset[cat], #args))

				funcArgs[field] = args
			end
		end
	end
end

f:close()

require "wc3binaryFile"
require "wc3binaryMaskFuncs"

data = wc3binaryFile.create()

local t = os.clock()

data.readFromFile(path, guiTrigMaskFunc)

print(os.clock() - t)

local t = os.clock()

data.print()

print(os.clock() - t)

data.writeToFile("abc.wtg", guiTrigMaskFunc)