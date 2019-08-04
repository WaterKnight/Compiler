--wc3binaryMaskFuncs.lua

require 'waterlua'

io.local_require('miscLib')

function checkFormatVer(sender, shouldBe, got)
	local okay

	if (type(shouldBe) == 'table') then
		for k, v in pairs(shouldBe) do
			if (v == got) then
				okay = true
			end
		end
	else
		okay = (got == shouldBe)
	end

	if not okay then
		if (type(shouldBe) == 'table') then
			local s

			for k, v in pairs(shouldBe) do
				if s then
					s = s..','..v
				else
					s = v
				end
			end

			s = '{'..s..'}'

			error(sender..': warning: wrong format version, got '..got..' instead of '..s, true)
		else
			error(sender..': warning: wrong format version, got '..got..' instead of '..shouldBe, true)
		end
	end
end

--format 18
function infoFileMaskFunc18(root)
	checkFormatVer('infoFileMaskFunc', 18, root:getVal('formatVersion'))

	root:add('savesAmount', 'int')
	root:add('editorVersion', 'int')
	root:add('mapName', 'string')
	root:add('mapAuthor', 'string')
	root:add('mapDescription', 'string')
	root:add('playersRecommendedAmount', 'string')
	for i = 1, 8, 1 do
		root:add('cameraBounds'..i, 'float')
	end
	root:add('boundaryMarginLeft', 'int')
	root:add('boundaryMarginRight', 'int')
	root:add('boundaryMarginBottom', 'int')
	root:add('boundaryMarginTop', 'int')
	root:add('mapWidthWithoutBoundaries', 'int')
	root:add('mapHeightWithoutBoundaries', 'int')
	root:add('flags', 'int', {
					'hideMinimap',
					'modifyAllyPriorities',
					'meleeMap',
					'initialMapSizeLargeNeverModified',
					'maskedAreasPartiallyVisible',
					'fixedPlayerForceSetting',
					'useCustomForces',
					'useCustomTechtree',
					'useCustomAbilities',
					'useCustomUpgrades',
					'mapPropertiesWindowOpenedBefore',
					'showWaterWavesOnCliffShores',
					'showWaterWavesOnRollingShores'
				})

	root:add('tileset', 'char')
	root:add('campaignBackgroundIndex', 'int')
	root:add('loadingScreenText', 'string')
	root:add('loadingScreenTitle', 'string')
	root:add('loadingScreenSubtitle', 'string')
	root:add('loadingScreenIndex', 'int')
	root:add('prologueScreenText', 'string')
	root:add('prologueScreenTitle', 'string')
	root:add('prologueScreenSubtitle', 'string')

	root:add('maxPlayers', 'int')

	local function createPlayer(index)
		local p = root:addNode('player'..index)

		p:add('num', 'int')
		p:add('type', 'int')
		p:add('race', 'int')
		p:add('startLocation', 'int')
		p:add('name', 'string')
		p:add('startLocationX', 'float')
		p:add('startLocationY', 'float')

		local t = {}

		for i = 1, root:getVal('maxPlayers'), 1 do
			t[i] = 'player'..i
		end

		p:add('allyLowPriorityFlags', 'int', t)
		p:add('allyHighPriorityFlags', 'int', t)
	end

	for i = 1, root:getVal('maxPlayers'), 1 do
		createPlayer(i)
	end

	root:add('maxForces', 'int')

	local function createForce(index)
		local f = root:addNode('force'..index)

		f:add('flags', 'int', {'allied', 'alliedVictory', 'sharedVision', 'shareUnitControl', 'shareUnitControlAdvanced'})

		local t = {}

		for i = 1, root:getVal('maxPlayers'), 1 do
			t[i] = 'player'..i
		end

		f:add('players', 'int', t)

		f:add('name', 'string')
	end

	for i = 1, root:getVal('maxForces'), 1 do
		createForce(i)
	end

	root:add('upgradeModsAmount', 'int')

	local function createUpgradeMod(index)
		local u = root:addNode('upgrade'..index)

		local t = {}

		for i = 1, root:getVal('maxPlayers'), 1 do
			t[i] = 'player'..i
		end

		u:add('players', 'int', t)
		u:add('id', 'id')
		u:add('level', 'int')
		u:add('availability', 'int')
	end

	for i = 1, root:getVal('upgradeModsAmount'), 1 do
		createUpgradeMod(i)
	end

	root:add('techModsAmount', 'int')

	local function createTechMod(index)
		local tech = root:addNode('tech'..index)

		local t = {}

		for i = 1, root:getVal('maxPlayers'), 1 do
			t[i] = 'player'..i
		end

		tech:add('players', 'int', t)

		tech:add('id', 'id')
	end

	for i = 1, root:getVal('techModsAmount'), 1 do
		createTechMod(i)
	end

	root:add('unitTablesAmount', 'int')

	local function createUnitTable(index)
		local t = root:addNode('unitTable'..index)

		t:add('index', 'int')

		t:add('name', 'string')

		t:add('positionsAmount', 'int')

		for i = 1, t:getVal('positionsAmount'), 1 do
			t:add('positionType'..i, 'int')
		end

		t:add('setsAmount', 'int')

		local function createSet(index)
			local s = t:addNode('set'..index)

			s:add('chance', 'int')

			for i = 1, t:getVal('positionsAmount'), 1 do
				s:add('id'..i, 'id')
			end
		end

		for i = 1, t:getVal('setsAmount'), 1 do
			createSet(i)
		end
	end

	for i = 1, root:getVal('unitTablesAmount'), 1 do
		createUnitTable(i)
	end
