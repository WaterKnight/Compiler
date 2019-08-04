local t = {}

t.defFunc = function(t)
	addToEnv(t)

	local fileName = getFileName(path, true)

	setDefVal('jassVar', toVar(fileName))
	setDefVal('jassVarIndex', toVarIndex(fileName))

	if (getVal('raw', 1) and (getVal('raw', 1):len() == 3)) then
		if dummy then
			setVal('raw', 'S'..getVal('raw', 1))
		else
			setVal('raw', 's'..getVal('raw', 1))
		end
	end

	setDefVal('minDist', 0)
	setDefVal('maxDist', 100000)
	setDefVal('cutoffDist', 100000)
end

t.createFunc = function(t)
	addToEnv(t)

	local name = getVal('name', 1)

	if (name == nil) then
		return
	end

	local widget = createSound(name, path)

	if getVal('is3d', 1) then
		widget:setTrue('MaxDistance', getVal('maxDist', 1), 0)
		widget:setTrue('MinDistance', getVal('minDist', 1), 0)
		widget:setTrue('DistanceCutoff', getVal('cutoffDist', 1), 0)

		widget:setTrue('InsideAngle', getVal('insideAngle', 1), 0)
		widget:setTrue('OutsideAngle', getVal('outsideAngle', 1), 0)
		widget:setTrue('OutsideVolume', getVal('outsideVolume', 1), 0)
		widget:setTrue('OrientationX', getVal('orientationX', 1), 0)
		widget:setTrue('OrientationY', getVal('orientationY', 1), 0)
		widget:setTrue('OrientationZ', getVal('orientationZ', 1), 0)
	end
end

t.jassType = 'SoundType'
t.jassTypeDummy = 'string'

t.jassIniter = [[call SoundType.AddInit(%s)]]

t.jassFunc = function(t)
	addToEnv(t)

	local varExpr = addVar(getVal('jassVar', 1), 'SoundType', getVal('jassVarIndex', 1))

	writeLine([[set %s = SoundType.Create()]], {varExpr})

	if getVal('filePath', 1) then
		writeLine([[call %s.SetFilePath(%q)]], {varExpr, toJassValue(getVal('filePath', 1))})
	end

	if getVal('channel', 1) then
		writeLine([[call %s.SetChannel(SoundChannel.%s)]], {varExpr, getVal('channel', 1)})
	end
	if getVal('eax', 1) then
		writeLine([[call %s.SetEax(SoundEax.%s)]], {varExpr, getVal('eax', 1)})
	end
	if getVal('pitch', 1) then
		writeLine([[call %s.SetPitch(%i)]], {varExpr, getVal('pitch', 1)})
	end
	if getVal('pitchVariance', 1) then
		writeLine([[call %s.SetPitchVariance(%i)]], {varExpr, getVal('pitchVariance', 1)})
	end
	if getVal('priority', 1) then
		writeLine([[call %s.SetPriority(%i)]], {varExpr, getVal('priority', 1)})
	end
	if getVal('volume', 1) then
		writeLine([[call %s.SetVolume(%i)]], {varExpr, getVal('volume', 1)})
	end

	if getVal('fadeInRate', 1) then
		writeLine([[call %s.SetFadeIn(%i)]], {varExpr, getVal('fadeInRate', 1)})
	end
	if getVal('fadeOutRate', 1) then
		writeLine([[call %s.SetFadeOut(%i)]], {varExpr, getVal('fadeOutRate', 1)})
	end
	if getVal('looping', 1) then
		writeLine([[call %s.SetLooping(%s)]], {varExpr, boolToString(getVal('looping', 1))})
	end
	if getVal('stopping', 1) then
		writeLine([[call %s.SetStopping(%s)]], {varExpr, boolToString(getVal('stopping', 1))})
	end

	if getVal('is3d', 1) then
		writeLine([[call %s.Set3D(%s)]], {varExpr, boolToString(getVal('is3d', 1))})
		if getVal('minDist', 1) then
			writeLine([[call %s.SetMinDist(%i)]], {varExpr, getVal('minDist', 1)})
		end
		if getVal('maxDist', 1) then
			writeLine([[call %s.SetMaxDist(%i)]], {varExpr, getVal('maxDist', 1)})
		end
		if getVal('cutoffDist', 1) then
			writeLine([[call %s.SetCutoffDist(%i)]], {varExpr, getVal('cutoffDist', 1)})
		end
	end

	if getVal('insideAngle', 1) then
		writeLine([[call %s.SetInsideAngle(%i)]], {varExpr, getVal('insideAngle', 1)})
	end
	if getVal('outsideAngle', 1) then
		writeLine([[call %s.SetOutsideAngle(%i)]], {varExpr, getVal('outsideAngle', 1)})
	end
	if getVal('outsideVolume', 1) then
		writeLine([[call %s.SetOutsideVolume(%i)]], {varExpr, getVal('outsideVolume', 1)})
	end
	if getVal('orientationX', 1) then
		writeLine([[call %s.SetOrientationX(%i)]], {varExpr, getVal('orientationX', 1)})
	end
	if getVal('orientationY', 1) then
		writeLine([[call %s.SetOrientationY(%s)]], {varExpr, getVal('orientationY', 1)})
	end
	if getVal('orientationZ', 1) then
		writeLine([[call %s.SetOrientationZ(%i)]], {varExpr, getVal('orientationZ', 1)})
	end
end

t.jassFuncDummy = function(t, jStream)
	addToEnv(t)

	addVar(getVal('jassVar', 1)..'Id', 'string', getVal('jassVarIndex', 1))
end

return t