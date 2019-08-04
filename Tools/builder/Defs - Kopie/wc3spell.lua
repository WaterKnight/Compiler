local t = {}

local builder

t.setup = function(builder)
	builder = _builder
end

local BUTTON_POS_X = {}

BUTTON_POS_X['HERO_FIRST'] = 0
BUTTON_POS_X['HERO_SECOND'] = 1
BUTTON_POS_X['ARTIFACT'] = 2
BUTTON_POS_X['ELEMENTAL'] = 3
BUTTON_POS_X['HERO_ULTIMATE'] = 1
BUTTON_POS_X['HERO_ULTIMATE_EX'] = 2
BUTTON_POS_X['NORMAL'] = 0

local BUTTON_POS_Y = {}

BUTTON_POS_Y['HERO_FIRST'] = 2
BUTTON_POS_Y['HERO_SECOND'] = 2
BUTTON_POS_Y['ARTIFACT'] = 2
BUTTON_POS_Y['ELEMENTAL'] = 2
BUTTON_POS_Y['HERO_ULTIMATE'] = 1
BUTTON_POS_Y['HERO_ULTIMATE_EX'] = 1
BUTTON_POS_Y['NORMAL'] = 2

local HOTKEY = {}

HOTKEY['HERO_FIRST'] = 'Q'
HOTKEY['HERO_SECOND'] = 'W'
HOTKEY['ARTIFACT'] = 'E'
HOTKEY['ELEMENTAL'] = 'R'
HOTKEY['HERO_ULTIMATE'] = 'F'
HOTKEY['HERO_ULTIMATE_EX'] = 'T'
HOTKEY['NORMAL'] = 'Q'

local IS_HERO_SPELL = {}

IS_HERO_SPELL['HERO_FIRST'] = true
IS_HERO_SPELL['HERO_SECOND'] = true
IS_HERO_SPELL['ELEMENTAL'] = true
IS_HERO_SPELL['HERO_ULTIMATE'] = true
IS_HERO_SPELL['HERO_ULTIMATE_EX'] = true

LEARN_BUTTON_POS_X = {}

LEARN_BUTTON_POS_X['HERO_FIRST'] = 0
LEARN_BUTTON_POS_X['HERO_SECOND'] = 1
LEARN_BUTTON_POS_X['ELEMENTAL'] = 3
LEARN_BUTTON_POS_X['HERO_ULTIMATE'] = 0
LEARN_BUTTON_POS_X['HERO_ULTIMATE_EX'] = 1

local LEARN_BUTTON_POS_Y = {}

LEARN_BUTTON_POS_Y['HERO_FIRST'] = 0
LEARN_BUTTON_POS_Y['HERO_SECOND'] = 0
LEARN_BUTTON_POS_Y['ELEMENTAL'] = 0
LEARN_BUTTON_POS_Y['HERO_ULTIMATE'] = 1
LEARN_BUTTON_POS_Y['HERO_ULTIMATE_EX'] = 1

local LEARN_HOTKEY = {}

LEARN_HOTKEY['HERO_FIRST'] = 'Q'
LEARN_HOTKEY['HERO_SECOND'] = 'W'
LEARN_HOTKEY['ELEMENTAL'] = 'R'
LEARN_HOTKEY['HERO_ULTIMATE'] = 'F'
LEARN_HOTKEY['HERO_ULTIMATE_EX'] = 'T'

local LEARN_SLOT = {}

LEARN_SLOT['HERO_FIRST'] = 0
LEARN_SLOT['HERO_SECOND'] = 1
LEARN_SLOT['ELEMENTAL'] = 4
LEARN_SLOT['HERO_ULTIMATE'] = 2
LEARN_SLOT['HERO_ULTIMATE_EX'] = 3

local LEVELS_AMOUNT = {}

LEVELS_AMOUNT['HERO_FIRST'] = 6
LEVELS_AMOUNT['HERO_SECOND'] = 6
LEVELS_AMOUNT['ARTIFACT'] = 6
LEVELS_AMOUNT['ELEMENTAL'] = 6
LEVELS_AMOUNT['HERO_ULTIMATE'] = 3
LEVELS_AMOUNT['HERO_ULTIMATE_EX'] = 3
LEVELS_AMOUNT['ITEM'] = 1
LEVELS_AMOUNT['NORMAL'] = 1

