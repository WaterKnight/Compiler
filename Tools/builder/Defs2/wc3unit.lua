local t = {}

t.defFunc = function(t)
	addToEnv(t)

	local fileName = getFileName(path, true)

	setDefVal('jassVar', toVar(fileName))
	setDefVal('jassVarIndex', toVarIndex(fileName))

	local raw = getVal('raw', 1)

	if (raw and (raw:len() == 3)) then
		if dummy then
			if getVal('hero', 1) then
				setVal('raw', 'Q'..raw)
			else
				setVal('raw', 'q'..raw)
			end
		else
			if getVal('hero', 1) then
				setVal('raw', 'U'..raw)
			else
				setVal('raw', 'u'..raw)
			end
		end
	end

	setDefVal('damageAmount', 0)
	setDefVal('damageDices', 0)
	setDefVal('damageSides', 0)

	local damageAmount = tonumber(getVal('damageAmount', 1)) or 0
	local damageDices = tonumber(getVal('damageDices', 1)) or 0
	local damageSides = tonumber(getVal('damageSides', 1)) or 0

	setDefVal('minDmg', damageAmount + damageDices)
	setDefVal('maxDmg', damageAmount + damageDices * damageSides)
end

local INVENTORY_SPELL_PATH = [[Header\Unit.page\Unit.struct\heroInventorySpell]]
local LOCUST_SPELL_PATH = [[Header\Misc.page\DummyUnit.struct\locustSpell]]

