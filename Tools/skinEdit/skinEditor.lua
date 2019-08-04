require "fileLib"
require "slkLib"
require "stringLib"
require "tableLib"
require "wc3objLib"

local params = {...}

local rootPath = params[1]
local buildPath = params[2]
local errorLog = io.open("error.log", "w+")

assert(rootPath, "no rootPath")
assert(buildPath, "no buildPath")

local slkData = readSlk("SkinMetaData")

local sectionByField = {}

for obj in pairs(slkData.objs) do
	obj = slkData.objs[obj]

	local field = obj.vals["field"]
	local section = obj.vals["section"]

	sectionByField[field] = section
end

sections = {}

local function addField(field, val)
	if (val == nil) then
		val = ""
	end

	local section = sectionByField[field]

	if (section == nil) then
		errorLog:write("\nfield "..field:quote().."("..val:quote()..")".." has no section")

		section = "FrameDef"
        end

	if (sections[section] == nil) then
		sections[section] = {}

		sections[section].vals = {}
	end

	sections[section].vals[field] = val
end

local f = io.open(buildPath..[[\war3mapSkin.txt]], "r")

if f then
	for line in f:lines() do
		local sepPos = line:find("=")

		if sepPos then
			local field = line:sub(1, sepPos - 1)
			local val = line:sub(sepPos + 1, line:len()):dequote()

			addField(field, val)
		end
	end

	f:close()
end

local files = getFiles(rootPath, "*.wc3skin")

for _, file in pairs(files) do
	print(file)
	local data = wc3objLib.create(file)

	for field, line in pairs(data.levelVals) do
		addField(field, line[1])
	end
end

local output = io.open("output.txt", "w+")

for section, sectionData in pairs(sections) do
	output:write("\n\n["..section.."]")

	for field, val in pairs(sectionData.vals) do
		if ((val == nil) or (val == "")) then
			val = ","
		else
			val = val--:quote()
		end

		output:write("\n"..field.."="..val)
	end
end

output:close()

errorLog:close()