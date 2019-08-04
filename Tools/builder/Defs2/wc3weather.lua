local t = {}

t.defFunc = function(t)
	addToEnv(t)

	local fileName = getFileName(path, true)

	setDefVal('jassVar', toVar(fileName))
	setDefVal('jassVarIndex', toVarIndex(fileName))

	if (getVal('raw', 1) and (getVal('raw', 1):len() == 3)) then
		if dummy then
			setVal('raw', 'w'..getVal('raw', 1))
		else
			setVal('raw', 'W'..getVal('raw', 1))
		end
	end
end

t.createFunc = function(t)
	addToEnv(t)

	local raw = getVal('raw', 1)

	if (raw == nil) then
		return
	end

	local weather = createWeather(raw, path)

	weather:setTexPath(getVal('texPath', 1))

	weather:setAlphaMod(getVal('alphaMode', 1))
	weather:setUseFog(getVal('useFog', 1))
	weather:setHeight(getVal('height', 1))
	weather:setAng(getVal('angleX', 1), getVal('angleY', 1))
	weather:setEmissionRate(getVal('emissionRate', 1))
	weather:setLifespan(getVal('lifespan', 1))
	weather:setParticles(getVal('particles', 1))
	weather:setSpeed(getVal('speed', 1), getVal('accel', 1))
	weather:setVariance(getVal('variance', 1))
	weather:setTexR(getVal('texR', 1))
	weather:setTexC(getVal('texC', 1))
	weather:setHead(getVal('head', 1))
	weather:setTail(getVal('tail', 1))
	weather:setTailLen(getVal('tailLength', 1))
	weather:setLatitude(getVal('latitude', 1))
	weather:setLongitude(getVal('longitude', 1))

	weather:setMidTime(getVal('midTime', 1))

	weather:setColorStart(getVal('redStart', 1), getVal('greenStart', 1), getVal('blueStart', 1), getVal('alphaStart', 1))
	weather:setColorMid(getVal('redMid', 1), getVal('greenMid', 1), getVal('blueMid', 1), getVal('alphaMid', 1))
	weather:setColorEnd(getVal('redEnd', 1), getVal('greenEnd', 1), getVal('blueEnd', 1), getVal('alphaEnd', 1))

	weather:setScale(getVal('scaleStart', 1), getVal('scaleMid', 1), getVal('scaleEnd', 1))

	weather:setHUV(getVal('hUVStart', 1), getVal('hUVMid', 1), getVal('hUVEnd', 1))
	weather:setTUV(getVal('tUVStart', 1), getVal('tUVMid', 1), getVal('tUVEnd', 1))
	weather:setSound(getVal('sound', 1))
end

t.jassType = 'WeatherType'
t.jassTypeDummy = 'integer'

t.jassIniter = [[call WeatherType.AddInit(%s)]]

t.jassFunc = function(t)
	addToEnv(t)

	local varExpr = addVar(getVal('jassVar', 1), 'WeatherType', getVal('jassVarIndex', 1))

	local raw = getVal('raw', 1)

	if (raw and raw ~= '') then
		writeLine([[set %s = WeatherType.Create(']]..raw..[[')]], {varExpr, raw})
	else
		writeLine([[set %s = WeatherType.Create(0)]], {varExpr})
	end
end

t.jassFuncDummy = function(t, jStream)
	addToEnv(t)

	addVar(getVal('jassVar', 1)..'Id', 'integer', getVal('jassVarIndex', 1))
end

return t