end

--format 25
function infoFileMaskFunc25(root)
	checkFormatVer('infoFileMaskFunc', 25, root:getVal('formatVersion'))

	root:add('savesAmount', 'int')
	root:add('editorVersion', 'int')
	root:add('mapName', 'string')
	root:add('mapAuthor', 'string')
	root:add('mapDescription', 'string')
	root:add('playersRecommendedAmount', 'string')
	for i = 1, 8, 1 do
		root:add('cameraBounds'..i, 'float')
	end
	root:add('boundaryMarginLeft', 'int')
	root:add('boundaryMarginRight', 'int')
	root:add('boundaryMarginBottom', 'int')
	root:add('boundaryMarginTop', 'int')
	root:add('mapWidthWithoutBoundaries', 'int')
	root:add('mapHeightWithoutBoundaries', 'int')
	root:add('flags', 'int', {
					'hideMinimap',
					'modifyAllyPriorities',
					'meleeMap',
					'initialMapSizeLargeNeverModified',
					'maskedAreasPartiallyVisible',
					'fixedPlayerForceSetting',
					'useCustomForces',
					'useCustomTechtree',
					'useCustomAbilities',
					'useCustomUpgrades',
					'mapPropertiesWindowOpenedBefore',
					'showWaterWavesOnCliffShores',
					'showWaterWavesOnRollingShores'
				})

	root:add('tileset', 'char')
	root:add('loadingScreenIndex', 'int')
	root:add('loadingScreenModelPath', 'string')
	root:add('loadingScreenText', 'string')
	root:add('loadingScreenTitle', 'string')
	root:add('loadingScreenSubtitle', 'string')
	root:add('gameData', 'int')
	root:add('prologueScreenPath', 'string')
	root:add('prologueScreenText', 'string')
	root:add('prologueScreenTitle', 'string')
	root:add('prologueScreenSubtitle', 'string')
	root:add('terrainFogType', 'int')
	root:add('terrainFogStartZHeight', 'float')
	root:add('terrainFogEndZHeight', 'float')
	root:add('terrainFogDensity', 'float')
	root:add('terrainFogBlue', 'byte')
	root:add('terrainFogGreen', 'byte')
	root:add('terrainFogRed', 'byte')
	root:add('terrainFogAlpha', 'byte')
	root:add('globalWeatherId', 'id')
	root:add('soundEnvironment', 'string')
	root:add('tilesetLightEnvironment', 'char')
	root:add('waterBlue', 'byte')
	root:add('waterGreen', 'byte')
	root:add('waterRed', 'byte')
	root:add('waterAlpha', 'byte')

	root:add('maxPlayers', 'int')

	local function createPlayer(index)
		local p = root:addNode('player'..index)

		p:add('num', 'int')
		p:add('type', 'int')
		p:add('race', 'int')
		p:add('startLocation', 'int')
		p:add('name', 'string')
		p:add('startLocationX', 'float')
		p:add('startLocationY', 'float')

		local t = {}

		for i = 1, root:getVal('maxPlayers'), 1 do
			t[i] = 'player'..i
		end

		p:add('allyLowPriorityFlags', 'int', t)
		p:add('allyHighPriorityFlags', 'int', t)
	end

	for i = 1, root:getVal('maxPlayers'), 1 do
		createPlayer(i)
	end

	root:add('maxForces', 'int')

	local function createForce(index)
		local f = root:addNode('force'..index)

		f:add('flags', 'int', {'allied', 'alliedVictory', 'sharedVision', 'shareUnitControl', 'shareUnitControlAdvanced'})

		local t = {}

		for i = 1, root:getVal('maxPlayers'), 1 do
			t[i] = 'player'..i
		end

		f:add('players', 'int', t)

		f:add('name', 'string')
	end

	for i = 1, root:getVal('maxForces'), 1 do
		createForce(i)
	end

	root:add('upgradeModsAmount', 'int')

	local function createUpgradeMod(index)
		local u = root:addNode('upgrade'..index)

		local t = {}

		for i = 1, root:getVal('maxPlayers'), 1 do
			t[i] = 'player'..i
		end

		u:add('players', 'int', t)
		u:add('id', 'id')
		u:add('level', 'int')
		u:add('availability', 'int')
	end

	for i = 1, root:getVal('upgradeModsAmount'), 1 do
		createUpgradeMod(i)
	end

	root:add('techModsAmount', 'int')

	local function createTechMod(index)
		local tech = root:addNode('tech'..index)

		local t = {}

		for i = 1, root:getVal('maxPlayers'), 1 do
			t[i] = 'player'..i
		end

		tech:add('players', 'int', t)

		tech:add('id', 'id')
	end

	for i = 1, root:getVal('techModsAmount'), 1 do
		createTechMod(i)
	end

	root:add('unitTablesAmount', 'int')

	local function createUnitTable(index)
		local t = root:addNode('unitTable'..index)

		t:add('index', 'int')

		t:add('name', 'string')

		t:add('positionsAmount', 'int')

		for i = 1, t:getVal('positionsAmount'), 1 do
			t:add('positionType'..i, 'int')
		end

		t:add('setsAmount', 'int')

		local function createSet(index)
			local s = t:addNode('set'..index)

			s:add('chance', 'int')

			for i = 1, t:getVal('positionsAmount'), 1 do
				s:add('id'..i, 'id')
			end
		end

		for i = 1, t:getVal('setsAmount'), 1 do
			createSet(i)
		end
	end

	for i = 1, root:getVal('unitTablesAmount'), 1 do
		createUnitTable(i)
	end

	root:add('itemTablesAmount', 'int')

	local function createItemTable(index)
		local t = root:addNode('itemTable'..index)

		t:add('index', 'int')
		t:add('name', 'string')
		t:add('setsAmount', 'int')

		local function createSet(index)
			local s = t:addNode('set'..index)

			s:add('itemsAmount', 'int')

			local function createItem(index)
				local i = s:addNode('item'..index)

				i:add('chance', 'int')
				i:add('id', 'id')
			end

			for i = 1, s:getVal('itemsAmount'), 1 do
				createItem(i)
			end
		end

		for i = 1, t:getVal('setsAmount'), 1 do
			createSet(i)
		end
	end

	for i = 1, root:getVal('itemTablesAmount'), 1 do
		createItemTable(i)
	end
