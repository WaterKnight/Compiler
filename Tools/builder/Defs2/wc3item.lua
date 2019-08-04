local t = {}

t.defFunc = function(t)
	addToEnv(t)

	local fileName = getFileName(path, true)

	setDefVal('jassVar', toVar(fileName))
	setDefVal('jassVarIndex', toVarIndex(fileName))

	if (getVal('raw', 1) and (getVal('raw', 1):len() == 3)) then
		if dummy then
			setVal('raw', 'i'..getVal('raw', 1))
		else
			setVal('raw', 'I'..getVal('raw', 1))
		end
	end
end

t.createFunc = function(t)
	addToEnv(t)

	local raw = getVal('raw', 1)

	if (raw == nil) then
		return
	end

	local widget = createWidget('item', raw, nil, getVal('profileIdent', 1), path)

	local abilities
	local cooldownGroup

	local function addAbility(value)
		if abilities then
			abilities = abilities..','..value
		else
			abilities = value
			if (cooldownGroup == nil) then
				cooldownGroup = value
			end
		end
	end

	--constant
	widget:set('idro', 1)
	widget:set('ihtp', 1)
	widget:set('ipaw', 1)
	widget:set('isel', 1)
	widget:set('isto', 1)

	widget:set('iarm', getVal('armor', 1), '')
	widget:set('iclr', getVal('vertexColorRed', 1), 255)
	widget:set('iclg', getVal('vertexColorGreen', 1), 255)
	widget:set('iclb', getVal('vertexColorBlue', 1), 255)
	widget:set('ides', getVal('description', 1), '')
	widget:set('iico', getVal('icon', 1), '')
	widget:set('ifil', getVal('model', 1), '')
	widget:set('igol', getVal('goldCost', 1), 0)
	widget:set('ilum', getVal('lumberCost', 1), 0)
	widget:set('ipaw', '1')
	widget:set('isca', getVal('scale', 1), 1)
	widget:set('isel', '1')
	widget:set('istr', 0)
	widget:set('unam', getVal('name', 1), 'defaultName(item) '..nilToString(raw, 'NONE'))
	widget:set('utip', getVal('tooltip', 1), '')
	widget:set('utub', getVal('uberTooltip', 1), '')

	if getVal('abilities', 1) then
		local t = totable(getVal('abilities', 1))

		for k, v in pairs(t) do
			if v:find('{', 1, true) then
				t[k] = v:sub(1, v:find('{', 1, true) - 1)
			end
		end

		t = objPathsToRaw(path, t, 'wc3spell')

		if t then
			for k, v in pairs(t:split(',')) do
				addAbility(v)
			end
		end
	end

	local classes = totable(getVal('classes', 1))

	if classes then
    		if tableContains(classes, 'POWER_UP') then
			addAbility(getObjVal(pathToFullPath(path, [[Header\Item.page\powerUpAbility]], 'wc3spell'), 'raw', 1))
		elseif tableContains(classes, 'SCROLL') then
			addAbility(getObjVal(pathToFullPath(path, [[Header\Item.page\scrollAbility]], 'wc3spell'), 'raw', 1))
		end
	end

	if abilities then
		widget:set('iabi', abilities)
		widget:set('icid', cooldownGroup)
		widget:set('iusa', 1)
	end

	widget:doSpecials(getVal('specialsTrue'), getVal('specials'))
end

t.jassType = 'ItemType'
t.jassTypeDummy = 'integer'

t.jassIniter = [[call ItemType.AddInit(%s)]]

t.jassFunc = function(t)
	addToEnv(t)

	local varExpr = addVar(getVal('jassVar', 1), 'UnitType', getVal('jassVarIndex', 1))

	if raw then
		writeLine([[set %s = ItemType.CreateFromSelf('%s')]], {varExpr, raw})
	end

	local t = totable(getVal('classes', 1))

	if t then
		for k, class in pairs(t) do
			writeLine([[call %s.Classes.Add(ItemClass.%s)]], {varExpr, class})
		end
	end

	if getVal('chargesAmount', 1) then
		writeLine([[call %s.ChargesAmount.Set(%i)]], {varExpr, getVal('chargesAmount', 1)})
	end
	if getVal('icon', 1) then
		writeLine([[call %s.SetIcon(%s)]], {varExpr, toJassValue(getVal('icon', 1))})
	end
	if getVal('usageGoldCost', 1) then
		writeLine([[call %s.UsageGoldCost.Set(%i)]], {varExpr, getVal('usageGoldCost', 1)})
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

	if (getVal('tooltip', 1) == nil) then
		if getVal('name', 1) then
			setVal('tooltip', 1, 'Purchase '..module_color.encolor(getVal('name', 1), module_color.colors.DWC))
		end
	end

	if getVal('tooltip', 1) then
		setVal('tooltip', 1, replaceTags('tooltip', getVal('tooltip', 1), 1, true))
	end
	if getVal('uberTooltip', 1) then
		setVal('uberTooltip', 1, replaceTags('uberTooltip', getVal('uberTooltip', 1), 1, true))

		if getVal('usageGoldCost', 1) then
			if (getVal('usageGoldCost', 1) > 0) then
		                setVal('uberTooltip', 1, getVal('uberTooltip', 1)..'|n|n'..module_color.encolor('Usage Gold Cost: '..module_color.engold(getVal('usageGoldCost', 1)), module_color.colors.DWC))
			end
		end
	end
end

return t