require 'waterlua'
require 'wc3libs'

local params = {...}

local dataPath = params[1]
local buildPath = params[2]
local specsPath = params[3]
local defFuncPath = params[4]
local createFuncPath = params[5]

local inputPath = io.local_dir()..'objectBuilderInput.lua'

osLib.clearScreen()

local logsDir = io.local_dir()..[[Logs\]]

createDir(logsDir)

local logFile = io.open(logsDir..[[objectBuilderLog.log]], 'w+')

local function log(...)
	print(...)
	logFile:write(..., '\n')
end

log('objectBuilder:', 'dataPath=', dataPath, 'buildPath=', buildPath)

assert(dataPath, 'no root path')
assert(specsPath, 'no specs path')

addPackagePath(specsPath..'?')

local clock = osLib.createTimer()

local outputPath = io.local_dir()..[[output\]]
local sheetOutputPath = io.local_dir()..[[output\]]

local function nilTo(val, inval)
	if (val == nil) then
		return inval
	end

	return val
end

removeDir(outputPath)
removeDir(sheetOutputPath)

local objsById = {}

local function createObj(id, raw, path)
	assert(id, 'no id')

	local this = objsById[id]

	if (this ~= nil) then
		if (path ~= nil) then
			if (this.path ~= nil) then
				log(string.format('%s: id %s already declared at %s', path, id, this.path))
			else
				log(string.format('%s: id %s already declared', path, id))
			end
		else
			if (this.path ~= nil) then
				log(string.format('id %s already declared at %s', id, this.path))
			else
				log(string.format('id %s already declared'), id)
			end
		end
	else
		this = {}

		this.id = id
		this.path = raw

		objsById[id] = this
	end

	return this
end

local function createWidget(raw, slk, objMod, path)
	assert(raw, 'no raw')

	local this = createObj(raw, path)

	function this:setInSlk(field, val, level)
		assert(field, 'no field')

		if (level ~= nil) then
			field = field..level
		end

		slk:getObj(this.id):set(field, val)
	end

	function this:set(field, val, defaultVal)
		assert(field, 'no field')

		if (val == nil) then
			objMod:getObj(this.id):set(field, defaultVal)
		else
			objMod:getObj(this.id):set(field, val)
		end
	end

	function this:setLv(field, val, level, defaultVal)
		assert(field, 'no field')

		if (val == nil) then
			objMod:getObj(this.id):set(field, defaultVal, level)
		else
			objMod:getObj(this.id):set(field, val, level)
		end
	end

	function this:doSpecials(specialsTrue, specials)
		if (specialsTrue ~= nil) then
			for level, levelData in pairs(totable(specialsTrue)) do
				levelData = totable(levelData)

				for _, line in pairs(levelData) do
					local field, val = line:match('(%w*)=(%w*)')

					this:setInSlk(field, val, level)
				end
				
			end
		end

		if (specials ~= nil) then
			for level, levelData in pairs(totable(specials)) do
				levelData = totable(levelData)

				for _, line in pairs(levelData) do
					local field, val = line:match('(%w*)=(%w*)')

					this:setLv(field, val, level)
				end
			end
		end
	end

	return this
end

require 'wc3bolt'

local bolts = wc3bolt.create()

local function createBolt(raw, path)
	assert(raw, 'no raw')

	local this = createObj(raw, path)

	this.bolt = bolts:createObj(raw)

	return this
end

require 'wc3weather'

local weathers = wc3weather.create()

local function createWeather(raw, path)
	assert(raw, 'no raw')

	local this = createObj(raw, path)

	this.weather = weathers:createObj(raw)

	return this
end

require 'wc3buff'

local buffs = wc3buff.createMix()

local function createBuff(raw, path)
	assert(raw, 'no raw')

	local this = createWidget(raw, buffs.slk, buffs.mod)

	this.slk = buffs.slk:addObj(raw)
	this.mod = buffs.mod:addObj(raw)
	--this.buff = buffs:addObj(raw)

	return this
end

require 'wc3ability'

local abilities = wc3ability.createMix()