end

function infoFileMaskFunc(root)
	root:add('formatVersion', 'int')

	local t = {}

	t[18] = infoFileMaskFunc18
	t[25] = infoFileMaskFunc25

	t[root:getVal('formatVersion')](root)
end

--format 1
function objMaskFunc(root)
	root:add('fileVersion', 'int')

	checkFormatVer('objMaskFunc', {1, 2}, root:getVal('fileVersion'))

	local varTypes = {}

	varTypes[0] = 'int'
	varTypes[1] = 'float'
	varTypes[2] = 'float'
	varTypes[3] = 'string'

	local function createPack(name)
		local pack = root:addNode(name)

		pack:add('objsAmount', 'int')

		local function createObj(index)
			local obj = pack:addNode('obj'..index)

			obj:add('base', 'id')
			obj:add('id', 'id')
			obj:add('modsAmount', 'int')

			local function createMod(index)
				local mod = obj:addNode('mod'..index)

				mod:add('id', 'id')
				mod:add('varType', 'int')

				mod:add('value', varTypes[mod:getVal('varType')])
				mod:add('endToken', 'id')
			end

			for i = 1, obj:getVal('modsAmount'), 1 do
				createMod(i)
			end
		end

		for i = 1, pack:getVal('objsAmount'), 1 do
			createObj(i)
		end
	end

	createPack('orig')
	createPack('custom')
