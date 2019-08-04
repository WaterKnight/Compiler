local t = {}

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

require 'buff'
require 'color'

t.defFunc = function(t)
	addToEnv(t)

	local fileName = getFileName(sheet.path, true)

	setDefVal('jassVar', toVar(fileName))
	setDefVal('jassVarIndex', toVarIndex(fileName))

	if ((getVal('raw') ~= nil) and (getVal('raw'):len() == 3)) then
		if dummy then
			setVal('raw', 'a'..getVal('raw'))
		else
			setVal('raw', 'A'..getVal('raw'))
		end
	end

	local class

	setDefVal('base', 'NORMAL')

	class = getVal('class')

	local hero = IS_HERO_SPELL[class]

	if (class ~= nil) then
		setDefVal('levelsAmount', LEVELS_AMOUNT[class])
	end
	setDefVal('order', ORDER[getVal('base')])

	setDefVal('autoCastOrderOff', AUTOCAST_ORDER_OFF[getVal('base')])
	setDefVal('autoCastOrderOn', AUTOCAST_ORDER_ON[getVal('base')])
	setDefVal('target', TARGET[getVal('base')])

	setDefVal('animation', 'spell')
	setDefVal('areaRangeDisplay', false)
	if class then
		setDefVal('range', 750)
	end

	setDefVal('buttonPosX', BUTTON_POS_X[class])
	setDefVal('buttonPosY', BUTTON_POS_Y[class])
	if (getVal('base') == 'PASSIVE') then
		setDefVal('hotkey')
	else
		setDefVal('hotkey', HOTKEY[class])
	end
	if (getVal('base') == 'AUTOCAST_IMMEDIATE') then
		setDefVal('iconDisabled', getVal('icon'))
	end

	--if hero then
        	setDefVal('learnButtonPosX', LEARN_BUTTON_POS_X[class])
		setDefVal('learnButtonPosY', LEARN_BUTTON_POS_Y[class])
		setDefVal('learnHotkey', HOTKEY[class])
		setDefVal('learnIcon', getVal('icon'))

		local raw = getVal('raw')
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

	local raw = getVal('raw')

	if (raw == nil) then
		return
	end

	local abil = createAbility(raw, path, getVal('profileIdent'))

	local base = getVal('base')
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

	abil.slk:setCode(baseCode)

	local class = getVal('class')
	local hero = getVal('hero')

	abil:setInSlk('hero', 0)
	if (class == 'ITEM') then
		abil.mod:setItem(true)
	end
	abil.mod:setName(inval(getVal('name'), 'defaultName(spell) '..nilToString(raw, 'NONE')))

	abil.mod:setAnim(getVal('animation'))
	abil.mod:setIcon(getVal('icon'))
	abil.mod:setIconUn(getVal('iconDisabled'))
	abil.mod:setButtonPos(getVal('buttonPosX'), getVal('buttonPosY'))
	abil.mod:setHotkey(getVal('hotkey'))
	abil.mod:setLevels(sheet.levelsAmount)

	for level = 1, sheet.levelsAmount, 1 do
		if ((base == 'PARALLEL_IMMEDIATE') or (base == 'AUTOCAST_IMMEDIATE')) then
			local parallelCastBuff = getSheet(pathToFullPath(path, [[Header\Spell.page\Spell.struct\parallelCastBuff]], 'wc3buff'))

			if (parallelCastBuff ~= nil) then
				abil.mod:setBuffId(parallelCastBuff:getVal('raw'), level)
			end
		end
		if ((channelBased ~= true) or getVal('areaRangeDisplay', level)) then
			abil.mod:setArea(tonumber(getVal('areaRange', level)), level)
		end
		abil.mod:setCastTime(getVal('castTime', level), level)
		abil.mod:setCooldown(getVal('cooldown', level), level)
		abil.mod:setManaCost(getVal('manaCost', level), level)
		abil.mod:setRange(getVal('range', level), level)
		abil.mod:setTargets(getVal('targets', level), level)
		abil.mod:setTooltip(getVal('tooltip', level), level)
		abil.mod:setUberTooltip(getVal('uberTooltip', level), level)
	end

	abil:doSpecials(getVal('specialsTrue'), getVal('specials'))

	if (channelBased ~= nil) then
		for level = 1, sheet.levelsAmount, 1 do
			local target = getVal('target', level)

			abil.mod:set('Ncl1', 0, level)
			if (target == 'IMMEDIATE') then
				abil.mod:set('Ncl2', 0, level)
			elseif (target == 'POINT') then
				abil.mod:set('Ncl2', 2, level)
			elseif (target == 'POINT_OR_UNIT') then
				abil.mod:set('Ncl2', 3, level)
			elseif (target == 'UNIT') then
				abil.mod:set('Ncl2', 1, level)
			end
			--Ncl3 flags: 1 - visible, 2 - target art, 4 - physical ability, 8 - magical ability, 16 - unique cast
			if getVal('areaRangeDisplay', level) then
				abil.mod:set('Ncl3', 1 + 2 + 16, level)
			else
				abil.mod:set('Ncl3', 1 + 16, level)
			end
			abil.mod:set('Ncl4', 0, level)
			abil.mod:set('Ncl5', false, level)
			abil.mod:set('Ncl6', getVal('order', level), level)
		end
	end

	if hero then
		local learnRaw = getVal('learnRaw')
		local learnSlot = getVal('learnSlot')

		if ((learnRaw ~= nil) and (learnSlot ~= nil)) then
			local index = learnSlot
			local learnPrefix = LEARN_PREFIX[learnSlot]

			local hidePlaceholderRaw = getHidePlaceholderRaw(learnRaw)
			local hideReplacerRaw = getHideReplacerRaw(learnRaw)

			local abil = createAbility(hidePlaceholderRaw, path)

			abil.slk:setCode('Agyb')

			local abil = createAbility(hideReplacerRaw, path)

			abil.slk:setCode('ANeg')

			abil.mod:setName(getVal('name')..' Hero Spell Replacer Hider')
			abil.mod:setRace('other')

			abil.mod:setBuffId(1, getSheet(pathToFullPath(path, [[Header\Spell.page\HeroSpell.struct\spellReplacerBuff]], 'wc3buff')):getVal('raw'))
			abil.mod:set('Neg3', raw..','..hidePlaceholderRaw, 1)

			local abil = createAbility('V'..learnRaw..index, path)

			abil.slk:setCode('ANeg')

			abil.slk:setHero(true)
			abil.mod:setLevels(sheet.levelsAmount)
			abil.mod:setName(getVal('name')..' Hero Spell Replacer '..index)
			abil.mod:setRace('other')

			for level = 1, sheet.levelsAmount, 1 do
				abil.mod:setBuffId(getSheet(pathToFullPath(path, [[Header\Spell.page\HeroSpell.struct\spellReplacerBuff]], 'wc3buff')):getVal('raw'), level)

				if (level == 1) then
					abil.mod:set('Neg3', 'AHS'..index..','..learnPrefix..learnRaw..(level - 1), level)
				else
					--abil.mod:set('Neg3', 'AHS'..index..','..learnPrefix..learnRaw..(level - 1), level)
					abil.mod:set('Neg3', learnPrefix..learnRaw..(level - 2)..','..learnPrefix..learnRaw..(level - 1), level)
				end
			end

			for level = 1, sheet.levelsAmount, 1 do
				local abil = createAbility(learnPrefix..learnRaw..(level - 1), path)

				abil.slk:setCode('ANcl')

				abil.mod:setHero(true)
				abil.mod:setName(getVal('name')..' Hero Spell Learner '..learnSlot..' Level '..level)
				abil:set('arac', 'other')

				abil.mod:set('Ncl6', 'wispharvest', 1)

				abil.mod:setResearchTooltip(getVal('learnTooltip', level))
				abil.mod:setResearchHotkey(getVal('learnHotkey'))
				abil.mod:setResearchButtonPos(getVal('learnButtonPosX'), getVal('learnButtonPosY'))
				abil.mod:setResearchUberTooltip(getVal('learnUberTooltip', level))
			end
		end
	end

	require 'vjass'

	local script = vjass.create()

	local raw = getVal('raw')

	if (getVal('dummy') ~= nil) then
		if (raw ~= nil) then
			script:addVar(getVal('jassVar')..'Id', 'integer', getVal('jassVarIndex'), string.format([['%s']], raw))

			script:addLine([[call InitAbility('%s', %s)]], {raw, boolToString(isExtended)})
		end
	else
		if (raw ~= nil) then
			script:addLine([[call InitAbility('%s', %s)]], {raw, boolToString(false)})
		end

		local varExpr = script:addVar(getVal('jassVar'), 'Spell', getVal('jassVarIndex'))

		local hero = getVal('hero')

		if ((raw ~= nil) and (raw ~= '')) then
			script:addLine([[set %s = Spell.CreateFromSelf('%s')]], {varExpr, raw})
		else
			script:addLine([[set %s = Spell.CreateHidden(thistype.NAME + %s)]], {varExpr, toJassVal(' ('..fileName..')')})
		end

		script:addLine('')

		if (getVal('class') ~= nil) then
			script:addLine([[call %s.SetClass(SpellClass.%s)]], {varExpr, getVal('class')})
		end
		if (getVal('levelsAmount') ~= nil) then
			script:addLine([[call %s.SetLevelsAmount(%i)]], {varExpr, getVal('levelsAmount')})
		end
		if (getVal('name') ~= nil) then
			script:addLine([[call %s.SetName(%s)]], {varExpr, toJassVal(getVal('name'))})
		end
		if (getVal('order') ~= nil) then
			script:addLine([[call %s.SetOrder(Order.GetFromSelf(OrderId(%s)))]], {varExpr, toJassVal(getVal('order'))})
		end
		if (getVal('autoCastOrderOff') ~= nil) then
			script:addLine([[call %s.SetAutoCastOrderOff(Order.GetFromSelf(%s))]], {varExpr, getVal('autoCastOrderOff')})
		end
		if (getVal('autoCastOrderOn') ~= nil) then
			script:addLine([[call %s.SetAutoCastOrderOn(Order.GetFromSelf(%s))]], {varExpr, getVal('autoCastOrderOn')})
		end
		if (getVal('target') ~= nil) then
			script:addLine([[call %s.SetTargetType(Spell.TARGET_TYPE_%s)]], {varExpr, getVal('target')})
		end

		if (getVal('animation') ~= nil) then
			script:addLine([[call %s.SetAnimation(%s)]], {varExpr, toJassVal(getVal('animation'))})
		end
		for level = 1, sheet.levelsAmount, 1 do
			if (getVal('areaRange', level) ~= nil) then
				script:addLine([[call %s.SetAreaRange(%i, %s)]], {varExpr, level, getVal('areaRange', level)})
			end
			if (getVal('castTime', level) ~= nil) then
				script:addLine([[call %s.SetCastTime(%i, %i)]], {varExpr, level, getVal('castTime', level)})
			end
			if (getVal('channelTime', level) ~= nil) then
				script:addLine([[call %s.SetChannelTime(%i, %i)]], {varExpr, level, getVal('channelTime', level)})
			end
			if (getVal('cooldown', level) ~= nil) then
				script:addLine([[call %s.SetCooldown(%i, %i)]], {varExpr, level, getVal('cooldown', level)})
			end
			if (getVal('manaCost', level) ~= nil) then
				script:addLine([[call %s.SetManaCost(%i, %i)]], {varExpr, level, getVal('manaCost', level)})
			end
			if (getVal('range', level) ~= nil) then
				script:addLine([[call %s.SetRange(%i, %i)]], {varExpr, level, getVal('range', level)})
			end
		end

		if (getVal('icon') ~= nil) then
			script:addLine([[call %s.SetIcon(%s)]], {varExpr, toJassVal(getVal('icon'))})
		end

		script:addLine('')

		if hero then
			local learnRaw = getVal('learnRaw')
			local learnSlot = getVal('learnSlot')

			if ((learnRaw ~= nil) and (learnSlot ~= nil)) then
				script:addLine([[call HeroSpell.InitSpell(%s, 'F%s0', %i, 'V%s0', '%s', '%s')]], {varExpr, learnRaw, sheet.levelsAmount, learnRaw, getHidePlaceholderRaw(learnRaw), getHideReplacerRaw(learnRaw)})
			end

			script:addLine('')
		end
	end

	createJStream():addLine(script:write())
