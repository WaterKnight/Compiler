local t = {}

t.defFunc = function(t)
	addToEnv(t)

	local fileName = getFileName(path, true)

	setDefVal('jassVar', toVar(fileName))
	setDefVal('jassVarIndex', toVarIndex(fileName))

	if (getVal('raw', 1) and (getVal('raw', 1):len() == 3)) then
		if dummy then
			setVal('raw', 'c'..getVal('raw', 1))
		else
			setVal('raw', 'C'..getVal('raw', 1))
		end
	end
end

t.createFunc = function(t)
	addToEnv(t)

	local function boolToBitString(b)
		if b then
			return '\1'
		end

		return '\0'
	end

	local widget = createWidget('destructable', getVal('raw', 1), nil, getVal('profileIdent', 1), path)

	--constant
	widget:set('bonc', 1)
	widget:set('bonw', 1)
	widget:set('btil', '*')
	widget:set('buch', 1)

	widget:set('bnam', getVal('name', 1), '')

	widget:set('bfil', getVal('model', 1), '')
	widget:set('blit', boolToBitString(getVal('modelLightweight', 1)), '\0')
	widget:set('bgpm', getVal('modelPortrait', 1), '')
	widget:set('bvar', getVal('modelVariations', 1), 1)

	widget:set('bflh', getVal('flyHeight', 1), 0)
	widget:set('boch', getVal('occluderHeight', 1), 0)
	widget:set('btxf', getVal('replaceableTex', 1), '')
	widget:set('btxi', getVal('replaceableTexId', 1), 0)
	widget:set('bgsc', getVal('selScale', 1), 0)
	widget:set('bvcr', getVal('vertexColorRed', 1), 255)
	widget:set('bvcg', getVal('vertexColorGreen', 1), 255)
	widget:set('bvcb', getVal('vertexColorBlue', 1), 255)

	widget:set('brad', getVal('elevRad', 1), 0)
	widget:set('bmar', getVal('maxRoll', 1), 0)
	widget:set('bmap', getVal('maxPitch', 1), 0)

	widget:set('bsmm', getVal('minimapDisplay', 1), '\0')
	if (getVal('minimapRed', 1) or getVal('minimapGreen', 1) or getVal('minimapBlue', 1)) then
		widget:set('bmmr', getVal('minimapRed', 1), 0)
		widget:set('bmmg', getVal('minimapGreen', 1), 0)
		widget:set('bmmb', getVal('minimapBlue', 1), 0)
		widget:set('bumm', '\1')
	else
		widget:set('bumm', '\0')
	end

	widget:set('bdsn', getVal('deathSound', 1), '')
	widget:set('bshd', getVal('shadow', 1), '')

	widget:set('barm', getVal('armor', 1), '')
	widget:set('bflo', boolToBitString(getVal('fatLOS', 1)), '\0')
	widget:set('bfra', getVal('fogRad', 1), 0)
	widget:set('bfvi', getVal('fogVisibility', 1), '\0')
	widget:set('bhps', getVal('life', 1), 1)
	widget:set('bgse', getVal('selectable', 1), '\0')

	widget:set('bptx', getVal('pathTex', 1), '')
	widget:set('bptd', getVal('pathTexDead', 1), '')
	widget:set('btar', getVal('combatFlags', 1), '')
	widget:set('bclh', getVal('cliffLevel', 1), 0)
	if getVal('walkable', 1) then
		widget:set('bwal', 1)
	else
		widget:set('bwal', 0)
	end

	widget:doSpecials(getVal('specialsTrue'), getVal('specials'))
end

t.jassType = 'DestructableType'
t.jassTypeDummy = 'integer'

t.jassIniter = [[call DestructableType.AddInit(%s)]]

t.jassFunc = function(t)
	addToEnv(t)

	if raw then
		writeLine([[set ]]..var..[[ = DestructableType.Create(']]..raw..[[')]])
	end
end

t.jassFuncDummy = function(t, jStream)
	addToEnv(t)

	addVar(getVal('jassVar', 1)..'Id', 'integer', getVal('jassVarIndex', 1))
end

return t