local t = {}

t.defFunc = function(t)
	addToEnv(t)

	local fileName = getFileName(path, true)

	setDefVal('jassVar', toVar(fileName))
	setDefVal('jassVarIndex', toVarIndex(fileName))

	if (getVal('raw', 1) and (getVal('raw', 1):len() == 3)) then
		if dummy then
			setVal('raw', 'P'..getVal('raw', 1))
		else
			setVal('raw', 'p'..getVal('raw', 1))
		end
	end
end

t.createFunc = function(t)
	addToEnv(t)

	local raw = getVal('raw', 1)

	if (raw == nil) then
		return
	end

	local widget = createUbersplat(raw, path)

	local texPath = getVal('texPath', 1)
print(texPath, path)
	local folder = getFolder(texPath)

	if (folder ~= nil) then
		if (folder:sub(folder:len(), folder:len()) == [[\]]) then
			folder = folder:sub(1, folder:len() - 1)
		end
	end

	widget:setTrue('Dir', folder, '')
	widget:setTrue('file', getFileName(texPath, true), '')

	widget:setTrue('BlendMode', getVal('blendMode', 1), 0)

	widget:setTrue('Scale', getVal('scale', 1), 100)
	widget:setTrue('BirthTime', getVal('birthTime', 1), 0)
	widget:setTrue('PauseTime', getVal('pauseTime', 1), 0)
	widget:setTrue('Decay', getVal('decay', 1), 0)

	widget:setTrue('StartR', getVal('redStart', 1), 255)
	widget:setTrue('StartG', getVal('greenStart', 1), 255)
	widget:setTrue('StartB', getVal('blueStart', 1), 255)
	widget:setTrue('StartA', getVal('alphaStart', 1), 255)

	widget:setTrue('MiddleR', getVal('redMid', 1), 127)
	widget:setTrue('MiddleG', getVal('greenMid', 1), 127)
	widget:setTrue('MiddleB', getVal('blueMid', 1), 127)
	widget:setTrue('MiddleA', getVal('alphaMid', 1), 127)

	widget:setTrue('EndR', getVal('redEnd', 1), 0)
	widget:setTrue('EndG', getVal('greenEnd', 1), 0)
	widget:setTrue('EndB', getVal('blueEnd', 1), 0)
	widget:setTrue('EndA', getVal('alphaEnd', 1), 0)

	widget:setTrue('Sound', getVal('sound', 1), 'NULL')
end

t.jassType = 'UbersplatType'
t.jassTypeDummy = 'string'

t.jassIniter = [[call UbersplatType.AddInit(%s)]]

t.jassFunc = function(t)
	addToEnv(t)

	local varExpr = addVar(getVal('jassVar', 1), 'UbersplatType', getVal('jassVarIndex', 1))

	local raw = getVal('raw', 1)

	if (raw and raw ~= '') then
		writeLine([[set %s = UbersplatType.Create(%q)]], {varExpr, raw})
	else
		writeLine([[set %s = UbersplatType.Create(null)]], {varExpr})
	end
end

t.jassFuncDummy = function(t, jStream)
	addToEnv(t)

	addVar(getVal('jassVar', 1)..'Id', 'string', getVal('jassVarIndex', 1))
end

return t