local ORDER = {}

ORDER['NORMAL'] = 'channel'
ORDER['PARALLEL_IMMEDIATE'] = 'berserk'
ORDER['AUTOCAST_IMMEDIATE'] = 'frenzy'

local AUTOCAST_ORDER_OFF = {}
local AUTOCAST_ORDER_ON = {}

AUTOCAST_ORDER_OFF['AUTOCAST_IMMEDIATE'] = 852563
AUTOCAST_ORDER_ON['AUTOCAST_IMMEDIATE'] = 852562

local TARGET = {}

TARGET['PARALLEL_IMMEDIATE'] = 'IMMEDIATE'

io.local_require([[..\buff]])
io.local_require([[..\color]])

t.defFunc = function(t)
	addToEnv(t)

	local fileName = getFileName(path, true)

	setDefVal('jassVar', toVar(fileName))
	setDefVal('jassVarIndex', toVarIndex(fileName))

	if (getVal('raw', 1) and (getVal('raw', 1):len() == 3)) then
		if dummy then
			setVal('raw', 'a'..getVal('raw', 1))
		else
			setVal('raw', 'A'..getVal('raw', 1))
		end
	end

	local class

	setDefVal('base', 'NORMAL')

	class = getVal('class', 1)

	local hero = IS_HERO_SPELL[class]

	if class then
		setDefVal('levelsAmount', LEVELS_AMOUNT[class])
	end
	setDefVal('order', ORDER[getVal('base', 1)])

	setDefVal('autoCastOrderOff', AUTOCAST_ORDER_OFF[getVal('base', 1)])
	setDefVal('autoCastOrderOn', AUTOCAST_ORDER_ON[getVal('base', 1)])
	setDefVal('target', TARGET[getVal('base', 1)])

	setDefVal('animation', 'spell')
	setDefVal('areaRangeDisplay', false)
	if class then
		setDefVal('range', 750)
	end

	setDefVal('buttonPosX', BUTTON_POS_X[class])
	setDefVal('buttonPosY', BUTTON_POS_Y[class])
	if (getVal('base', 1) == 'PASSIVE') then
		setDefVal('hotkey')
	else
		setDefVal('hotkey', HOTKEY[class])
	end
	if (getVal('base', 1) == 'AUTOCAST_IMMEDIATE') then
		setDefVal('iconDisabled', getVal('icon', 1))
	end

	--if hero then
        	setDefVal('learnButtonPosX', LEARN_BUTTON_POS_X[class])
		setDefVal('learnButtonPosY', LEARN_BUTTON_POS_Y[class])
		setDefVal('learnHotkey', HOTKEY[class])
		setDefVal('learnIcon', getVal('icon', 1))

		local raw = getVal('raw', 1)
		local learnRaw

		if raw then
			--learnRaw = raw:sub(2, 3)
		end

		setDefVal('learnRaw', learnRaw)
		setDefVal('learnSlot', LEARN_SLOT[class])
	--end
end

local HIDE_PLACEHOLDER_PREFIX = 'LP'
local HIDE_REPLACER_PREFIX = 'LR'

local function getHidePlaceholderRaw(learnRaw)
	return HIDE_PLACEHOLDER_PREFIX..learnRaw
end

local function getHideReplacerRaw(learnRaw)
	return HIDE_REPLACER_PREFIX..learnRaw
end

local LEARN_PREFIX = {}

LEARN_PREFIX[0] = 'F'
LEARN_PREFIX[1] = 'G'
LEARN_PREFIX[2] = 'H'
LEARN_PREFIX[3] = 'J'
LEARN_PREFIX[4] = 'K'

local LEARN_REPLACER_PREFIX = {}

