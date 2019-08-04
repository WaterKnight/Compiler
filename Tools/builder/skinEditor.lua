require 'waterlua'

require 'slkLib'
require 'wc3objSheet'
require 'tagReplacement'

local params = {...}

local dataPath = params[1]
local buildPath = params[2]
local skins = params[3]

--assert(dataPath, 'no dataPath')
--assert(buildPath, 'no buildPath')
assert(skins, 'no skins')

local slk = slkLib.create()

slk:readFromFile(io.local_dir()..'SkinMetaData')

local sectionByField = {}

for obj in pairs(slk.objs) do
	obj = slk.objs[obj]

	local field = obj.vals['field']
	local section = obj.vals['section']

	sectionByField[field] = section
end

sections = {}

local function addField(field, val)
	if (val == nil) then
		val = ''
	else
		val = tagReplacement.replaceTags(field, val, 1, true)
	end

	local section = sectionByField[field]

	--assert(section, field..' has no section')
	if (section == nil) then
		section = 'FrameDef'
	end

	if (sections[section] == nil) then
		sections[section] = {}

		sections[section].vals = {}
	end

	sections[section].vals[field] = val
end

if buildPath then
	local f = io.open(buildPath..[[\war3mapSkin.txt]], 'r')

	if f then
		for line in f:lines() do
			local sepPos = line:find('=')

			if sepPos then
				local field = line:sub(1, sepPos - 1)
				local val = line:sub(sepPos + 1, line:len()):dequote()

				addField(field, val)
			end
		end

		f:close()
	end
end

for _, path in pairs(skins) do
	print(_, '-->', path)
	local obj = getObjFromPath(path)

	for _, field in pairs(obj.customFields) do
		addField(field, obj[field][1])
	end
end

local output = io.open('output.txt', 'w+')

for section, sectionData in pairs(sections) do
	output:write('\n\n['..section..']')

	for field, val in pairs(sectionData.vals) do
		if ((val == nil) or (val == '')) then
			val = ','
		else
			val = val--:quote()
		end

		output:write('\n'..field..'='..val)
	end
end

output:close()