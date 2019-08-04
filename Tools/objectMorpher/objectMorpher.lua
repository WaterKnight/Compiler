params = {...}

outputFolder = [[D:\Warcraft III\Mapping\DWC\Tools\ObjectMorpher\Output\]]

require "slkLib"

function loadMeta(path)
	local slk = readSlk(path, true)

	local data = slk.data

	for obj, objData in pairs(slk.objs) do
		metaToTrue[objData["ID"]] = objData["field"]

		local dataNum = tonumber(objData["data"])

		if dataNum then
			if (dataNum > 0) then
				metaToTrue[objData["ID"]] = metaToTrue[objData["ID"]]..string.char(string.byte('A') + dataNum - 1)
			end
		end
	end
end

function loadMetas(path)
	metaToTrue = {}

	local t = {}

	t[1] = "UnitMetaData.slk"
	t[2] = "DestructableMetaData.slk"
	t[3] = "AbilityBuffMetaData.slk"
	t[4] = "AbilityMetaData.slk"
	t[5] = "UpgradeMetaData.slk"
	t[6] = "DoodadMetaData.slk"

	local c = 1

	while t[c] do
		local found
		local search = t[c]

		local file = io.popen([[dir "MetaSlks\]]..search..[[" 2>nul /b /s]])

		for line in file:lines() do
			if (found == nil) then
				found = true
				loadMeta(line)
			end
		end

		if (found == nil) then
			print("did not find "..t[c])
		end

		c = c + 1
	end
end

loadMetas()

local t = {}

t[1] = ".w3u"
t[2] = ".w3t"
t[3] = ".w3b"
t[4] = ".w3d"
t[5] = ".w3a"
t[6] = ".w3h"
t[7] = ".w3q"

transExtension = {}

transExtension[".w3u"] = ".wc3unit"
transExtension[".w3t"] = ".wc3item"
transExtension[".w3b"] = ".wc3dest"
transExtension[".w3d"] = ".wc3dood"
transExtension[".w3a"] = ".wc3spell"
transExtension[".w3h"] = ".wc3buff"
transExtension[".w3q"] = ".wc3upgr"

usesLevels = {}

usesLevels[".w3d"] = true
usesLevels[".w3a"] = true
usesLevels[".w3q"] = true

objSlkPaths = {}

objSlkPaths[1] = "Doodads\\Doodads.slk"
objSlkPaths[2] = "Units\\AbilityData.slk"
objSlkPaths[3] = "Units\\AbilityBuffData.slk"
objSlkPaths[4] = "Units\\ItemData.slk"
objSlkPaths[5] = "Units\\UnitData.slk"
objSlkPaths[6] = "Units\\UnitAbilities.slk"
objSlkPaths[7] = "Units\\UnitBalance.slk"
objSlkPaths[8] = "Units\\UnitUI.slk"
objSlkPaths[9] = "Units\\UnitWeapons.slk"
objSlkPaths[10] = "Units\\DestructableData.slk"

objSlks = {}

local c = 1

while objSlkPaths[c] do
	local path

	for line in io.popen([[dir "Input\Imports\]]..objSlkPaths[c]..[[" /b /s]]):lines() do
		path = line
	end

	if (path == nil) then
		path = "StdObjSlks\\"..objSlkPaths[c]
		print(objSlkPaths[c].." not found, try std")
	end

	local t = readSlk(path, true)

	if t then
		objSlks[t] = t
	end

	c = c + 1
end

os.execute("del "..outputFolder:quote().." /q")

os.execute("mkdir "..outputFolder:quote())

local errorOut = io.open("errors.log", "w+")

