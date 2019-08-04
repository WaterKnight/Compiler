require 'waterlua'

io.local_require([[loaderLib]])

local params = {...}

local dataPath = params[1]
local specsPath = params[2]

osLib.clearScreen()

print('loader', 'dataPath=', dataPath, 'specsPath=', specsPath)

assert(dataPath, 'no dataPath')
assert(specsPath, 'no specsPath')

require 'pather'

local pathMap = pather.createPathMap(dataPath)

local logPath = io.local_dir()..[[Logs\loaderLog.log]]

createDir(getFolder(logPath))

local outputPath = io.local_dir()..'objectBuilderInput.lua'
local outputFile

removeFile(outputPath)

local function addLine(line, subArgs)
	if subArgs then
		line = string.format(line, unpack(subArgs))
	end

	outputFile:write(line..'\n')
end

local function addFile(path, isMod)
	addLine(string.format([[objectBuilder.defSheetFromPath(%q)]], path))
end

local function start()
	--update obj
	local doUpdates = true

	if doUpdates then
		outputFile = io.open(outputPath, 'w+')

		addLine([[local jassIdents]])
		addLine([[local levelVals]])
		addLine([[local arrayFields]])
		addLine([[local customFields]])
		addLine([[local dummy]])
		addLine([[local levelsAmount]])

		for extension in pairs(loaderLib.typeDefs) do
--print('extension '..extension)
			for _, path in pairs(getFiles(dataPath, '*.'..extension)) do
--print('load', path)
				addFile(path)
			end
		end

		local files = getFiles(dataPath, '*.wc3objLua')

		for _, path in pairs(files) do
			addLine(string.format([[objectBuilder.execScriptFromPath(%q)]], path))
		end

		outputFile:close()
	end
end

start()

osLib.ack()