local function createAbility(raw, path)
	assert(raw, 'no raw')

	local this = createWidget(raw, abilities.slk, abilities.mod)

	this.slk = abilities.slk:addObj(raw)
	this.mod = abilities.mod:addObj(raw)
	--this.ability = abilities:addObj(raw)

	return this
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function createJStream(path)
	assert(path, 'no path')

	local this = {}

	this.lines = {}

	function this:addLine(line)
		assert(line, 'no line')

		if (type(line) == 'table') then
			local t = line

			for i = 1, #t, 1 do
				this:addLine(t[i])
			end

			return
		end

		local t = line:split('\n')

		for _, line in pairs(t) do
			this.lines[#this.lines + 1] = line
		end
	end

	return this
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local sheetsByPath = {}

local function getSheetFromPath(path)
	assert(path, 'no path')

	if (sheetsByPath[path] == nil) then
		log('getSheetFromPath: sheet at '..path..' does not exist')
	end

	return sheetsByPath[path]
end

require 'pather'

local pathMap = pather.createPathMap(dataPath)

local function getSheet(sheetOrPath)
	local res

	if (type(sheetOrPath) == 'string') then
		local path = sheetOrPath

		path = pathMap:toFullPath(nil, path)

		if (res ~= nil) then
			res = getSheetFromPath(path)
		end

		if (res == nil) then
			log('getSheet: sheet '..path:quote()..' does not exist')
		end
	else
		res = sheetOrPath
	end

	return res
end

local function getValOfPaths(basePath, paths, mainExtension, field, level)
	assert(paths, 'no paths')

	local res = {}

	for _, path in pairs(paths) do
		path = pathMap:toFullPath(basePath, path, mainExtension)

		local sheet = getSheetFromPath(path)

		assert(sheet, 'sheet '..tostring(path)..' not found')

		res[#res + 1] = sheet:getVal(field, level)
	end

	return res
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local typeDefs = {}

for _, path in pairs(getFiles(io.local_dir()..[[Defs\]], '*.lua')) do
	local sheetType = getFileName(path, true)

	typeDefs[sheetType] = loadfile(path)()
end

local function getJassFileName(path)
	return getFileName(path):gsub('%.', '_'):trim('['):trim(']')
end

local function replaceStuff(sheet, errorFile)
	assert(sheet, 'no sheet')
	assert(errorFile, 'no errorFile')

	require 'tagReplacement'

	local tagReplacer = tagReplacement.create(pathMap)

	tagReplacer:addColor('DWC', 0, 0, 0)
	tagReplacer:addColor('GOLD', 0, 0, 0)

	local typeDef = typeDefs[sheet.type]

	if (typeDef ~= nil) then
		if (typeDef.tagsFunc ~= nil) then
			local t = {
				sheet = sheet,
				tagReplacer = tagReplacer,
				log = log,

				pathToFullPath = function(...) return pathMap:toFullPath(...) end,
				getVal = function(...) return sheet:getVal(...) end,
				setVal = function(...) sheet:setVal(...) end
			}

			typeDef.tagsFunc(t)
		end
	end

	for field, fieldData in pairs(sheet.fields) do
		local vals = fieldData.vals

		for level, val in pairs(vals) do
			if ((type(level) == 'number') and (type(val) == 'string')) then
				sheet:setVal(field, level, tagReplacer:exec(field, val, level, false, sheet.path))
			end
		end
	end
end

local function toJassVal(val)
	assert(val, 'no val')

	if (type(val) == 'string') then
		return string.format('%q', val)
	end

	return val
end

local function toVar(s)
	assert(s, 'no value')

	s = getFileName(s, true)

	local pos = s:find('[', 1, true)

	if pos then
		return s:sub(1, pos - 1)
	end

	return s
end

local function toVarIndex(s)
	assert(s, 'no value')

	s = getFileName(s, true)

	local pos, posEnd, index = s:find('%[(%d*)%]')

	if index then
		return tonumber(index)
	end

	return nil
end

local sheetQueue = {}

local function processSheets()
	log('process sheets')

	pathMap:writeToFile(logsDir..[[pathMap.txt]])

	local skins = {}

	local c = 1

	while (sheetQueue[c] ~= nil) do
		local sheet = sheetQueue[c]

		local sheetType = sheet.type

		local typeDef = typeDefs[sheetType]

		if (typeDef == nil) then
			log(string.format('warning: unknown typeDef %s', sheetType))
		end

		c = c + 1
	end

	--alter definitions
	local c = 1

	while (sheetQueue[c] ~= nil) do
		local sheet = sheetQueue[c]

		--log('def '..sheet.path)

		local sheetType = sheet.type

		local typeDef = typeDefs[sheetType]

		--assert(typeDef, 'unknown typeDef '..sheetType)

		if (typeDef ~= nil) then
			local defFunc = typeDef.defFunc

			if (defFunc ~= nil) then
				local params = {
					sheet = sheet,
					toVar = toVar,
					toVarIndex = toVarIndex,
					log = log,

					getVal = function(...) return sheet:getVal(...) end,
					setVal = function(...) sheet:setVal(...) end,
					setDefVal = function(...) sheet:setDefVal(...) end
				}

				defFunc(params)
			end
		end

		c = c + 1
	end

	if (defFuncPath ~= nil) then
		local defunc = loadfileSyntaxCheck(defFuncPath, true)

		defFunc()
	end

	--replace tags
	local replaceErrors = io.open(logsDir..[[objectBuilderReplaceErrors.txt]], 'w+')

	local c = 1

	while (sheetQueue[c] ~= nil) do
		local sheet = sheetQueue[c]

		replaceStuff(sheet, replaceErrors)

		c = c + 1
	end

	replaceErrors:close()

	--print final sheets for debug
	createDir(sheetOutputPath)

	local c = 1

	while (sheetQueue[c] ~= nil) do
		local sheet = sheetQueue[c]

		--sheet:writeToFile(sheetOutputPath..sheet.path)

		c = c + 1
	end

	--create stuff
	local c = 1

	while (sheetQueue[c] ~= nil) do
		local sheet = sheetQueue[c]

		--log('create '..sheet.path)

		local sheetType = sheet.type

		local typeDef = typeDefs[sheetType]

		--assert(typeDef, 'unknown typeDef '..sheetType)

		if (typeDef ~= nil) then
			local createFunc = typeDef.createFunc

			if (createFunc ~= nil) then
				local params = {
					nilTo = nilTo,
					sheetPathsToRaw = sheetPathsToRaw,
					getSheet = getSheet,
					sheet = sheet,
					inval = function(val, inval) if (val ~= nil) then return val end return inval end,
					toJassVal = toJassVal,
					log = log,

					pathToFullPath = function(...) return pathMap:toFullPath(...) end,
					getVal = function(...) return sheet:getVal(...) end,
					--setVal = function(...) sheet:setVal(...) end,

					createBolt = createBolt,
					createWeather = createWeather,

					createBuff = createBuff,
					createAbility = createAbility,

					createJStream = function(...) return sheet:createJStream(...) end
				}

				createFunc(params, sheet)
			end
		end

		c = c + 1
	end

	if (createFuncPath ~= nil) then
		local createFunc = loadfileSyntaxCheck(createFuncPath, true)

		createFunc()
	end

	--
	local skinEditPath = io.local_dir()..'skinEditor.lua'

	local skinEditFunc = loadfileSyntaxCheck(skinEditPath, true)

	skinEditFunc(dataPath, buildPath, skins)
end

local function defSheet(sheet)
	assert(sheet, 'no sheet')

	local this = sheet

	pathMap:add(sheet.path, sheet.path)

	sheetQueue[#sheetQueue + 1] = this

	sheetsByPath[sheet.path] = this

	if (sheet.refNames ~= nil) then
		local t = totable(sheet.refNames)

		for _, name in pairs(t) do
			pathMap:add(name, sheet.path, true)
		end
	end

	----------------------------------------------------------------------------

	function this:createAbility(raw)
		createAbility(raw, this.path)
	end

	function this:createBuff(raw)
		createBuff(raw, this.path)
	end

	----------------------------------------------------------------------------

	this.jStreams = {}

	function this:createJStream()
		local jStream = createJStream(this.path)

		this.jStreams[#this.jStreams + 1] = jStream

		return jStream
	end
end

local t = {}

t.defSheet = defSheet

require 'loaderLib'

local defFile = io.open(logsDir..[[defFile.txt]], 'w+')

local function defSheetFromPath(path)
	assert(path, 'no path')

	require 'wc3objSheet'

	local sheet = wc3objSheet.create(getFileExtension(path), specsPath, path)

	sheet:readFromFile(path)

	defFile:write('\n'..path)

	defSheet(sheet)
end

t.defSheetFromPath = defSheetFromPath

local function execScriptFromPath(path)
	assert(path, 'no path')

	local f = loadfileSyntaxCheck(path, true)

	f()
end

t.execScriptFromPath = execScriptFromPath

local function finalize()
	processSheets()

	log('output')

	createDir(outputPath)

	abilities:writeToDir(outputPath, true)
	buffs:writeToDir(outputPath, true)
	--objContainer:output(outputPath, [[CampaignUnitFunc.txt]])
end

objectBuilder = t

log('inputPath=', inputPath)

local inputFunc = loadfileSyntaxCheck(inputPath, true)

inputFunc()

defFile:close()

finalize()

log(string.format('finished in %s seconds', clock:getElapsed()))