for _, extension in pairs(t) do
	for line in io.popen([[dir "Input\war3map]]..extension..[[" /b /s]]):lines() do
		local inp = io.open(line, "rb")
		local out = io.open("output"..extension..".txt", "w")

		local data = inp:read("*all")

		local curPos = 1

		local function readInt()
			local i = 4
			local result = 0

			for i = 0, 3, 1 do
				result = result + tonumber(data:sub(curPos + i, curPos + i):byte()) * math.pow(256, i)
			end

			curPos = curPos + 4

			if (result > math.pow(2, 32) / 2) then
				return (result - math.pow(2, 32))
			end

			return result
		end

		local function readReal()
			local result = ""

			for i = 3, 0, -1 do
				local num = tonumber(data:sub(curPos + i, curPos + i):byte())

				for i2 = 7, 0, -1 do
					local quo = math.floor(num / math.pow(2, i2))

					num = num - quo * math.pow(2, i2)
					result = result..quo
				end
			end

			result = result:reverse()

			local exp = 0
			local frac = 1

			for i = 1, 23, 1 do
				frac = frac + result:sub(24-i, 24-i) * math.pow(2, -i)
			end
			for i = 24, 31, 1 do
				exp = exp + tonumber(result:sub(i, i)) * math.pow(2, i - 24)
			end
			local sign = result:sub(32, 32)

			result = math.pow(-1, sign) * frac * math.pow(2, exp - 127)

			curPos = curPos + 4

			result = math.floor(result * math.pow(10, 2) + 0.5) / math.pow(10, 2)

			return result
		end

		local function readUnreal()
			local result = readReal()

			return result
		end

		local function readString()
			local til = curPos

			while (tonumber(data:sub(til, til):byte()) ~= 0) do
				til = til + 1
			end

			local result = data:sub(curPos, til - 1)

			curPos = til + 1

			return result
		end

		local function readId()
			local result = data:sub(curPos, curPos + 3)

			curPos = curPos + 4

			return result
		end

		readInt()

		amount = readInt()
		curObj = 0

		print("orig:")
		print(amount)

		local function createObject(raw, baseRaw)
			local maxLevel = 1
			local objData = {}

			local function readMods()
				local amount = readInt()

				for i = 1, amount, 1 do
					local mod = readId()

					local data
					local level
					local varType = readInt()

					if usesLevels[extension] then
						level = readInt()

						data = readInt()
					end

					if (varType == 0) then
						val = readInt()
					elseif (varType == 1) then
						val = readReal()
					elseif (varType == 2) then
						val = readUnreal()
					elseif (varType == 3) then
						val = readString()
					else
						print("unrecognized varType "..varType)
						print("evaluate as string and hope for best")
						val = readString()
					end

					if (metaToTrue[mod] == nil) then
						print("mod "..mod.." unrecognized")
					else
						local tmp = metaToTrue[mod]

						if level then
							tmp = tmp.."("..level..")"
						end

						out:write("\n\t"..tmp..": "..val)
					end

					readId()

					if (level and (level > 0)) then
						if (level > maxLevel) then
							maxLevel = level
						end

						if (objData[mod] == nil) then
							objData[mod] = {}
						end

						objData[mod][level] = val
					else
						objData[mod] = val
					end
				end
			end

			local function outputData()
				local curFile = io.open(outputFolder..raw..transExtension[extension], "w+")

				curFile:write("field\tjassIdent")

				for level = 1, maxLevel, 1 do
					curFile:write("\t"..level)
				end

				curFile:write("\nraw\t\t"..raw)

				if baseRaw then
					for slk in pairs(objSlks) do
						for obj, objData in pairs(slk.objs) do
							if (obj == baseRaw) then
								for field, val in pairs(objData) do
									curFile:write("\nspecialsTrue\t")

									curFile:write("\t"..field.."="..val)
								end
							end
						end
					end
				end

				for field, fieldData in pairs(objData) do
					curFile:write("\nspecials\t")

					if (type(fieldData) == "table") then
						for level = 1, maxLevel, 1 do
							if fieldData[level] then
								curFile:write("\t"..field.."="..fieldData[level])
							else
								curFile:write("\t")
							end
						end
					else
						curFile:write("\t"..field.."="..fieldData)
					end
				end

				curFile:close()
			end

			readMods()

			outputData()
		end

		while (curObj < amount) do
			baseRaw = readId()

			raw = readId()
			print("orig obj: "..baseRaw)
			out:write("\n"..baseRaw.." --> "..raw)

			createObject(baseRaw)

			curObj = curObj + 1
		end

		amount = readInt()
		curObj = 0

		print("custom:")
		print(amount)

		while (curObj < amount) do
			baseRaw = readId()

			raw = readId()
			print("custom obj: "..raw.."("..baseRaw..")")
			out:write("\n"..baseRaw.." --> "..raw)

			createObject(raw, baseRaw)

			curObj = curObj + 1
		end

		inp:close()
		out:close()
	end
end

errorOut:close()