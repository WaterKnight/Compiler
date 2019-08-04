local t = {}

t.defFunc = function(t)
	addToEnv(t)

	local fileName = getFileName(path, true)

	setDefVal('jassVar', toVar(fileName))
	setDefVal('jassVarIndex', toVarIndex(fileName))

	if (getVal('raw', 1) and (getVal('raw', 1):len() == 3)) then
		if dummy then
			setVal('raw', 'o'..getVal('raw', 1))
		else
			setVal('raw', 'O'..getVal('raw', 1))
		end
	end
end

t.createFunc = function(t)
	addToEnv(t)

	local raw = getVal('raw', 1)

	if (raw == nil) then
		return
	end

	local bolt = createBolt(raw, path)

	bolt:setTexPath(getVal('texPath', 1))
	bolt:setAvgSegLen(getVal('avgSegLen', 1))
	bolt:setWidth(getVal('width', 1))
	bolt:setColor(getVal('red', 1), getVal('green', 1), getVal('blue', 1), getVal('alpha', 1))
	bolt:setNoiseScale(getVal('noiseScale', 1))
	bolt:setTexCoordScale(getVal('texCoordScale', 1))
	bolt:setDuration(getVal('duration', 1))
end

t.jassType = 'LightningType'
t.jassTypeDummy = 'string'

t.jassIniter = [[call LightningType.AddInit(%s)]]

t.jassFunc = function(t)
	addToEnv(t)

	local varExpr = addVar(getVal('jassVar', 1), 'SoundType', getVal('jassVarIndex', 1))

	local raw = getVal('raw', 1)

	if (raw and raw ~= '') then
		writeLine([[set %s = LightningType.Create(%s)]], {varExpr, toJassValue(raw)})
	else
		writeLine([[set %s = LightningType.Create(null)]], {varExpr})
	end
end

t.jassFuncDummy = function(t, jStream)
	addToEnv(t)

	addVar(getVal('jassVar', 1)..'Id', 'string', getVal('jassVarIndex', 1))
end

return t