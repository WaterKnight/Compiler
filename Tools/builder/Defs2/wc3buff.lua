local t = {}

t.defFunc = function(t)
	addToEnv(t)

	local fileName = getFileName(path, true)

	setDefVal('jassVar', toVar(fileName))
	setDefVal('jassVarIndex', toVarIndex(fileName))

	if (getVal('raw', 1) and (getVal('raw', 1):len() == 3)) then
		if dummy then
			setVal('raw', 'b'..tostring(getVal('raw', 1)))
		else
			setVal('raw', 'B'..tostring(getVal('raw', 1)))
		end
	end
end

t.createFunc = function(t)
	addToEnv(t)

	local raw = getVal('raw', 1)

	if (raw == nil) then
		return
	end

	local widget = createWidget('buff', raw, nil, getVal('profileIdent', 1), path)

	widget:setTrue('code', 'Basl')

	widget:set('fart', getVal('icon', 1), '')
	widget:set('fnsf', '')
	widget:set('ftat', '')
	widget:set('fube', getVal('uberTooltip', 1), '')

	local tooltip = getVal('tooltip', 1)

	if (tooltip == nil) then
		if getVal('name', 1) then
			tooltip = getVal('name', 1)
		end
	end

	if getVal('positive', 1) then
		if tooltip then
			widget:set('ftip', string.format('|cff00ff00%s', tooltip), '')
		end
	else
	    widget:set('ftip', tooltip, '')
	end

	widget:doSpecials(getVal('specialsTrue'), getVal('specials'))

	if (dummy ~= true) then
		if raw then
			local widget = createWidget('ability', 'b'..raw:sub(2, 4), nil, nil, path)

			widget:setTrue('code', 'Aasl')

			widget:setLv('aare', 1, 0)
			for level = 1, levelsAmount, 1 do
			    widget:setLv('abuf', level, raw)
			    widget:setLv('atar', level, 'invulnerable,self,vulnerable')
			    widget:setLv('Slo1', level, 0)
			end
			widget:set('alev', levelsAmount)
			widget:set('anam', getVal('name', 1), string.format('defaultName(buff) %s', nilToString(raw, 'NONE')))
			widget:set('ansf', '(Buffer)')
			widget:set('arac', 'other')
		end
	end
end

t.jassType = 'Buff'
t.jassTypeDummy = 'integer'

t.jassIniter = [[call Buff.AddInit(%s)]]