LEARN_REPLACER_PREFIX[0] = 'V'
LEARN_REPLACER_PREFIX[1] = 'W'
LEARN_REPLACER_PREFIX[2] = 'X'
LEARN_REPLACER_PREFIX[3] = 'Y'
LEARN_REPLACER_PREFIX[4] = 'Z'

t.createFunc = function(t)
	addToEnv(t)

	local raw = getVal('raw', 1)

	if (raw == nil) then
		return
	end

	local widget = createWidget('ability', raw, nil, getVal('profileIdent', 1), path)

	local base = getVal('base', 1)
	local baseCode
	local channelBased

	if (base == 'NORMAL') then
		baseCode = 'ANcl'
		channelBased = true
	elseif (base == 'PARALLEL_IMMEDIATE') then
		baseCode = 'Absk'
	elseif (base == 'PASSIVE') then
		baseCode = 'Agyb'
	elseif (base == 'AUTOCAST_IMMEDIATE') then
		baseCode = 'Afzy'
	elseif (string.sub(base, 1, 1 + 7 - 1) == 'SPECIAL') then
		baseCode = string.sub(base, 1 + 7 + 1, string.len(base))
	end

	widget:setTrue('code', baseCode)

	local class = getVal('class', 1)
	local hero = getVal('hero', 1)

	widget:set('acap', '')
	widget:set('acat', '')
	widget:set('aeat', '')
	--widget:set('aher', '\0')
	widget:setTrue('hero', 0)
	widget:set('ahky', '')
	if (class == 'ITEM') then
		widget:set('aite', 1)
	end
	widget:set('anam', getVal('name', 1), 'defaultName(spell) '..nilToString(raw, 'NONE'))
	widget:set('areq', '')
	widget:set('ata0', '')
	widget:set('atat', '')

	widget:set('aani', getVal('animation', 1), '')
	widget:set('aart', getVal('icon', 1), '')
	widget:set('auar', getVal('iconDisabled', 1), nil)
	widget:set('abpx', getVal('buttonPosX', 1), 0)
	widget:set('abpy', getVal('buttonPosY', 1), 0)
	widget:set('ahky', getVal('hotkey', 1), '')
	widget:set('alev', levelsAmount)

	for level = 1, levelsAmount, 1 do
		if ((base == 'PARALLEL_IMMEDIATE') or (base == 'AUTOCAST_IMMEDIATE')) then
			widget:setLv('abuf', level, getObjVal(pathToFullPath(path, [[Header\Spell.page\Spell.struct\parallelCastBuff]], 'wc3buff'), 'raw', 1), '')
		end
		if ((channelBased ~= true) or getVal('areaRangeDisplay', level)) then
			widget:setLv('aare', level, tonumber(getVal('areaRange', level)), 0)
		end
		widget:setLv('acas', level, getVal('castTime', level), 0)
		widget:setLv('acdn', level, getVal('cooldown', level), 0)
		widget:setLv('amcs', level, getVal('manaCost', level), 0)
		widget:setLv('aran', level, getVal('range', level), 0)
		widget:setLv('atar', level, getVal('targets', level), '')
		widget:setLv('atp1', level, getVal('tooltip', level), '')
		widget:setLv('aub1', level, getVal('uberTooltip', level), '')
	end

	widget:doSpecials(getVal('specialsTrue'), getVal('specials'))

	if channelBased then	
		for level = 1, levelsAmount, 1 do
			local target = getVal('target', level)

			widget:setLv('Ncl1', level, 0)
			if (target == 'IMMEDIATE') then
				widget:setLv('Ncl2', level, 0)
			elseif (target == 'POINT') then
				widget:setLv('Ncl2', level, 2)
			elseif (target == 'POINT_OR_UNIT') then
				widget:setLv('Ncl2', level, 3)
			elseif (target == 'UNIT') then
				widget:setLv('Ncl2', level, 1)
			end
			--Ncl3 flags: 1 - visible, 2 - target art, 4 - physical ability, 8 - magical ability, 16 - unique cast
			if getVal('areaRangeDisplay', level) then
				widget:setLv('Ncl3', level, 1 + 2 + 16)
			else
				widget:setLv('Ncl3', level, 1 + 16)
			end
			widget:setLv('Ncl4', level, 0)
			widget:setLv('Ncl5', level, false)
			widget:setLv('Ncl6', level, getVal('order', level), '')
		end
	end

	if hero then
		local learnRaw = getVal('learnRaw', 1)
		local learnSlot = getVal('learnSlot', 1)

		if (learnRaw and learnSlot) then
			local index = learnSlot
			local learnPrefix = LEARN_PREFIX[learnSlot]

			local hidePlaceholderRaw = getHidePlaceholderRaw(learnRaw)
			local hideReplacerRaw = getHideReplacerRaw(learnRaw)

			local widget = createWidget('ability', hidePlaceholderRaw, nil, nil, path)

			widget:setTrue('code', 'Agyb')

			widget = createWidget('ability', hideReplacerRaw, nil, nil, path)

			widget:setTrue('code', 'ANeg')

			widget:set('abpx', 0)
			widget:set('abpy', 0)
			widget:set('aher', '\0')
			widget:set('ahky', '')
			widget:set('alev', 1)
			widget:set('anam', getVal('name', 1)..' Hero Spell Replacer Hider')
			widget:set('arac', 'other')
			widget:set('aret', '')
			widget:set('arhk', '')
			widget:set('arpx', 0)
			widget:set('arut', '')

			widget:setLv('abuf', 1, getObjVal(pathToFullPath(path, [[Header\Spell.page\HeroSpell.struct\spellReplacerBuff]], 'wc3buff'), 'raw', 1))
			widget:setLv('atp1', 1, '')
			widget:setLv('aub1', 1, '')
			widget:setLv('Neg1', 1, 0)
			widget:setLv('Neg2', 1, 0)
			widget:setLv('Neg3', 1, raw..','..hidePlaceholderRaw)
			widget:setLv('Neg4', 1, '')
			widget:setLv('Neg5', 1, '')
			widget:setLv('Neg6', 1, '')

			widget = createWidget('ability', 'V'..learnRaw..index, nil, nil, path)

			widget:setTrue('code', 'ANeg')

			widget:set('abpx', 0)
			widget:set('abpy', 0)
			widget:set('aher', '\1')
			widget:set('ahky', '')
			widget:set('alev', levelsAmount)
			widget:set('anam', getVal('name', 1)..' Hero Spell Replacer '..index)
			widget:set('arac', 'other')
			widget:set('aret', '')
			widget:set('arhk', '')
			widget:set('arpx', 0)
			widget:set('arut', '')

			for level = 1, levelsAmount, 1 do
				widget:setLv('abuf', level, getObjVal(pathToFullPath(path, [[Header\Spell.page\HeroSpell.struct\spellReplacerBuff]], 'wc3buff'), 'raw', 1))
				widget:setLv('atp1', level, '')
				widget:setLv('aub1', level, '')
				widget:setLv('Neg1', level, 0)
				widget:setLv('Neg2', level, 0)
				if (level == 1) then
					widget:setLv('Neg3', level, 'AHS'..index..','..learnPrefix..learnRaw..(level - 1))
				else
					--widget:setLv('Neg3', level, 'AHS'..index..','..learnPrefix..learnRaw..(level - 1))
					widget:setLv('Neg3', level, learnPrefix..learnRaw..(level - 2)..','..learnPrefix..learnRaw..(level - 1))
				end
				widget:setLv('Neg4', level, '')
				widget:setLv('Neg5', level, '')
				widget:setLv('Neg6', level, '')
			end

			for level = 1, levelsAmount, 1 do
				widget = createWidget('ability', learnPrefix..learnRaw..(level - 1), nil, nil, path)

				widget:setTrue('code', 'ANcl')

				widget:set('aani', '')
				widget:set('aart', '')
				widget:set('abpx', 0)
				widget:set('acap', '')
				widget:set('acat', '')
				widget:set('aeat', '')
				widget:set('aher', '\1')
				widget:set('ahky', '')
				widget:set('alev', 1)
				widget:set('anam', getVal('name', 1)..' Hero Spell Learner '..learnSlot..' Level '..level)
				widget:set('arac', 'other')

				widget:setLv('aran', 1, 0)
				widget:set('arar', getVal('icon', level), '')
				widget:set('ata0', '')
				widget:set('atat', '')
				widget:setLv('atp1', 1, '')
				widget:setLv('aub1', 1, '')
				widget:setLv('Ncl1', 1, 0)
				widget:setLv('Ncl3', 1, 0)
				widget:setLv('Ncl4', 1, 0)
				widget:setLv('Ncl5', 1, '\0')
				widget:setLv('Ncl6', 1, 'wispharvest')

				widget:set('aret', getVal('learnTooltip', level))
				widget:set('arhk', getVal('learnHotkey', 1))
				widget:set('arpx', getVal('learnButtonPosX', 1))
				widget:set('arpy', getVal('learnButtonPosY', 1))
				widget:set('arut', getVal('learnUberTooltip', level), '')
			end
		end
	end
