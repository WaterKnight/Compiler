require 'orient'

addPackagePath([[D:\Warcraft III\Mapping\?\init]])

require 'waterlua'
require 'wc3libs'

local logPath = 'luaproachLog.log'

local log = io.open(logPath, 'w+')

local logDetailedPath = 'luaproachLogDetailed.log'

local logDetailed = io.open(logDetailedPath, 'w+')

logDetailed:close()

local function start(params)
	osLib.clearScreen()

	local timer = osLib.createTimer()

	local configPath = params[1]

	local config = configParser(configPath)

	assert(config, 'no config file '..tostring(configPath))

	local projectPath = config['project']
	local dataPath = config['data']
	local specsPath = config['specs']
	local compilePath = config['compile']

	local inputPath = compilePath..'input.w3x'
	local outputPath = compilePath..'output.w3x'
	local logTrackerLogPath = config['logTrackerLogPath']

	local map = params[2]

	local curMapPath = projectPath..'curMapPath.txt'

	if (map == nil) then
		map = io.getGlobal(curMapPath)
	end

	if (map == nil) then
		print([[no map found]])

		return
	end

	io.setGlobal(curMapPath, map)

	if not io.pathIsOpenable(map) then
		print([[cannot open map ]]..map)

		return
	end

	local buildNumPath = projectPath..'curBuildNum.txt'

	local buildNum = io.getGlobal(buildNumPath)

	if (buildNum == nil) then
		print([[no buildNum]])

		return
	end

	buildNum = buildNum + 1

	io.setGlobal(buildNumPath, buildNum)

	print('configPath', configPath)
	print('projectPath', projectPath)
	print('dataPath', dataPath)
	print('specsPath', specsPath)
	print('compilePath', compilePath)
	print('mapPath', mapPath)
	print('logTrackerLogPath', logTrackerLogPath)
	osLib.pause()

	local mapFileName = getFileName(map)
	local mapFolder = getFolder(map)

	flushDir(compilePath)

	copyFile(map, inputPath)

	if not io.pathIsOpenable(inputPath) then
		print([[cannot open map ]]..inputPath)

		return
	end

	print('compilePath: '..compilePath)

	io.local_require[[portLib]]

	local buildPath = compilePath..[[ported\]]

	mpqExtract(inputPath, '*', buildPath)

	removeFile(buildPath..[[(attributes)]])
	removeFile(buildPath..[[(listfile)]])

	local runable = true

	--osLib.runProg('lua', [[Tools\objectMorper\objectMorpher.lua]], {buildPath})

	--merge objects
	if not osLib.runProg(nil, [[Tools\builder\loader.bat]], {dataPath, specsPath}) then
		return
	end

	if not osLib.runProg(nil, [[Tools\builder\merge.bat]], {dataPath, buildPath, specsPath}) then
		return
	end

	if not osLib.runProg(nil, [[WEPlacements\starter.bat]]) then
		return
	end

	--import files
	local jassHelperPath = [[Tools\jassnewgenpack5d\]]

	local jassHelperCustomWEPath = jassHelperPath..[[CustomWE\]]

	flushDir(jassHelperCustomWEPath)

	copyDir([[Tools\builder\GeneratedImports]], jassHelperCustomWEPath, true)
	copyDir([[Tools\builder\GeneratedImports]], buildPath, true)

	--jassHelper and script
	if not osLib.runProg(nil, [[Tools\beforeJasshelper\starter.bat]], {dataPath, buildPath}) then
		return
	end

	local jassHelperArgs = {jassHelperPath, [[Tools\jassnewgenpack5d\jasshelper\common.j]], [[Tools\jassnewgenpack5d\jasshelper\blizzard.j]], buildPath..[[war3map.j]], buildPath..[[war3map.j]]}

	local jassErrorPath = [[Tools\jassnewgenpack5d\jasshelper\jassParserCLIErrors.txt]]

	removeFile(jassErrorPath:quote())

	if not osLib.runProg(nil, [[jassHelperStarter.bat]], jassHelperArgs) then
		return
	end

	if io.pathExists([[Tools\jassnewgenpack5d\logs\compileerrors.txt]]) then
		runable = false

		return
	end

	if not osLib.runProg(nil, [[Tools\jassnewgenpack5d\jasshelper\pjassStart.bat]], {buildPath..[[war3map.j]]}) then
		return
	end

	if io.pathIsOpenable(jassErrorPath) then
		local content = io.getGlobal(jassErrorPath)

		if ((content ~= nil) and (content ~= '')) then
			runable = false

			osLib.runProg(buildPath..[[war3map.j]])
			osLib.runProg(jassErrorPath)

			return
		end
	else
		print('could not open '..jassErrorPath)
	end

	--funcSorter
	if not osLib.runProg(nil, [[Tools\funcSorter\starter.bat]], {buildPath}) then
		return
	end

	--info file
	if not osLib.runProg(nil, [[Tools\infoFiler\starter.bat]], {buildPath, buildNum}) then
		return
	end

	--skinEdit
	--if not osLib.runProg(nil, [[Tools\skinEdit\starter.bat]], {dataPath, buildPath}) then
	--	return
	--end

	--finished
	print('finished')

	removeFile(outputPath)

	local porter = createMpqPort()

	porter:addCreate(outputPath)
	porter:addImport(buildPath..[[*]])

	porter:commit(outputPath)

	--header
	osLib.runProg('lua', [[addHeader.lua]], {outputPath})

	if runable then
		print('compiled in '..timer:getElapsed()..' seconds')

		local outputOptPath = getFolder(outputPath)..getFileName(outputPath, true)..'_opt.w3x'

		if not osLib.runProg(nil, [[D:\Warcraft III\Mapping\Compiler\Tools\wc3Optimizer\start.bat]], {outputPath, outputOptPath}) then
			return
		end

		local size = io.getFileSize(outputOptPath)

		io.write(string.format('build #%i has been completed (%i kb). Start now? (y/n) ', buildNum, math.cutFloat(size / 1024, 0)))

		local runNow = false

		repeat
			runNowIn = osLib.waitForKeystroke()
		until ((runNowIn == 'y') or (runNowIn == 'n'))

		print(runNowIn)

		if (runNowIn == 'y') then
			runNow = true
		end

		if runNow then
			if logTrackerLogPath then
				print('logTrackerLogPath', logTrackerLogPath)
				osLib.runProg(nil, [[Tools\logTrackerWait.bat]], {logTrackerLogPath}, nil, true)
			else
				print('no logTrackerLogPath set')
			end

			if not osLib.runProg(nil, [[D:\Warcraft III\windowStart.bat]], {outputOptPath}) then
				return
			end
		end
	end

	return true
end

if not start({...}) then
	print('there were errors')
	osLib.pause()
end

log:close()