end

--io.local_require([[tagReplacement.lua]])

t.tagsFunc = function(t)
	addToEnv(t)

	local sharedBuffs = {}

	for level = 0, sheet.levelsAmount, 1 do
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

	for level = 1, sheet.levelsAmount, 1 do
		if (getVal('tooltip', level) == nil) then
			if getVal('name', level) then
				setVal('tooltip', module_color.encolor(getVal('name', level), module_color.DWC), level)
			end
		end

		if getVal('hotkey', level) then
			if (getVal('tooltip', level) == nil) then
				setVal('tooltip', '('..module_color.engold(getVal('hotkey', level))..') ', level)
			else
				setVal('tooltip', '('..module_color.engold(getVal('hotkey', level))..') '..getVal('tooltip', level), level)
			end
		end
		if (sheet.levelsAmount > 1) then
			if (getVal('tooltip', level) == nil) then
				setVal('tooltip', ' ['..module_color.engold('Level '..level)..']', level)
			else
				setVal('tooltip', getVal('tooltip', level)..' ['..module_color.engold('Level '..level)..']', level)
			end
		end

		if (getVal('uberTooltip', level) == nil) then
			setVal('uberTooltip', nil, level)
		end

		if getVal('uberTooltip', level) then
			setVal('uberTooltip', tagReplacer:exec('uberTooltip', getVal('uberTooltip', level), level, true), level)
		end

		for key, buff in pairs(sharedBuffs[level]) do
			if module_sharedBuff.getById(buff) then
				if (getVal('uberTooltip', level) == nil) then
					setVal('uberTooltip', module_sharedBuff.getById(buff).description, level)
				else
					setVal('uberTooltip', getVal('uberTooltip', level)..'|n|n'..module_sharedBuff.getById(buff).description, level)
				end
			end
		end

		if getVal('lore', level) then
			if (getVal('uberTooltip', level) == nil) then
				setVal('uberTooltip', module_color.engold(getVal('lore', level)), level)
			else
				setVal('uberTooltip', getVal('uberTooltip', level)..'|n|n'..module_color.engold(getVal('lore', level)), level)
			end
		end

		if getVal('cooldown', level) then
			if (getVal('cooldown', level) > 0) then
				if (getVal('uberTooltip', level) == nil) then
					setVal('uberTooltip', module_color.encolor('Cooldown: '..module_color.engold(getVal('cooldown', level))..' seconds', module_color.DWC), level)
				else
					setVal('uberTooltip', getVal('uberTooltip', level)..'|n|n'..module_color.encolor('Cooldown: '..module_color.engold(getVal('cooldown', level))..' seconds', module_color.DWC), level)
				end
			end
		end

		if (getVal('hero') ~= nil) then
			if (getVal('learnTooltip', level) == nil) then
				if getVal('name', level) then
					setVal('learnTooltip', module_color.encolor(getVal('name', level), module_color.DWC), level)
				end

				if getVal('hotkey', level) then
					if (getVal('learnTooltip', level) == nil) then
						setVal('learnTooltip', '('..module_color.engold(getVal('hotkey', level))..') ', level)
					else
						setVal('learnTooltip', '('..module_color.engold(getVal('hotkey', level))..') '..getVal('learnTooltip', level), level)
					end
				end
				if (sheet.levelsAmount > 1) then
					if (getVal('learnTooltip', level) == nil) then
						setVal('learnTooltip', ' ['..module_color.engold('Level '..level)..']', level)
					else
						setVal('learnTooltip', getVal('learnTooltip', level)..' ['..module_color.engold('Level '..level)..']', level)
					end
				end

				if getVal('learnTooltip', level) then
					setVal('learnTooltip', 'Learn '..getVal('learnTooltip', level), level)
				end
			end

			if getVal('learnTooltip', level) then
				setVal('learnTooltip', tagReplacer:exec('learnTooltip', getVal('learnTooltip', level), level, true), level)
			end
			if getVal('learnUberTooltip', level) then
				setVal('learnUberTooltip', tagReplacer:exec('learnUberTooltip', getVal('learnUberTooltip', level), level, true), level)

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
									prevVal = tagReplacer:exec('learnUberTooltipUpgrades', field, level - 1, true)
								end
								local newVal = tagReplacer:exec('learnUberTooltipUpgrades', field, level, true)

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

								local prevVal = tagReplacer:exec('learnUberTooltipUpgrades', '<'..field..'>', level - 1, true)
								local newVal = tagReplacer:exec('learnUberTooltipUpgrades', '<'..field..'>', level, true)

								if (prevVal ~= newVal) then
									upgradesString = upgradesString..'|n\t'..alias..': '..prevVal..' --> '..newVal
								end]]

								i = i + 1
							end

							if (upgradesString:len() > 0) then
								if (level == 1) then
									setVal('learnUberTooltip', getVal('learnUberTooltip', level)..'|n|n'..module_color.engold('First level stats:')..upgradesString, level)
								else
									setVal('learnUberTooltip', getVal('learnUberTooltip', level)..'|n|n'..module_color.engold('Next level:')..upgradesString, level)
								end
							end
						end
					end
				end
			end
		end
	end
end

return t