end

--format 1
function objExMaskFunc(root)
	root:add('fileVersion', 'int')

	checkFormatVer('objExMaskFunc', {1, 2}, root:getVal('fileVersion'))

	local varTypes = {}

	varTypes[0] = 'int'
	varTypes[1] = 'float'
	varTypes[2] = 'float'
	varTypes[3] = 'string'

	local function createPack(name)
		local pack = root:addNode(name)

		pack:add('objsAmount', 'int')

		local function createObj(index)
			local obj = pack:addNode('obj'..index)

			obj:add('base', 'id')
			obj:add('id', 'id')
			obj:add('modsAmount', 'int')

			local function createMod(index)
				local mod = obj:addNode('mod'..index)

				mod:add('id', 'id')
				mod:add('varType', 'int')
				mod:add('variation', 'int')
				mod:add('dataPointer', 'int')

				mod:add('value', varTypes[mod:getVal('varType')])
				mod:add('endToken', 'id')
			end

			for i = 1, obj:getVal('modsAmount'), 1 do
				createMod(i)
			end
		end

		for i = 1, pack:getVal('objsAmount'), 1 do
			createObj(i)
		end
	end

	createPack('orig')
	createPack('custom')
end

--format 11
groundZero = 0x2000
waterZero = 89.6
cliffHeight = 0x0200

function rawToFinalGroundHeight(rawVal, cliffLevel)
	return ((rawVal - groundZero + (cliffLevel - 2) * cliffHeight) / 4)
end

function finalGroundToRawHeight(finalVal, cliffLevel)
	return (finalVal * 4 - (cliffLevel - 2) * cliffHeight + groundZero)
end

function rawToFinalWaterHeight(rawVal)
	return ((rawVal - groundZero) / 4) - waterZero
end

function finalWaterToRawHeight(finalVal)
	return ((finalVal + waterZero) * 4 + groundZero)
end

function envMaskFunc(root, mode)
	root:add('startToken', 'id')

	root:add('formatVersion', 'int')

	checkFormatVer('envMaskFunc', 11, root:getVal('formatVersion'))

	root:add('mainTileset', 'char')
	root:add('customTilesetsFlag', 'int')

	root:add('groundTilesetsUsed', 'int')
	for i = 1, root:getVal('groundTilesetsUsed'), 1 do
		root:add('groundTileset'..i..'id', 'id')
	end

	root:add('cliffTilesetsUsed', 'int')
	for i = 1, root:getVal('cliffTilesetsUsed'), 1 do
		root:add('cliffTileset'..i..'id', 'id')
	end

	root:add('width', 'int')
	root:add('height', 'int')
	root:add('centerX', 'float')
	root:add('centerY', 'float')

	flagsTable = {'tex', 'tex', 'tex', 'tex', 'ramp', 'blight', 'water', 'boundary2'}
	cliffFlagsTable = {'layer', 'layer', 'layer', 'layer', 'cliffTex', 'cliffTex', 'cliffTex', 'cliffTex'}
	waterLevelFlagsTable = {[15] = 'boundary'}

	local tilesCount = root:getVal('height') * root:getVal('width')

	local loadDisplay

	if (mode == 'reading') then
		loadDisplay = createLoadPercDisplay(tilesCount, 'reading tiles...')
	else
		loadDisplay = createLoadPercDisplay(tilesCount, 'writing tiles...')
	end

	local format = string.format

	local function createTile(index)
		local tile = root:addNode('tile'..format('%i', index))

		tile:add('groundHeight', 'short')
		tile:add('waterLevel', 'short', waterLevelFlagsTable)
		tile:add('flags', 'byte', flagsTable)
		tile:add('textureDetails', 'byte')
		tile:add('cliff', 'byte', cliffFlagsTable)

		loadDisplay:inc()
	end

	for i = 1, tilesCount, 1 do
		createTile(i)
	end
