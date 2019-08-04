require 'waterlua'

local params = {...}

local dataPath = params[1]
local buildPath = params[2]

local inputPath = io.local_dir()..'input.j'
local outputPath = io.local_dir()..'output.j'

removeFile(outputPath)

print('buildPath', buildPath)

if buildPath then
	removeFile(inputPath)

	copyFile(buildPath..[[war3map.j]], inputPath, true)
end

local success = pcallPath(io.local_dir()..[[beforeJasshelper.lua]], {inputPath, outputPath, dataPath})
--local success = loadfile(io.local_dir()..[[beforeJasshelper.lua]])(inputPath, outputPath, dataPath)

if success then
	if buildPath then
		copyFile(outputPath, buildPath..[[war3map.j]], true)
	end

	osLib.exit(osLib.EXIT_SUCCESS)
else
	osLib.exit(osLib.EXIT_FAILURE)
end