t.jassFunc = function(t)
	addToEnv(t)

	if (name == nil) then
		name = 'defaultName(buff)'

		if raw then
			name = name..' '..raw
		end
	end

	local varExpr = addVar(getVal('jassVar', 1), 'Buff', getVal('jassVarIndex', 1))

	if raw then
		local bufferRaw = 'b'..raw:sub(2, 4)

		writeLine([[set %s = Buff.Create('%s', %s, '%s')]], {varExpr, raw, toJassValue(name), bufferRaw})
        else
		writeLine([[set %s = Buff.CreateHidden(thistype.NAME + %s)]], {varExpr, toJassValue(' ('..fileName..')')})
	end

	if getVal('positive', 1) then
		writeLine([[call %s.SetPositive(%s)]], {varExpr, boolToString(getVal('positive', 1))})
	end

	local t = totable(getVal('lostOn', 1))

	if t then
		if tableContains(t, 'death') then
			writeLine('call %s.SetLostOnDeath(true)', {varExpr})
		end

		if tableContains(t, 'dispel') then
			writeLine('call %s.SetLostOnDispel(true)', {varExpr})
		end
	end

	if getVal('icon', 1) then
        	writeLine([[call %s.SetIcon(%s)]], {varExpr, toJassValue(getVal('icon', 1))})
        end

        local sfxCount = 0
        local sfxPaths = {}
       	local sfxAttachPts = {}
        local sfxLevels = {}

	local t = totable(getVal('sfxPath', 1))

	if t then
	        for k, v in pairs(t) do
	        	sfxCount = sfxCount + 1

	        	sfxPaths[sfxCount] = v
	        end
        end

	sfxCount = 0
	t = totable(getVal('sfxAttachPt', 1))

	if t then
		for k, v in pairs(t) do
			sfxCount = sfxCount + 1

			sfxAttachPts[sfxCount] = v
		end
	end

	sfxCount = 0
	t = totable(getVal('sfxLevel', 1))

	if t then
		for k, v in pairs(t) do
			sfxCount = sfxCount + 1

			sfxLevels[sfxCount] = v
		end
	end

	for i = 1, sfxCount, 1 do
		if sfxPaths[i] and sfxAttachPts[i] and sfxLevels[i] then
			writeLine([[call %s.TargetEffects.Add(%s, %s, %s)]], {varExpr, toJassValue(sfxPaths[i]), sfxAttachPts[i], sfxLevels[i]})
		end
	end

	local t = totable(getVal('sfxSoundLoop', 1))

	if t then
		for i = 1, #t, 1 do
			local val = toJassName(getObjVal(pathToFullPath(path, t[i], 'wc3sound'), 'jassVar', 1))

			writeLine([[call %s.LoopSounds.Add(%s)]], {varExpr, val})
		end
	end

	if getVal('unitMod') then
		local stateTable = {}

		stateTable['scaleBonus'] = [[UNIT.Scale.Bonus.STATE]]

		local t = {}
		stateTable['scaleBonusTimed'] = t
			t.jassPath = [[UNIT.Scale.Timed.STATE]]
			t.jassArgs = {{key = [[UNIT.Scale.Timed.STATE_SCALE_KEY]], typeName = [[Real]]}, {key = [[UNIT.Scale.Timed.STATE_DURATION_KEY]], typeName = [[Real]]}}
			t.type = 'CustomMod'

		local t = {}
		stateTable['scaleBonusTimed'] = t
			t.jassLine = [[UNIT.Scale.Timed.CreateMod(%s)]]

		local t = {}
		stateTable['vertexColorBonus'] = t
			t.jassLine = [[UNIT.VertexColor.CreateMod(%s)]]

		local t = {}
		stateTable['vertexColorBonusTimed'] = t
			t.jassLine = [[UNIT.VertexColor.Timed.CreateMod(%s)]]

		stateTable['maxLifeBonus'] = [[UNIT.MaxLife.Bonus.STATE]]
		stateTable['maxManaBonus'] = [[UNIT.MaxMana.Bonus.STATE]]

		stateTable['lifeRegenBonus'] = [[UNIT.LifeRegeneration.Bonus.STATE]]
		stateTable['lifeRegenBonusRel'] = [[UNIT.LifeRegeneration.Relative.STATE]]
		stateTable['lifeRegenDisable'] = [[UNIT.LifeRegeneration.Disablement.STATE]]
		stateTable['manaRegenBonus'] = [[UNIT.ManaRegeneration.Bonus.STATE]]
		stateTable['manaRegenBonusRel'] = [[UNIT.ManaRegeneration.Relative.STATE]]
		stateTable['manaRegenDisable'] = [[UNIT.ManaRegeneration.Disablement.STATE]]
		stateTable['staminaRegenBonus'] = [[UNIT.StaminaRegeneration.Bonus.STATE]]

		stateTable['attackSpeedBonus'] = [[UNIT.Attack.Speed.BonusA.STATE]]
		stateTable['moveSpeedBonus'] = [[UNIT.Movement.Speed.BonusA.STATE]]
		stateTable['moveSpeedBonusRel'] = [[UNIT.Movement.Speed.RelativeA.STATE]]

		stateTable['critBonus'] = [[UNIT.CriticalChance.Bonus.STATE]]
		stateTable['evasionBonus'] = [[UNIT.EvasionChance.Bonus.STATE]]
		stateTable['evasionDefBonus'] = [[UNIT.EvasionChanceDefense.Bonus.STATE]]
		stateTable['missBonus'] = [[UNIT.EvasionChanceDefense.Bonus.STATE]]

		stateTable['dmgBonus'] = [[UNIT.Damage.Bonus.STATE]]
		stateTable['dmgBonusRel'] = [[UNIT.Damage.Relative.STATE]]
		stateTable['armorBonus'] = [[UNIT.Armor.Bonus.STATE]]
		stateTable['armorSpell'] = [[UNIT.Armor.Spell.STATE]]

		stateTable['lifeLeech'] = [[UNIT.LifeLeech.STATE]]
		stateTable['manaLeech'] = [[UNIT.ManaLeech.STATE]]

		stateTable['spellPowerBonus'] = [[UNIT.SpellPower.Bonus.STATE]]
		stateTable['spellPowerBonusRel'] = [[UNIT.SpellPower.Relative.STATE]]

		stateTable['healAbilityBonusRel'] = [[UNIT.HealAbility.BONUS_STATE]]
		stateTable['spellVampBonus'] = [[UNIT.SpellVamp.Bonus.STATE]]

		stateTable['resistanceBonus'] = [[UNIT.Armor.Resistance.STATE]]

		stateTable['attackDisable'] = [[UNIT.Attack.DISABLE_STATE]]
		stateTable['ghost'] = [[UNIT.Ghost.STATE]]
		stateTable['invul'] = [[UNIT.Invulnerability.STATE]]
		stateTable['magicImmunity'] = [[UNIT.MagicImmunity.STATE]]
		stateTable['moveDisable'] = [[UNIT.Movement.DISABLE_STATE]]
		stateTable['stun'] = [[UNIT.Stun.STATE]]

		stateTable['vigorBonusRel'] = [[UNIT.Strength.Relative.STATE]]
		stateTable['focusBonusRel'] = [[UNIT.Agility.Relative.STATE]]
		stateTable['animusBonusRel'] = [[UNIT.Intelligence.Relative.STATE]]

		for level = 1, levelsAmount, 1 do
			if getVal('unitMod', level) then
				local mods = totable(getVal('unitMod', level))
				local vals = totable(getVal('unitModVal', level))

				if mods and mods[1] and (mods[1] ~= '') then
					writeLine([[set %s = UnitModSet.Create()]], {'UnitModSet.TEMP'})

					for pos, mod in pairs(mods) do
						local state = stateTable[mod]
						local val = vals[pos]

						if (type(val) == 'string') then
							if ((val:sub(1, 1) == '{') and (val:sub(val:len(), val:len()) == '}')) then
								val = val:sub(2, val:len() - 1):split(',')
							end
						end

						if state then
							if (type(val) == 'table') then
								if (state.type == 'CustomMod') then
									writeLine([[call %s.CustomMods.Add(%s)]], {'UnitModSet.TEMP', state.jassPath})
									for k, v in pairs(val) do
										writeLine([[call %s.CustomMods.Add%s(%s, %s, %s)]], {'UnitModSet.TEMP', state.jassArgs[k].typeName, state.jassPath, state.jassArgs[k].key, v})
									end
								else
									writeLine([[call %s.Mods.Add(%s)]], {'UnitModSet.TEMP', string.format(state.jassLine, table.concat(val, ','))})
								end
							elseif tonumber(val) then
								writeLine([[call %s.RealMods.Add(%s, %s)]], {'UnitModSet.TEMP', state, val})
							elseif ((tostring(val) == 'true') or (tostring(val) == 'false')) then
								writeLine([[call %s.BoolMods.Add(%s, %s)]], {'UnitModSet.TEMP', state, 'true'})
							else
								log:write(path..': unitMod type unrecognized ('..mod..', '..tostring(val)..')')
							end
						end
					end

					writeLine([[call %s.UnitModSets.Add(%i, %s)]], {varExpr, level, [[UnitModSet.TEMP]]})
				end
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

	for level = 1, levelsAmount, 1 do
		if (getVal('tooltip', level) == nil) then
			if getVal('name', level) then
				setVal('tooltip', level,  getVal('name', level))
			end
		end

		if getVal('tooltip', level) then
			setVal('tooltip', level, replaceTags('tooltip', getVal('tooltip', level), level, true))
		end
		if getVal('uberTooltip', level) then
			setVal('uberTooltip', level, replaceTags('uberTooltip', getVal('uberTooltip', level), level, true))
		end
	end
end

return t