end

--format 7
local guiTrigData

function initGuiTrigData()
	if guiTrigData then
		return guiTrigData.funcArgs
	end

	local funcArgs = {}

	local cat
	local f = io.local_open('TriggerData.txt')

	local catArgsOffset = {}

	catArgsOffset['TriggerEvents'] = 2
	catArgsOffset['TriggerConditions'] = 2
	catArgsOffset['TriggerActions'] = 2
	catArgsOffset['TriggerCalls'] = 4

	for line in f:lines() do
		if ((line ~= '') and (line:find('//', 1, true) ~= true)) then
			if (line:sub(1, 1) == '[') then
				cat = line:sub(2, line:find(']', 1, true) - 1)
			end
			if ((cat == 'TriggerEvents') or (cat == 'TriggerConditions') or (cat == 'TriggerActions') or (cat == 'TriggerCalls')) then
				if ((line:sub(1, 1) ~= '_') and line:find('=', 1, true)) then
					local field = line:sub(1, line:find('=', 1, true) - 1)
					local args = line:sub(line:find('=', 1, true) + 1, line:len()):split(',')

					local function add(...)
						local arg = {...}
						local n = select('#', ...)
						local t = {}

						for c = 1, n, 1 do
							if (arg[c] ~= 'nothing') then
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

	guiTrigData = {}

	guiTrigData.funcArgs = funcArgs

	return funcArgs
end

function guiTrigMaskFunc(root)
	local funcArgs = initGuiTrigData()

	if (funcArgs == nil) then
		error('guiTrigMaskFunc - missing funcArgs from TriggerData.txt')
	end

	root:add('startToken', 'id')
	root:add('format', 'int')

	checkFormatVer('guiTrigMaskFunc', 7, root:getVal('format'))

	local function createTrigCat(index)
		local c = root:addNode('trigCategory'..index)

		c:add('index', 'int')
		c:add('name', 'string')
		c:add('type', 'int')
	end

	root:add('trigCategoriesAmount', 'int')
	for i = 1, root:getVal('trigCategoriesAmount'), 1 do
		createTrigCat(i)
	end

	root:add('unknownNumB', 'int')

	local varArrayTable = {}

	local function createVar(index)
		local v = root:addNode('var'..index)

		local name = v:add('name', 'string')
		v:add('type', 'string')
		v:add('unknownNumE', 'int')
		local arrayFlag = v:add('arrayFlag', 'int')
		v:add('arraySize', 'int')
		v:add('initFlag', 'int')
		v:add('initVal', 'string')

		if (arrayFlag:getVal() ~= 0) then
			varArrayTable[name:getVal()] = true
		end
	end

	root:add('varAmount', 'int')
	for i = 1, root:getVal('varAmount'), 1 do
		createVar(i)
	end

	local function createTrig(index)
		local t = root:addNode('trig'..index)

		t:add('name', 'string')
		t:add('description', 'string')
		t:add('comment', 'int')
		t:add('enabled', 'int')
		t:add('customTxtFlag', 'int')
		t:add('initFlag', 'int')
		t:add('runOnMapInit', 'int')
		t:add('categoryIndex', 'int')

		t:add('ECAAmount', 'int')

		local function createECA(parent, index, hasBranch)
			local eca = parent:addNode('ECA'..index)

			eca:add('type', 'int')

			if hasBranch then
				eca:add('branch', 'int')
			end

			local field = eca:add('funcName', 'string')
			eca:add('enabled', 'int')

			local function createParam(parent, index, paramType)
				local param = parent:addNode('param'..index)

				if ((paramType == 'boolexpr') or (paramType == 'boolcall') or (paramType == 'eventcall')) then
					param:add('boolexpr_unknown1', 'int')
					param:add('boolexpr_unknown2', 'int')
					param:add('boolexpr_unknown3', 'char')

					createECA(param, '('..paramType..')', false)

					param:add('boolexpr_endToken', 'int')
				elseif (paramType == 'code') then
					param:add('code_unknown1', 'int')
					local dummyDoNothing = param:add('code_dummyDoNothing', 'int')
					if (dummyDoNothing:getVal() == 0x100) then
						param:add('code_unknown2', 'char')
					else
						for i = 2, 11, 1 do
							param:add('code_unknown'..i, 'char')
						end
					end

					createECA(param, '(code)', false)

					param:add('code_endToken', 'int')
				else
					local type = param:add('type', 'int')
					local val = param:add('val', 'string')

					local beginFunc = param:add('beginFunc', 'int')

					if (beginFunc:getVal() == 1) then
						param:add('beginFunc_type', 'int')
						local field = param:add('beginFunc_val', 'string')
						param:add('beginFunc_beginFunc', 'int')

						field = field:getVal()

						for i = 1, #funcArgs[field], 1 do
							createParam(param, i, funcArgs[field][i])
						end

						param:add('beginFunc_endToken', 'int')
					end

					param:add('endToken', 'int')

					if ((type:getVal() == 1) and varArrayTable[val:getVal()]) then
						createParam(param, '(arrayIndex)', 'int')
					end
				end
			end

			field = field:getVal()

			for i = 1, #funcArgs[field], 1 do
				createParam(eca, i, funcArgs[field][i])
			end

			eca:add('ECAAmount', 'int')

			for i = 1, eca:getVal('ECAAmount'), 1 do
				createECA(eca, i, true)
			end
		end

		for i = 1, t:getVal('ECAAmount'), 1 do
			createECA(t, i, false)
		end
	end

	root:add('trigAmount', 'int')
	for i = 1, root:getVal('trigAmount'), 1 do
		createTrig(i)
	end