t.createFunc = function(t)
	addToEnv(t)

	local raw = getVal('raw', 1)

	if (raw == nil) then
		return
	end

	local widget = createWidget('unit', raw, nil, getVal('profileIdent', 1), path)

	if getVal('standardScale', 1) then
		local scaleFactor = 1. / getVal('standardScale', 1)

		local t = {}

		t[0] = 'selScale'
		t[1] = 'impactZ'
		t[2] = 'outpactX'
		t[3] = 'outpactY'
		t[4] = 'outpactZ'
		t[5] = 'shadowWidth'
		t[6] = 'shadowHeight'
		t[7] = 'collisionSize'

		for k, v in pairs(t) do
			if getVal(v, 1) then
				setVal(v, 1, getVal(v, 1) * scaleFactor)
			end
		end
	end

	local scale = getVal('scale', 1)

	if (scale == nil) then
		scale = 1.
	end

	local classes = getVal('classes', 1)

	if classes then
		classes = totable(classes)
	else
		classes = {}
	end

	--constant
	widget:set('ucam', 0)
	widget:set('ucar', 1) --cargo
	widget:set('udea', string.char(3))
	widget:set('ufle', 0)
	widget:set('uine', 1)
	widget:set('upri', 0)
	widget:set('util', '*')
	widget:set('uwu1', 1)

	local abilities

	local function addAbility(value)
		if abilities then
			abilities = abilities..','..value
		else
			abilities = value
		end
	end

	if dummy then
		if (tableContains(classes, 'NOT_LOCUST') ~= true) then
			addAbility(getObjVal(pathToFullPath(nil, LOCUST_SPELL_PATH, 'wc3spell'), 'raw')[1])
		end
		if tableContains(classes, 'WARPER') then
			addAbility(getObjVal(pathToFullPath(nil, 'Warp', 'wc3spell'), 'raw')[1])
		end

		if (getVal('name', 1) == nil) then
			widget:set('unam', 'Dummy '..nilToString(raw, 'NONE'))
		end
	else
		widget:set('unam', getVal('name', 1), '')
	end

	--classification

	local t = {}

	t['DEFENDER'] = 'human'
	t['ATTACKER'] = 'creeps'
	t['OTHER'] = 'other'

	widget:set('uhos', 0)
	widget:set('urac', t[(getVal('team', 1))], 'unknown')

	local utypT = {}

	if tableContains(classes, 'WORKER') then
    		table.insert(utypT, 'peon')
	end

	widget:set('utyp', table.concat(utypT, ','))

	--model
	widget:set('uaap', getVal('modelAttachMods', 1), '')
	widget:set('ualp', getVal('modelAttachPts', 1), '')
	widget:set('uani', getVal('modelAnims', 1), '')
	widget:set('ubpr', getVal('modelBones', 1), '')
	widget:set('umdl', getVal('model', 1), '')
	
	--modelMods
	widget:set('uept', getVal('elevPts', 1), 0)
	widget:set('uerd', getVal('elevRad', 1), 0)
	widget:set('umxr', getVal('maxRoll', 1), 0)
	widget:set('umxp', getVal('maxPitch', 1), 0)
	widget:set('usca', getVal('scale', 1), 1)
	if getVal('selScale', 1) then
		setVal('selScale', getVal('selScale', 1) * 0.85)
	end
	--widget:set('ussc', nilTo(getVal('selScale', 1), 0) * scale, 0)
	widget:set('ussc', nilTo(getVal('collisionSize', 1), 0) * scale * 3 / 100, 0)
	widget:set('uclr', getVal('vertexColorRed', 1), 255)
	widget:set('uclg', getVal('vertexColorGreen', 1), 255)
	widget:set('uclb', getVal('vertexColorBlue', 1), 255)
	
	--missilePoints
	widget:set('uimz', nilTo(getVal('impactZ', 1), 0) * scale, 0)
	widget:set('ulpx', nilTo(getVal('outpactX', 1), 0) * scale, 0)
	widget:set('ulpy', nilTo(getVal('outpactY', 1), 0) * scale, 0)
	widget:set('ulpz', nilTo(getVal('outpactZ', 1), 0) * scale, 0)

	--shadow
	widget:set('ushw', nilTo(getVal('shadowWidth', 1), 0) * scale, 0)
	widget:set('ushh', nilTo(getVal('shadowHeight', 1), 0) * scale, 0)
	widget:set('ushx', getVal('shadowOffsetX', 1), 0)
	widget:set('ushy', getVal('shadowOffsetY', 1), 0)
	if (getVal('shadowPath', 1) == 'NONE') then
		widget:set('ushb', '')
		widget:set('ushu', '')
	elseif (getVal('shadowPath', 1) == 'NORMAL') then
		widget:set('ushb', '')
		widget:set('ushu', 'Shadow')
	elseif (getVal('shadowPath', 1) == 'FLY') then
		widget:set('ushb', '')
		widget:set('ushu', 'ShadowFlyer')
	else
		widget:set('ushb', getVal('shadowPath', 1), '')
		widget:set('ushu', '')
	end
	
	--misc
	widget:set('uico', getVal('icon', 1), '')
	--widget:set('usnd', getVal('soundset', 1), '')
	widget:set('utip', getVal('tooltip', 1), '')
	widget:set('utub', getVal('uberTooltip', 1), '')

	--movement
	local t = {}

	t['NONE'] = ''
	t['FOOT'] = 'foot'
	t['HORSE'] = 'horse'
	t['FLY'] = 'fly'
	t['HOVER'] = 'hover'
	t['FLOAT'] = 'float'
	t['AMPHIBIOUS'] = 'amph'

	if getVal('moveType', 1) then
		widget:set('umvt', t[(getVal('moveType', 1))], '')
	else
		widget:set('umvt', '')
	end

	if (getVal('moveSpeed', 1) and (getVal('moveSpeed', 1) > 0)) then
		widget:set('umvs', getVal('moveSpeed', 1))
		widget:set('uprw', 60)
	elseif dummy then
		widget:set('umvs', -1)
	else
		widget:set('umvs', 0)
	end
	widget:set('umvr', getVal('turnRate', 1), 0)
	widget:set('umvh', getVal('height', 1), 0)
	widget:set('umvf', getVal('heightMin', 1), 0)
	widget:set('uwal', getVal('animWalk', 1), 0)
	widget:set('urun', getVal('animRun', 1), 0)
	widget:set('uori', getVal('moveInterp', 1), 0)

	--balance
	if getVal('armorAmount', 1) then
		widget:set('udef', math.floor(getVal('armorAmount', 1)), 0)
	else
		widget:set('udef', 0)
	end
	widget:set('uarm', getVal('armorSound', 1), '')

	local t = {}

	t['LIGHT'] = 'small'
	t['MEDIUM'] = 'medium'
	t['LARGE'] = 'large'
	t['FORT'] = 'fort'
	t['HERO'] = 'hero'
	t['UNARMORED'] = 'none'
	t['DIVINE'] = 'divine'

	if getVal('armorType', 1) then
		widget:set('udty', t[(getVal('armorType', 1))], 'divine')
	else
		widget:set('udty', 'divine')
	end

	if (getVal('life', 1) == 'INFINITE') then
		widget:set('uhpm', 150000)
	else
		widget:set('uhpm', getVal('life', 1), 0)
	end
	widget:set('umpm', getVal('mana', 1), 0)

	widget:set('usid', getVal('sightRange', 1), 0)
	widget:set('usin', getVal('sightRange', 1), 0)
	--widget:set('usin', getVal('sightRangeNight', 1), 0)
	
	--attack
	widget:set('ua1c', getVal('attackCooldown', 1), 0)
	widget:set('ua1g', getVal('attackTargetFlags', 1), '')
	if getVal('attackRange', 1) then
		setVal('attackRange', getVal('attackRange', 1) * 1.2)
	end
	widget:set('ua1r', getVal('attackRange', 1), 0)

	if (getVal('attackType', 1) == 'NORMAL') then
		widget:set('ua1w', 'normal')
	elseif (getVal('attackType', 1) == 'MISSILE') then
		widget:set('ua1w', 'missile')
	elseif (getVal('attackType', 1) == 'HOMING_MISSILE') then
		widget:set('ua1w', 'missile')
		widget:set('umh1', 1)
	elseif (getVal('attackType', 1) == 'ARTILLERY') then
		widget:set('ua1f', 0.)
		widget:set('ua1h', 0.)
		widget:set('ua1p', 'invulnerable')
		widget:set('ua1q', 1000.)
		widget:set('ua1w', 'artillery')
		widget:set('uqd1', -1)
	end

	widget:set('uacq', getVal('attackRangeAcq', 1), 0)
	widget:set('urb1', getVal('attackRangeBuffer', 1), 0)
	widget:set('uaen', string.char(1))
	widget:set('ubs1', getVal('attackWaitAfter', 1), 0)
	widget:set('udp1', getVal('attackWaitBefore', 1), 0)
	widget:set('ucs1', getVal('attackSound', 1), '')
	widget:set('utc1', 1)
	widget:set('uamn', getVal('attackMinRange', 1), 0)
	
	--attackMissile
	widget:set('ua1m', getVal('attackMissileModel', 1), '')
	widget:set('ua1z', getVal('attackMissileSpeed', 1), 0)
	widget:set('uma1', getVal('attackMissileArc', 1), 0)
	
	--anim
	widget:set('uble', getVal('animBlend', 1), 0)
	widget:set('ucbs', getVal('animCastWaitAfter', 1), 0)
	widget:set('ucpt', getVal('animCastWaitBefore', 1), 0)

	if classes then
		if tableContains(classes, 'STRUCTURE') then
			isStructure = true
			widget:set('ubdg', 1)
		elseif (getVal('structure', 1) == true) then
			widget:set('ubdg', 1)
		end
		if tableContains(classes, 'UPGRADED') then
	    		isUpgrade = true
		end
	end

	--damage
	local t = {}
	
	t['NORMAL'] = 'normal'
	t['PIERCE'] = 'pierce'
	t['SIEGE'] = 'siege'
	t['MAGIC'] = 'magic'
	t['CHAOS'] = 'chaos'
	t['HERO'] = 'hero'
	t['SPELLS'] = 'spells'
	
	if getVal('damageType', 1) then
		widget:set('ua1t', t[(getVal('damageType', 1))], 'spells')
	else
		widget:set('ua1t', 'spells')
	end
	
	widget:set('ua1b', getVal('damageAmount', 1), 0)
	widget:set('ua1d', getVal('damageDices', 1), 0)
	widget:set('ua1s', getVal('damageSides', 1), 0)
	
	--balanceMisc
	if getVal('collisionSize', 1) then
		--setVal('collisionSize', getVal('collisionSize', 1) * 0.85)
	end
	--widget:set('ucol', nilTo(getVal('collisionSize', 1), 0) * scale, 0)
	widget:set('ucol', 16, 0)
	widget:set('utar', getVal('combatFlags', 1), '')
	widget:set('udtm', getVal('deathTime', 1), 0)
	widget:set('ubba', getVal('gold', 1), 0)

	--hero
	if (getVal('hero', 1) == true) then
		--constant
		local inventoryObj = pathToFullPath(nil, INVENTORY_SPELL_PATH, 'wc3spell')

		if inventoryObj then
			addAbility(getObjVal(inventoryObj, 'raw', 1))
		end
		widget:set('uhhd', '1')
		widget:set('uhab', 'AHS0,AHS1,AHS2,AHS3,AHS4')

		--misc
		local t = {}

		t['AGILITY'] = 'AGI'
		t['INTELLIGENCE'] = 'INT'
		t['STRENGTH'] = 'STR'

		if (getVal('heroAttribute', 1) and t[(getVal('heroAttribute', 1))]) then
			widget:set('upra', t[(getVal('heroAttribute', 1))])
		else
			widget:set('upra', '_')
		end
		widget:set('upro', getVal('heroNames', 1), '')
		widget:set('upru', 1)
	end

	--structure
	if (getVal('structure', 1) == true) then
		widget:set('upat', getVal('structurePathTex', 1), '')
		widget:set('uubs', getVal('structureUbersplat', 1), '')
	end
	if getVal('structureSoldItems', 1) then
		addAbility(getObjVal(pathToFullPath(nil, [[Header\Unit.page\Unit.struct\purchaseItem]], 'wc3spell'), 'raw')[1])
		addAbility(getObjVal(pathToFullPath(nil, [[Header\Unit.page\Unit.struct\selectHero]], 'wc3spell'), 'raw')[1])
		widget:set('usei', objPathsToRaw(path, totable(getVal('structureSoldItems', 1)), 'wc3item'), '')
	end
	if getVal('structureUpgradeTo', 1) then
		widget:set('uupt', objPathsToRaw(path, totable(getVal('structureUpgradeTo', 1)), 'wc3unit'), '')
	end

	widget:set('uabi', abilities)

	widget:doSpecials(getVal('specialsTrue'), getVal('specials'))
