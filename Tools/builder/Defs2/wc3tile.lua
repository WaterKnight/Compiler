local t = {}

t.defFunc = function(t)
	addToEnv(t)

	local fileName = getFileName(path, true)

	setDefVal('jassVar', toVar(fileName))
	setDefVal('jassVarIndex', toVarIndex(fileName))

	if (getVal('raw', 1) and (getVal('raw', 1):len() == 3)) then
		if dummy then
			setVal('raw', 'T'..getVal('raw', 1))
		else
			setVal('raw', 't'..getVal('raw', 1))
		end
	end
end

t.createFunc = function(t)
	addToEnv(t)

	local raw = getVal('raw', 1)

	if (raw == nil) then
		return
	end

	local widget = createTile(raw, path)

	local texPath = getVal('texPath', 1)

	local folder = getFolder(texPath)

	if (folder:sub(folder:len(), folder:len()) == [[\]]) then
		folder = folder:sub(1, folder:len() - 1)
	end

	widget:setTrue('dir', folder, '')
	widget:setTrue('file', getFileName(texPath, true), '')

	widget:setTrue('cliffSet', getVal('cliffSet', 1), -1)

	if (getVal('walkable', 1) == true) then
		widget:setTrue('walkable', 1, 0)
	else
		widget:setTrue('walkable', 0, 0)
	end
	if (getVal('flyable', 1) == true) then
		widget:setTrue('flyable', 1, 0)
	else
		widget:setTrue('flyable', 0, 0)
	end
	if (getVal('buildable', 1) == true) then
		widget:setTrue('buildable', 1, 0)
	else
		widget:setTrue('buildable', 0, 0)
	end

	if (getVal('footprints', 1) == true) then
		widget:setTrue('footprints', 1, 0)
	else
		widget:setTrue('footprints', 0, 0)
	end
	widget:setTrue('blightPri', getVal('blightPriority', 1), 0)
end

t.jassType = 'TileType'
t.jassTypeDummy = 'integer'

t.jassIniter = [[call TileType.AddInit(%s)]]

t.jassFunc = function(t)
	addToEnv(t)

	local varExpr = addVar(getVal('jassVar', 1), 'SoundType', getVal('jassVarIndex', 1))

	local raw = getVal('raw', 1)

	if (raw and raw ~= '') then
		writeLine([[set %s = TileType.CreateFromSelf('%s')]], {varExpr, raw})
	else
		writeLine([[set %s = TileType.CreateFromSelf(0)]], {varExpr})
	end
end

t.jassFuncDummy = function(t, jStream)
	addToEnv(t)

	addVar(getVal('jassVar', 1)..'Id', 'integer', getVal('jassVarIndex', 1))
end

return t