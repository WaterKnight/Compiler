local t = {}

t.defFunc = function(t)
	addToEnv(t)

	local fileName = getFileName(sheet.path, true)

	setDefVal('jassVar', toVar(fileName))
	setDefVal('jassVarIndex', toVarIndex(fileName))

	if (getVal('raw') and (getVal('raw'):len() == 3)) then
		if dummy then
			setVal('raw', 'b'..tostring(getVal('raw')))
		else
			setVal('raw', 'B'..tostring(getVal('raw')))
		end
	end
end

t.createFunc = function(t)
	addToEnv(t)

	local raw = getVal('raw')

	if (raw == nil) then
		return
	end

	local buff = createBuff(raw, sheet.path, getVal('profileIdent'))

	buff.slk:setCode('Basl')

	buff.mod:setIcon(getVal('icon'))

	buff.mod:setUberTooltip(getVal('uberTooltip'))

	local tooltip = getVal('tooltip')

	if (tooltip == nil) then
		if (getVal('name') ~= nil) then
			tooltip = getVal('name')
		end
	end

	if (getVal('positive') ~= nil) then
		if tooltip then
			tooltip = string.format('|cff00ff00%s', tooltip)
		end
	end

	buff.mod:setTooltip(tooltip)

	buff:doSpecials(getVal('specialsTrue'), getVal('specials'))

	if (dummy ~= true) then
		if raw then
			local ability = createAbility('b'..raw:sub(2, 4), sheet.path)

			ability.slk:setCode('Aasl')

			ability.mod:setArea(1, 0)
			for level = 1, sheet.levelsAmount, 1 do
			    ability.mod:setBuffId(raw, level)
			    ability.mod:setTargets('invulnerable,self,vulnerable', level)
			    ability.mod:set('Slo1', 0, level)
			end
			ability.mod:setLevels(sheet.levelsAmount)
			ability.mod:setName(getVal('name'), string.format('defaultName(buff) %s', nilToString(raw, 'NONE')))
			ability.mod:setEditorSuffix('(Buffer)')
			ability.mod:setRace('other')
		end
	end

	require 'vjass'

	local script = vjass.create()

	if (dummy == true) then
		script:addVar(getVal('jassVar')..'Id', 'integer', getVal('jassVarIndex'))
	else
		if (name == nil) then
			name = 'defaultName(buff)'

			if (raw ~= nil) then
				name = name..' '..raw
			end
		end

		local varExpr = script:addVar(getVal('jassVar'), 'Buff', getVal('jassVarIndex'))

		if (raw ~= nil) then
			local bufferRaw = 'b'..raw:sub(2, 4)

			script:addLine([[set %s = Buff.Create('%s', %s, '%s')]], {varExpr, raw, toJassVal(name), bufferRaw})
		else
			script:addLine([[set %s = Buff.CreateHidden(thistype.NAME + %s)]], {varExpr, toJassVal(' ('..fileName..')')})
		end

		if (getVal('positive') ~= nil) then
			script:addLine([[call %s.SetPositive(%s)]], {varExpr, boolToString(getVal('positive'))})
		end

		local t = totable(getVal('lostOn'))

		if t then
			if tableContains(t, 'death') then
				script:addLine('call %s.SetLostOnDeath(true)', {varExpr})
			end

			if tableContains(t, 'dispel') then
				script:addLine('call %s.SetLostOnDispel(true)', {varExpr})
			end
		end

		if (getVal('icon') ~= nil) then
			script:addLine([[call %s.SetIcon(%s)]], {varExpr, toJassVal(getVal('icon'))})
		end

		local sfxCount = 0
		local sfxPaths = {}
		local sfxAttachPts = {}
		local sfxLevels = {}

		local t = totable(getVal('sfxPath'))

		if t then
				for k, v in pairs(t) do
					sfxCount = sfxCount + 1

					sfxPaths[sfxCount] = v
				end
			end

		sfxCount = 0
		t = totable(getVal('sfxAttachPt'))

		if t then
			for k, v in pairs(t) do
				sfxCount = sfxCount + 1

				sfxAttachPts[sfxCount] = v
			end
		end

		sfxCount = 0
		t = totable(getVal('sfxLevel'))

		if t then
			for k, v in pairs(t) do
				sfxCount = sfxCount + 1

				sfxLevels[sfxCount] = v
			end
		end

		for i = 1, sfxCount, 1 do
			if ((sfxPaths[i] ~= nil) and (sfxAttachPts[i] ~= nil) and (sfxLevels[i]) ~= nil) then
				script:addLine([[call %s.TargetEffects.Add(%s, %s, %s)]], {varExpr, toJassVal(sfxPaths[i]), sfxAttachPts[i], sfxLevels[i]})
			end
		end

		local t = totable(getVal('sfxSoundLoop'))

		if (t ~= nil) then
			for i = 1, #t, 1 do
				local soundSheet = getSheet(pathToFullPath(sheet.path, t[i], 'wc3sound'))

				if (soundSheet ~= nil) then
					local val = toJassName(soundSheet:getVal('jassVar'))

					script:addLine([[call %s.LoopSounds.Add(%s)]], {varExpr, val})
				end
			end
		end

		if (getVal('unitMod') ~= nil) then
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

			for level = 1, sheet.levelsAmount, 1 do
				if (getVal('unitMod', level) ~= nil) then
					local mods = totable(getVal('unitMod', level))
					local vals = totable(getVal('unitModVal', level))

					if mods and mods[1] and (mods[1] ~= '') then
						script:addLine([[set %s = UnitModSet.Create()]], {'UnitModSet.TEMP'})

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
										script:addLine([[call %s.CustomMods.Add(%s)]], {'UnitModSet.TEMP', state.jassPath})
										for k, v in pairs(val) do
											script:addLine([[call %s.CustomMods.Add%s(%s, %s, %s)]], {'UnitModSet.TEMP', state.jassArgs[k].typeName, state.jassPath, state.jassArgs[k].key, v})
										end
									else
										script:addLine([[call %s.Mods.Add(%s)]], {'UnitModSet.TEMP', string.format(state.jassLine, table.concat(val, ','))})
									end
								elseif (tonumber(val) ~= nil) then
									script:addLine([[call %s.RealMods.Add(%s, %s)]], {'UnitModSet.TEMP', state, val})
								elseif ((tostring(val) == 'true') or (tostring(val) == 'false')) then
									script:addLine([[call %s.BoolMods.Add(%s, %s)]], {'UnitModSet.TEMP', state, 'true'})
								else
									log(sheet.path..': unitMod type unrecognized ('..mod..', '..tostring(val)..')')
								end
							end
						end

						script:addLine([[call %s.UnitModSets.Add(%i, %s)]], {varExpr, level, [[UnitModSet.TEMP]]})
					end
				end
			end
		end
	end

	createJStream():addLine(script:write())
end

t.tagsFunc = function(t)
	addToEnv(t)

	for level = 1, sheet.levelsAmount, 1 do
		if (getVal('tooltip', level) == nil) then
			if getVal('name', level) then
				setVal('tooltip', getVal('name', level), level)
			end
		end

		if getVal('tooltip', level) then
			setVal('tooltip', tagReplacer:exec('tooltip', getVal('tooltip', level), level, true), level)
		end
		if getVal('uberTooltip', level) then
			setVal('uberTooltip', tagReplacer:exec('uberTooltip', getVal('uberTooltip', level), level, true), level)
		end
	end
end

return t