end

--format 8
function dooMaskFunc(root)
	root:add('startToken', 'id')
	root:add('format', 'int')

	checkFormatVer('dooMaskFunc', 8, root:getVal('format'))

	root:add('formatSub', 'int')

	root:add('treeCount', 'int')

	for i = 1, root:getVal('treeCount'), 1 do
		local tree = root:addNode('tree'..i)

		tree:add('type', 'id')

		tree:add('variation', 'int')
		tree:add('x', 'float')
		tree:add('y', 'float')
		tree:add('z', 'float')

		tree:add('angle', 'float')

		tree:add('scaleX', 'float')
		tree:add('scaleY', 'float')
		tree:add('scaleZ', 'float')

		tree:add('flags', 'byte')
		tree:add('life', 'byte')

		tree:add('itemTablePointer', 'int')

		tree:add('itemsDroppedCount', 'int')

		for i2 = 1, tree:getVal('itemsDroppedCount'), 1 do
			local itemSet = tree:addNode('item'..i2)

			itemSet:add('itemCount', 'int')

			for i3 = 1, itemSet:getVal('itemCount') do
				local item = itemSet:addNode('item'..i3)

				item:add('type', 'id')
				item:add('chance', 'int')
			end
		end

		tree:add('editorID', 'int')

	end

	--format 0
	root:add('specialTreeFormat', 'int')

	root:add('specialTreeCount', 'int')

	for i = 1, root:getVal('specialTreeCount'), 1 do
		local tree = root:addNode('specialTree'..i)

		tree:add('type', 'id')

		tree:add('z', 'float')
		tree:add('x', 'float')
		tree:add('y', 'float')
	end
end

--format 0
function camMaskFunc(root)
	root:add('format', 'int')

	checkFormatVer('camMaskFunc', 0, root:getVal('format'))

	root:add('camCount', 'int')

	for i = 1, root:getVal('camCount'), 1 do
		local tree = root:addNode('cam'..i)

		tree:add('targetX', 'float')
		tree:add('targetY', 'float')
		tree:add('zOffset', 'float')
		tree:add('rotation', 'float')
		tree:add('angleOfAttack', 'float')
		tree:add('dist', 'float')
		tree:add('roll', 'float')
		tree:add('fieldOfView', 'float')
		tree:add('farZ', 'float')
		tree:add('unknown', 'float')
		tree:add('cinematicName', 'string')
	end
end