end

t.jassIniter = [[call UnitType.AddInit(%s)]]

t.jassFunc = function(t, jStream)
	addToEnv(t)

	local scaleFactor

	if getVal('standardScale', 1) then
		scaleFactor = 1. / getVal('standardScale', 1)
	else
		scaleFactor = 1.
	end

	local raw = getVal('raw', 1)
	local var = getVal('jassVar', 1)

	local varExpr = addVar(var, 'UnitType', getVal('jassVarIndex', 1))

	--base
	if raw then
		writeLine([[set %s = UnitType.Create('%s')]], {varExpr, raw})
	else
		writeLine([[set %s = UnitType.CreateHidden()]], {varExpr})
	end

	--classification
	local jassClasses = {}

	local function addClass(val)
		jassClasses[val] = val
	end

	if (getVal('hero', 1) == true) then
		local inventoryPath = pathToFullPath(nil, INVENTORY_SPELL_PATH, 'wc3spell')

		if inventoryPath then
			writeLine([[call %s.Abilities.Add('%s')]], {varExpr, getObjVal(inventoryPath, 'raw', 1)})
		end
		addClass('hero')
	end
	if (getVal('structure', 1) == true) then
		addClass('structure')
	end

	local t = totable(getVal('classes', 1))

	if t then
		for k, v in pairs(t) do
			addClass(v)
		end
	end

	local t = string.split(getVal('combatFlags', 1), ',')

	if t then
		for k, v in pairs(t) do
			addClass(v)
		end
	end

	if jassClasses then
		local t = {}

		t['air'] = 'AIR'
		t['ground'] = 'GROUND'
		t['hero'] = 'HERO'
		t['mechanical'] = 'MECHANICAL'
		t['structure'] = 'STRUCTURE'

		for k, v in pairs(jassClasses) do
			if t[v] then
				writeLine([[call %s.Classes.Add(UnitClass.%s)]], {varExpr, t[v]})
			end
		end
	end

	--modelMods
	if getVal('scale', 1) then
		writeLine([[call %s.Scale.Set(%s)]], {varExpr, getVal('scale', 1)})
	end

	local colorMod
	local red
	local green
	local blue
	local alpha

	if getVal('vertexColorRed', 1) then
		colorMod = true
		red = getVal('vertexColorRed', 1)
	end
	if getVal('vertexColorGreen', 1) then
		colorMod = true
		green = getVal('vertexColorGreen', 1)
	end
	if getVal('vertexColorBlue', 1) then
		colorMod = true
		blue = getVal('vertexColorBlue', 1)
	end
	if getVal('vertexColorAlpha', 1) then
		colorMod = true
		alpha = getVal('vertexColorAlpha', 1)
	end

	if colorMod then
		if (red == nil) then
			red = 255
		end
		if (green == nil) then
			green = 255
		end
		if (blue == nil) then
			blue = 255
		end
		if (alpha == nil) then
			alpha = 255
		end

		writeLine([[call %s.VertexColor.Set(%s, %s, %s, %s)]], {varExpr, red, green, blue, alpha})
	end

	--missilePoints
	if getVal('impactZ', 1) then
		writeLine([[call %s.Impact.Z.Set(%s)]], {varExpr, (getVal('impactZ', 1) * scaleFactor)})
	end
	if getVal('outpactZ', 1) then
		writeLine([[call %s.Outpact.Z.Set(%s)]], {varExpr, (getVal('outpactZ', 1) * scaleFactor)})
	end

	--misc
	if getVal('attachments', 1) then
		local c = 1
		local t = totable(getVal('attachments', 1))

		while (t[c] and t[c + 1] and t[c + 2]) do
			writeLine([[call %s.Attachments.Add(%j, AttachPoint.%s, EffectLevel.%s)]], {varExpr, toJassValue(t[c]), t[c + 1], t[c + 2]})

			c = c + 3
		end
	end
	if getVal('blood', 1) then
		writeLine([[call %s.Blood.Set(%s)]], {varExpr, toJassValue(getVal('blood', 1))})
	end
	if getVal('bloodExplosion', 1) then
		writeLine([[call %s.BloodExplosion.Set(%s)]], {varExpr, toJassValue(getVal('bloodExplosion', 1))})
	end

	--movement
	if getVal('moveSpeed', 1) then
		writeLine([[call %s.Speed.Set(%s)]], {varExpr, getVal('moveSpeed', 1)})
	end

	--balance
	if getVal('armorAmount', 1) then
		writeLine([[call %s.Armor.Set(%s)]], {varExpr, getVal('armorAmount', 1)})
	end
	if getVal('armorType', 1) then
		writeLine([[call %s.Armor.Type.Set(Attack.ARMOR_TYPE_%s)]], {varExpr, getVal('armorType', 1)})
	end
	if getVal('life', 1) then
		if (getVal('life', 1) == 'INFINITE') then
			writeLine([[call %s.Life.Set(%s)]], {varExpr, [[UNIT_TYPE.Life.INFINITE]]})
			writeLine([[call %s.Life.SetBJ(%s)]], {varExpr, [[UNIT_TYPE.Life.INFINITE]]})
		else
			writeLine([[call %s.Life.Set(%s)]], {varExpr, getVal('life', 1)})
			writeLine([[call %s.Life.SetBJ(%s)]], {varExpr, getVal('life', 1)})
		end
	end
	if getVal('lifeRegen', 1) then
		writeLine([[call %s.LifeRegeneration.Set(%s)]], {varExpr, (getVal('lifeRegen', 1) / 5)})
	end

	if getVal('mana', 1) then
		writeLine([[call %s.Mana.Set(]]..getVal('mana', 1)..[[)]], {varExpr})
		writeLine([[call %s.Mana.SetBJ(]]..getVal('mana', 1)..[[)]], {varExpr})
	end
	if getVal('manaRegen', 1) then
		writeLine([[call %s.ManaRegeneration.Set(]]..(getVal('manaRegen', 1) / 5)..[[)]], {varExpr})
	end
	if getVal('sightRange', 1) then
		writeLine([[call %s.SightRange.Set(%s)]], {varExpr, getVal('sightRange', 1)})
		writeLine([[call %s.SightRange.SetBJ(%s)]], {varExpr, getVal('sightRange', 1)})
	end
	if getVal('spellPower', 1) then
		writeLine([[call %s.SpellPower.Set(%s)]], {varExpr, getVal('spellPower', 1)})
	end

	--attack
	if getVal('attackType', 1) then
		writeLine([[call %s.Attack.Set(Attack.%s)]], {varExpr, getVal('attackType', 1)})
	end
	if getVal('attackRange', 1) then
		writeLine([[call %s.Attack.Range.Set(%s)]], {varExpr, getVal('attackRange', 1)})
	end
	if getVal('attackCooldown', 1) then
		writeLine([[call %s.Attack.Speed.SetByCooldown(%s)]], {varExpr, getVal('attackCooldown', 1)})
	end
	if getVal('attackWaitBefore', 1) then
		writeLine([[call %s.Damage.Delay.Set(%s)]], {varExpr, getVal('attackWaitBefore', 1)})
	end

	--attackMissile
	if getVal('attackMissileSpeed', 1) then
		writeLine([[call %s.Attack.Missile.Speed.Set(%s)]], {varExpr, getVal('attackMissileSpeed', 1)})
	end

	--attackSplash
	if getVal('attackSplash', 1) then
		local c = 1
		local t = totable(getVal('attackSplash', 1))

		while t[c] and t[c + 1] do
			writeLine([[call %s.Attack.Splash.Add(%s, %s)]], {varExpr, t[c], t[c + 1]})

			c = c + 2
		end

		if getVal('attackSplashTargetFlags', 1) then
			local t = totable(getVal('attackSplashTargetFlags', 1))

			if t then
				for k,v in pairs(t) do
					writeLine([[call %s.Attack.Splash.TargetFlag.Add(TargetFlag.%s)]], {varExpr, v})
				end
			end
		end
	end

	--damage
	if getVal('damageAmount', 1) then
		writeLine([[call %s.Damage.Set(%s)]], {varExpr, getVal('damageAmount', 1)})
		writeLine([[call %s.Damage.SetBJ(%s)]], {varExpr, getVal('damageAmount', 1)})
	end
	if getVal('damageDices', 1) then
		writeLine([[call %s.Damage.Dices.Set(%s)]], {varExpr, getVal('damageDices', 1)})
	end
	if getVal('damageSides', 1) then
		writeLine([[call %s.Damage.Sides.Set(%s)]], {varExpr, getVal('damageSides', 1)})
	end
	if getVal('damageType', 1) then
		writeLine([[call %s.Damage.Type.Set(Attack.DMG_TYPE_%s)]], {varExpr, getVal('damageType', 1)})
	end

	--balanceMisc
	if getVal('collisionSize', 1) then
		writeLine([[call %s.CollisionSize.Set(%s)]], {varExpr, (getVal('collisionSize', 1) * scaleFactor)})
	end
	if getVal('gold', 1) then
		writeLine([[call %s.Drop.Supply.Set(%s)]], {varExpr, getVal('gold', 1)})
	end
	if getVal('exp', 1) then
		writeLine([[call %s.Drop.Exp.Set(%s)]], {varExpr, getVal('exp', 1)})
	end

	--hero
	if getVal('heroAbilities', 1) then
		local t = totable(getVal('heroAbilities', 1))

		for k, v in pairs(t) do
			v = v:dequote()

			if getObj(v) then
				if v:find('{', 1, true) then
					local val = v:sub(1, v:find('{', 1, true) - 1)
					local level = v:sub(v:find('{', 1, true) + 1, v:len())

					level = level:sub(1, level:find('}', 1, true) - 1)

					writeLine([[call %s.Abilities.Hero.AddWithLevel(%s, %i)]], {varExpr, toJassPath(path, val, 'wc3spell'), level})
				else
					writeLine([[call %s.Abilities.Hero.Add(%s)]], {varExpr, toJassPath(path, v, 'wc3spell')})
				end
			end
		end
	end
	if getVal('heroAgi', 1) then
		writeLine([[call %s.Hero.Agility.Set(%s)]], {varExpr, getVal('heroAgi', 1)})
	end
	if getVal('heroAgiUp', 1) then
		writeLine([[call %s.Hero.Agility.PerLevel.Set(%s)]], {varExpr, getVal('heroAgiUp', 1)})
	end
	if getVal('heroArmorUp', 1) then
		writeLine([[call %s.Hero.ArmorPerLevel.Set(%s)]], {varExpr, getVal('heroArmorUp', 1)})
	end
	if getVal('heroInt', 1) then
		writeLine([[call %s.Hero.Intelligence.Set(%s)]], {varExpr, getVal('heroInt', 1)})
	end
	if getVal('heroIntUp', 1) then
		writeLine([[call %s.Hero.Intelligence.PerLevel.Set(%s)]], {varExpr, getVal('heroIntUp', 1)})
	end
	if getVal('heroStr', 1) then
		writeLine([[call %s.Hero.Strength.Set(%s)]], {varExpr, getVal('heroStr', 1)})
	end
	if getVal('heroStrUp', 1) then
		writeLine([[call %s.Hero.Strength.PerLevel.Set(%s)]], {varExpr, getVal('heroStrUp', 1)})
	end

	if getVal('abilities', 1) then
		local t = totable(getVal('abilities', 1))

		for k, v in pairs(t) do
			v = v:dequote()

			if v:find('{', 1, true) then
				local val = v:sub(1, v:find('{', 1, true) - 1)
				local level = v:sub(v:find('{', 1, true) + 1, v:len())

				level = level:sub(1, level:find('}', 1, true) - 1)

				writeLine([[call %s.Abilities.AddWithLevel(%s, %i)]], {varExpr, toJassPath(path, val, 'wc3spell'), level})
			else