end

t.jassType = 'Spell'
t.jassTypeDummy = 'integer'

t.jassIniter = [[call Spell.AddInit(%s)]]

t.jassFunc = function(t)
	addToEnv(t)

	local raw = getVal('raw', 1)

	if raw then
		writeLine([[call InitAbility('%s', %s)]], {raw, boolToString(false)})
	end

	local varExpr = addVar(getVal('jassVar', 1), 'Spell', getVal('jassVarIndex', 1))

	local hero = getVal('hero', 1)

	if (raw and raw ~= '') then
		writeLine([[set %s = Spell.CreateFromSelf('%s')]], {varExpr, raw})
	else
		writeLine([[set %s = Spell.CreateHidden(thistype.NAME + %s)]], {varExpr, toJassValue(' ('..fileName..')')})
	end

	writeLine('')

	if getVal('class', 1) then
		writeLine([[call %s.SetClass(SpellClass.%s)]], {varExpr, getVal('class', 1)})
	end
	if getVal('levelsAmount', 1) then
		writeLine([[call %s.SetLevelsAmount(%i)]], {varExpr, getVal('levelsAmount', 1)})
	end
	if getVal('name', 1) then
		writeLine([[call %s.SetName(%s)]], {varExpr, toJassValue(getVal('name', 1))})
	end
	if getVal('order', 1) then
		writeLine([[call %s.SetOrder(Order.GetFromSelf(OrderId(%s)))]], {varExpr, toJassValue(getVal('order', 1))})
	end
	if getVal('autoCastOrderOff', 1) then
		writeLine([[call %s.SetAutoCastOrderOff(Order.GetFromSelf(%s))]], {varExpr, getVal('autoCastOrderOff', 1)})
	end
	if getVal('autoCastOrderOn', 1) then
		writeLine([[call %s.SetAutoCastOrderOn(Order.GetFromSelf(%s))]], {varExpr, getVal('autoCastOrderOn', 1)})
	end
	if getVal('target', 1) then
		writeLine([[call %s.SetTargetType(Spell.TARGET_TYPE_%s)]], {varExpr, getVal('target', 1)})
	end

	if getVal('animation', 1) then
		writeLine([[call %s.SetAnimation(%s)]], {varExpr, toJassValue(getVal('animation', 1))})
	end
	for level = 1, levelsAmount, 1 do
		if getVal('areaRange', level) then
			writeLine([[call %s.SetAreaRange(%i, %s)]], {varExpr, level, getVal('areaRange', level)})
		end
		if getVal('castTime', level) then
			writeLine([[call %s.SetCastTime(%i, %i)]], {varExpr, level, getVal('castTime', level)})
		end
		if getVal('channelTime', level) then
			writeLine([[call %s.SetChannelTime(%i, %i)]], {varExpr, level, getVal('channelTime', level)})
		end
		if getVal('cooldown', level) then
			writeLine([[call %s.SetCooldown(%i, %i)]], {varExpr, level, getVal('cooldown', level)})
		end
		if getVal('manaCost', level) then
			writeLine([[call %s.SetManaCost(%i, %i)]], {varExpr, level, getVal('manaCost', level)})
		end
		if getVal('range', level) then
			writeLine([[call %s.SetRange(%i, %i)]], {varExpr, level, getVal('range', level)})
		end
	end

	if getVal('icon', 1) then
		writeLine([[call %s.SetIcon(%s)]], {varExpr, toJassValue(getVal('icon', 1))})
	end

	writeLine('')

	if hero then
		local learnRaw = getVal('learnRaw', 1)
		local learnSlot = getVal('learnSlot', 1)

		if (learnRaw and learnSlot) then
			writeLine([[call HeroSpell.InitSpell(%s, 'F%s0', %i, 'V%s0', '%s', '%s')]], {varExpr, learnRaw, levelsAmount, learnRaw, getHidePlaceholderRaw(learnRaw), getHideReplacerRaw(learnRaw)})
		end

		writeLine('')
	end
