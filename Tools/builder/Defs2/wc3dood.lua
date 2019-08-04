local t = {}

t.defFunc = function(t)
	addToEnv(t)

	if (getVal('raw', 1) and (getVal('raw', 1):len() == 3)) then
		if dummy then
			setVal('raw', 'd'..getVal('raw', 1))
		else
			setVal('raw', 'D'..getVal('raw', 1))
		end
	end
end

t.createFunc = function(t)
	addToEnv(t)

	local raw = getVal('raw', 1)

	if (raw == nil) then
		return
	end

	local widget = createWidget('doodad', raw, nil, getVal('profileIdent', 1), path)

	widget:setTrue('Name', getVal('name', 1))

	local cat = getVal('category', 1)

	if (cat == 'props') then
		widget:setTrue('category', 'O')
	elseif (cat == 'structure') then
		widget:setTrue('category', 'S')
	elseif (cat == 'terrain') then
		widget:setTrue('category', 'C')
	elseif (cat == 'environment') then
		widget:setTrue('category', 'E')
	elseif (cat == 'cinematic') then
		widget:setTrue('category', 'Z')
	elseif (cat == 'water') then
		widget:setTrue('category', 'W')
	else
		widget:setTrue('category', 'O')
	end

	widget:setTrue('tilesets', '*')
	widget:setTrue('UserList', 1)
	widget:setTrue('onCliffs', 1)
	widget:setTrue('onWater', 1)
	widget:setTrue('canPlaceRandScale', 0)
	widget:setTrue('tilesetSpecific', 0)

	widget:setTrue('selSize', getVal('selSize', 1), 0)
	widget:setTrue('useClickHelper', getVal('useClickHelper', 1), 0)
	widget:setTrue('ignoreModelClick', getVal('ignoreModelClick', 1), 0)

	widget:setTrue('file', getVal('model', 1), 'none')
	widget:setTrue('numVar', levelsAmount, 1)

	widget:setTrue('minScale', getVal('minScale', 1), 0.8)
	widget:setTrue('maxScale', getVal('maxScale', 1), 1.2)
	widget:setTrue('defScale', getVal('defaultScale', 1), 1)
	widget:setTrue('fixedRot', getVal('fixedRotation', 1), -1)

	widget:setTrue('maxRoll', getVal('maxRoll', 1), 0)
	widget:setTrue('maxPitch', getVal('maxPitch', 1), 0)

	for i = 1, 10, 1 do
		local suffix

		if (i < 10) then
			suffix = '0'..i
		else
			suffix = i
		end

		widget:setTrue('vertR'..suffix, getVal('red', i), 255)
		widget:setTrue('vertG'..suffix, getVal('green', i), 255)
		widget:setTrue('vertB'..suffix, getVal('blue', i), 255)
	end

	widget:setTrue('visRadius', getVal('visRange', 1), 50)
	widget:setTrue('showInFog', getVal('showInFog', 1), 1)
	widget:setTrue('animInFog', getVal('animInFog', 1), 0)
	widget:setTrue('shadow', getVal('hasShadow', 1), 0)
	widget:setTrue('floats', getVal('floats', 1), 1)
	widget:setTrue('walkable', getVal('walkable', 1), 0)

	if (getVal('minimapRed', 1) or getVal('minimapGreen', 1) or getVal('minimapBlue', 1)) then
		widget:setTrue('showInMM', 1)
		widget:setTrue('useMMColor', 1)
	end
	widget:setTrue('MMRed', getVal('minimapRed', 1), 255)
	widget:setTrue('MMGreen', getVal('minimapGreen', 1), 255)
	widget:setTrue('MMBlue', getVal('minimapBlue', 1), 255)

	widget:setTrue('pathTex', getVal('pathTex', 1), 'none')

	widget:setTrue('soundLoop', getVal('sound', 1), '_')

	widget:doSpecials(getVal('specialsTrue'), getVal('specials'))
end

t.jassType = nil
t.jassTypeDummy = nil

t.jassIniter = nil

t.jassFunc = function(t)
	addToEnv(t)
end

return t