print('ability', v)
				writeLine([[call %s.Abilities.Add(%s)]], {varExpr, toJassPath(path, v, 'wc3spell')})
			end
		end
	end
end

t.jassFuncDummy = function(t, jStream)
	addToEnv(t)

	addVar(getVal('jassVar', 1)..'Id', 'integer', getVal('jassVarIndex', 1))
end

t.tagsFunc = function(t, obj)
	addToEnv(t)

	if (getVal('standardScale', 1) == nil) then
		setVal('standardScale', 1, 1)
	end
	if (getVal('tooltip', 1) == nil) then
		if getVal('name', 1) then
			if getVal('structure', 1) then
				if getVal('classes', 1) then
					local t = totable(getVal('classes', 1))

					if (t and tableContains(t, 'UPGRADED')) then
						setVal('tooltip', 1, 'Upgrade to ')
					end
				end

				if (getVal('tooltip', 1) == nil) then
					setVal('tooltip', 1, 'Build ')
				end
			else
				setVal('tooltip', 1, 'Train ')
			end

			if getVal('tooltip', 1) then
				setVal('tooltip', 1, getVal('tooltip', 1)..getVal('name', 1))
			end
		end
	end

	if getVal('tooltip', 1) then
		setVal('tooltip', 1, replaceTags('tooltip', getVal('tooltip', 1), 1, true))
	end
	if getVal('uberTooltip', 1) then
		setVal('uberTooltip', 1, replaceTags('uberTooltip', getVal('uberTooltip', 1), 1, true))
	end
end

return t