--format 5
function rectMaskFunc(root)
	root:add('format', 'int')

	checkFormatVer('rectMaskFunc', 5, root:getVal('format'))

	root:add('rectsCount', 'int')

	for i = 1, root:getVal('rectsCount'), 1 do
		local rect = root:addNode('rect'..i)

		rect:add('minX', 'float')
		rect:add('minY', 'float')
		rect:add('maxX', 'float')
		rect:add('maxY', 'float')
		rect:add('name', 'string')
		rect:add('index', 'int')
		rect:add('weather', 'id')
		rect:add('sound', 'string')
		rect:add('blue', 'byte')
		rect:add('green', 'byte')
		rect:add('red', 'byte')
		rect:add('endToken', 'byte')
	end
end

--format 8
function dooUnitsMaskFunc(root)
	root:add('startToken', 'id')
	root:add('format', 'int')

	checkFormatVer('dooUnitsMaskFunc', 8, root:getVal('format'))

	root:add('formatSub', 'int')

	root:add('unitsCount', 'int')

	for i = 1, root:getVal('unitsCount'), 1 do
		local unit = root:addNode('unit'..i)

		unit:add('type', 'id')

		unit:add('variation', 'int')

		unit:add('x', 'float')
		unit:add('y', 'float')
		unit:add('z', 'float')

		unit:add('angle', 'float')

		unit:add('scaleX', 'float')
		unit:add('scaleY', 'float')
		unit:add('scaleZ', 'float')

		unit:add('flags', 'byte')
		unit:add('ownerIndex', 'int')
		unit:add('unknown', 'byte')
		unit:add('unknown2', 'byte')

		unit:add('life', 'int')
		unit:add('mana', 'int')

		unit:add('itemTablePointer', 'int')

		unit:add('itemsDroppedCount', 'int')

		for i2 = 1, unit:getVal('itemsDroppedCount'), 1 do
			local itemSet = unit:addNode('item'..i2)

			itemSet:add('itemCount', 'int')

			for i3 = 1, itemSet:getVal('itemCount') do
				local item = itemSet:addNode('item'..i3)

				item:add('type', 'id')
				item:add('chance', 'int')
			end
		end

		unit:add('resourceAmount', 'int')

		unit:add('targetAcquisition', 'float')

		unit:add('heroLevel', 'int')
		unit:add('heroStr', 'int')
		unit:add('heroAgi', 'int')
		unit:add('heroInt', 'int')

		unit:add('inventoryItemsCount', 'int')

		for i2 = 1, unit:getVal('inventoryItemsCount'), 1 do
			local item = unit:addNode('inventoryItem'..i2)

			item:add('slot', 'int')
			item:add('type', 'id')
		end

		unit:add('abilityModsCount', 'int')

		for i2 = 1, unit:getVal('abilityModsCount'), 1 do
			local item = unit:addNode('abilityMod'..i2)

			item:add('type', 'id')
			item:add('autocast', 'int')
			item:add('level', 'int')
		end

		unit:add('randomFlag', 'int')

		if (unit:getVal('randomFlag') == 0) then
			unit:add('randomLevel', 'byte')
			unit:add('randomLevel2', 'byte')
			unit:add('randomLevel3', 'byte')

			unit:add('randomClass', 'byte')
		elseif (unit:getVal('randomFlag') == 1) then
			unit:add('randomGroupIndex', 'int')
			unit:add('randomGroupPosition', 'int')
		elseif (unit:getVal('randomFlag') == 2) then
			unit:add('randomUnitsCount', 'int')

			for i2 = 1, unit:getVal('randomUnitsCount'), 1 do
				local item = unit:addNode('randomUnit'..i2)

				item:add('type', 'id')
				item:add('chance', 'int')
			end
		end

		unit:add('customColor', 'int')
		unit:add('waygateTargetRectIndex', 'int')

		unit:add('editorID', 'int')

	end
end

--format 1
function wctMaskFunc(root)
	root:add('format', 'int')

	checkFormatVer('dooUnitsMaskFunc', 1, root:getVal('format'))

	root:add('headComment', 'string')

	local trig = root:addNode('headTrig')

	trig:add('size', 'int')
	trig:add('text', 'string')

	root:add('trigsCount', 'int')

	for i = 1, root:getVal('trigsCount'), 1 do
		local trig = root:addNode('trig'..i)

		trig:add('size', 'int')
		trig:add('text', 'string')
	end
end