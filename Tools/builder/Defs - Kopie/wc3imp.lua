local t = {}

t.defFunc = function(t)
	addToEnv(t)

	setDefVal('src')
	setDefVal('target')
	setDefVal('type')

	local valType = getVal('type', 1)

	if (valType == 'icon') then
		setDefVal('iconDisabledSrc')
		setDefVal('iconDisabledTarget')

		local src = getVal('src', 1)

		if ((getVal('target', 1) == nil) and src) then
			setVal('target', [[ReplaceableTextures\CommandButtons\]]..src)
		end

		local disabledSrc = getVal('iconDisabledSrc', 1)

		if ((getVal('iconDisabledTarget', 1) == nil) and src and disabledSrc) then
			setVal('iconDisabledTarget', [[ReplaceableTextures\CommandButtonsDisabled\DIS]]..src)
		end
	else
		local src = getVal('src', 1)

		if ((getVal('target', 1) == nil) and src) then
			setVal('target', getFolder(refPath):gsub('%.', '_')..src)
		end
	end
end

t.createFunc = function(t)
	addToEnv(t)

	local src = getVal('src', 1)
	local target = getVal('target', 1)

	if (src and target) then
		copyFile(getFolder(path)..src, OUTPUT_PATH..target)
	end

	local iconDisabledSrc = getVal('iconDisabledSrc', 1)
	local iconDisabledTarget = getVal('iconDisabledTarget', 1)

	if (iconDisabledSrc and iconDisabledTarget) then
		copyFile(getFolder(path)..iconDisabledSrc, OUTPUT_PATH..iconDisabledTarget)
	end
end

t.jassType = nil
t.jassTypeDummy = nil

t.jassIniter = nil

t.jassFunc = nil

return t