end

t.jassFuncDummy = function(t)
	addToEnv(t)

	local raw = getVal('raw', 1)

	if raw then
		addVar(getVal('jassVar', 1)..'Id', 'integer', getVal('jassVarIndex', 1), string.format([['%s']], raw))

		writeLine([[call InitAbility('%s', %s)]], {raw, boolToString(isExtended)})
	end
end

--io.local_require([[tagReplacement.lua]])

t.tagsFunc = function(t, obj)
	addToEnv(t)

	local levelsAmount = obj.levelsAmount

	local sharedBuffs = {}

	for level = 0, levelsAmount, 1 do
		sharedBuffs[level] = {}

		local t = getVal('sharedBuffs', level)

		if (type(t) == 'string') then
			t = t:split(';')

			if (type(t) == 'table') then
				for k, v in pairs(t) do
					sharedBuffs[level][k] = v
				end
			end
		end
	end

	for level = 1, levelsAmount, 1 do
		if (getVal('tooltip', level) == nil) then
			if getVal('name', level) then
				setVal('tooltip', level, module_color.encolor(getVal('name', level), module_color.DWC))
			end
		end

		if getVal('hotkey', level) then
			if (getVal('tooltip', level) == nil) then
				setVal('tooltip', level, '('..module_color.engold(getVal('hotkey', level))..') ')
			else
				setVal('tooltip', level, '('..module_color.engold(getVal('hotkey', level))..') '..getVal('tooltip', level))
			end
		end
		if (levelsAmount > 1) then
			if (getVal('tooltip', level) == nil) then
				setVal('tooltip', level, ' ['..module_color.engold('Level '..level)..']')
			else
				setVal('tooltip', level, getVal('tooltip', level)..' ['..module_color.engold('Level '..level)..']')
			end
		end

		if (getVal('uberTooltip', level) == nil) then
			setVal('uberTooltip', level, nil)
		end

		if getVal('uberTooltip', level) then
			setVal('uberTooltip', level, replaceTags('uberTooltip', getVal('uberTooltip', level), level, true))
		end

		for key, buff in pairs(sharedBuffs[level]) do
			if module_sharedBuff.getById(buff) then
				if (getVal('uberTooltip', level) == nil) then
					setVal('uberTooltip', level, module_sharedBuff.getById(buff).description)
				else
					setVal('uberTooltip', level, getVal('uberTooltip', level)..'|n|n'..module_sharedBuff.getById(buff).description)
				end
			end
		end

		if getVal('lore', level) then
			if (getVal('uberTooltip', level) == nil) then
				setVal('uberTooltip', level, module_color.engold(getVal('lore', level)))
			else
				setVal('uberTooltip', level, getVal('uberTooltip', level)..'|n|n'..module_color.engold(getVal('lore', level)))
			end
		end

		if getVal('cooldown', level) then
			if (getVal('cooldown', level) > 0) then
				if (getVal('uberTooltip', level) == nil) then
					setVal('uberTooltip', level, module_color.encolor('Cooldown: '..module_color.engold(getVal('cooldown', level))..' seconds', module_color.DWC))
				else
					setVal('uberTooltip', level, getVal('uberTooltip', level)..'|n|n'..module_color.encolor('Cooldown: '..module_color.engold(getVal('cooldown', level))..' seconds', module_color.DWC))
				end
			end
		end

		if getVal('hero', 1) then
			if (getVal('learnTooltip', level) == nil) then
				if getVal('name', level) then
					setVal('learnTooltip', level, module_color.encolor(getVal('name', level), module_color.DWC))
				end

				if getVal('hotkey', level) then
					if (getVal('learnTooltip', level) == nil) then
						setVal('learnTooltip', level, '('..module_color.engold(getVal('hotkey', level))..') ')
					else
						setVal('learnTooltip', level, '('..module_color.engold(getVal('hotkey', level))..') '..getVal('learnTooltip', level))
					end
				end
				if (levelsAmount > 1) then
					if (getVal('learnTooltip', level) == nil) then
						setVal('learnTooltip', level, ' ['..module_color.engold('Level '..level)..']')
					else
						setVal('learnTooltip', level, getVal('learnTooltip', level)..' ['..module_color.engold('Level '..level)..']')
					end
				end

				if getVal('learnTooltip', level) then
					setVal('learnTooltip', level, 'Learn '..getVal('learnTooltip', level))
				end
			end

			if getVal('learnTooltip', level) then
				setVal('learnTooltip', level, replaceTags('learnTooltip', getVal('learnTooltip', level), level, true))
			end
			if getVal('learnUberTooltip', level) then
				setVal('learnUberTooltip', level, replaceTags('learnUberTooltip', getVal('learnUberTooltip', level), level, true))

				if (level > 0) then
					if getVal('learnUberTooltipUpgrades', level) then
						local upgrades = getVal('learnUberTooltipUpgrades', level):split(';')

						local function addField(name, alias)
							if getVal(field, level) then
								upgrades[#upgrades + 1] = '{'..name..','..alias..'}'
							end
						end

						addField('{Area range,<areaRange>}')
						addField('{Channel time,<channelTime>}')
						addField('{Mana cost,<manaCost>}')
						addField('{Cast range,<range>}')

						if (#upgrades > 0) then
							local upgradesString = ''

							local i = 1

							while upgrades[i] do
								upgrades[i] = upgrades[i]:debracket('{', '}')

								local vals = upgrades[i]:splitOuter(',', {{'<', '>'}, {'{', '}'}})

								local alias = vals[1]
								local field = vals[2]

								local prevVal
								if (level > 1) then
									prevVal = replaceTags('learnUberTooltipUpgrades', field, level - 1, true)
								end
								local newVal = replaceTags('learnUberTooltipUpgrades', field, level, true)

								if (level == 1) then
									upgradesString = upgradesString..'|n\t'..alias..': '..newVal
								else
									if (prevVal ~= newVal) then
										upgradesString = upgradesString..'|n\t'..alias..': '..prevVal..' --> '..newVal
									end
								end

								--[[upgrades[i] = upgrades[i]:debracket('{', '}')

								local vals = upgrades[i]:split(',')

								local field = vals[1]
								local alias = vals[2]
								local mods

								if (field:sub(1, 1) == '{') then
									field = field.debracket('{', '}')
								end

								local prevVal = replaceTags('learnUberTooltipUpgrades', '<'..field..'>', level - 1, true)
								local newVal = replaceTags('learnUberTooltipUpgrades', '<'..field..'>', level, true)

								if (prevVal ~= newVal) then
									upgradesString = upgradesString..'|n\t'..alias..': '..prevVal..' --> '..newVal
								end]]

								i = i + 1
							end

							if (upgradesString:len() > 0) then
								if (level == 1) then
									setVal('learnUberTooltip', level, getVal('learnUberTooltip', level)..'|n|n'..module_color.engold('First level stats:')..upgradesString)
								else
									setVal('learnUberTooltip', level, getVal('learnUberTooltip', level)..'|n|n'..module_color.engold('Next level:')..upgradesString)
								end
							else
								--print(path)
								--osLib.pause()
							end
						end
					end
				end
			end
		end
	end
end

return t