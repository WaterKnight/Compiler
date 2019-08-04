--[[local function toJassValue(val, jassType)
	assert(val, 'no value')

	if (jassType == nil) then
		jassType = type(val)
	end

	if (jassType == 'boolean') then
		return boolToString(val)
	end
	if (jassType == 'string') then
		if isPlainText(val) then
			return val:doubleBackslashes():quote()
		end
	end

	return val
end

local function toJassName(s)
	assert(s, 'no value')

	local result = ''

	for i = 1, s:len(), 1 do
		local c = s:sub(i, i)

		if ((c >= 'A') and (c <= 'Z') and (i > 1)) then
			result = result..'_'..c
		else
			result = result..c:upper()
		end
	end

	return result
end


local function toJassPath(base, a, mainExtension)
	assert(a, 'no value')

	local s = pathMap:toFullPath(base, a, mainExtension)

	assert(s, 'toJassPath: no path'..' ('..table.concat({tostring(base), tostring(a), tostring(mainExtension)}, ',')..')')

	local c = 1
	local startFrom
	local t = s:split([[\]])

	while (t[c] ~= nil) do
		if t[c]:find('.struct', 1, true) then
			startFrom = c
		end

		c = c + 1
	end

	c = startFrom

	s = t[c]:sub(1, t[c]:find('.struct', 1, true) - 1)..'(NULL)'

	c = c + 1

	while (t[c + 1] ~= nil) do
		s = s..'.'..t[c]

		c = c + 1
	end

	s = s..'.'..toJassName(getFileName(t[c], true))

	return s
end]]

--[[local function clearJs()
	for _, path in pairs(getFiles(dataPath, '*obj_*.j')) do
	    removeFile(path)
	end

	for _, path in pairs(getFiles(dataPath, '*obj.j')) do
	    removeFile(path)
	end
end

local function initJs()
	clearJs()
end

local function finalizeJs()
	log('finalize js')

	--obj imports
	local folderImports = {}

	for path, jData in pairs(generatedJs) do
		local folder = pather.getScriptRallyPath(getFolder(path))

		if (folderImports[folder] == nil) then
			folderImports[folder] = {}
		end

		folderImports[folder][path] = path

		--
		local varLines = jData.varLines
		local lines = jData.lines

		local varLinesC

		if (varLines ~= nil) then
			varLinesC = #varLines
		else
			varLinesC = 0
		end

		local linesC

		if (lines ~= nil) then
			linesC = #lines
		else
			linesC = 0
		end

		local finalLines = {}
		local finalLinesC = 0

		local function writeLine(s)
			finalLinesC = finalLinesC + 1
			finalLines[finalLinesC] = s
		end

		for i = 1, varLinesC, 1 do
			writeLine(varLines[i])
		end

		if ((varLinesC > 0) and (linesC > 0)) then
			writeLine('')
		end

		if (linesC > 0) then
			jData.hasInitMethod = true

			writeLine(string.format('static method Init_sheet_%s takes nothing returns boolean', getFileName(path, true):gsub('%.', '_'):trim('['):trim(']')))

			for i = 1, linesC, 1 do
				writeLine(lines[i])
			end

			writeLine('\t'..[[return true]])

			writeLine([[endmethod]])
		end

		writeTable(path, finalLines)
	end

	for folder in pairs(folderImports) do
		local file = io.open(folder..[[obj.j]], 'w+')

		local sharedStream = pathSharedJStreams[folder]

		if sharedStream then
			sharedStream:finalize()

			local len = sharedStream.varLinesC + sharedStream.linesC

			if (len > 0) then
				file:write('//open shared vars', '\n')

				for _, line in pairs(sharedStream.varLines) do
					file:write(line, '\n')
				end
				for _, line in pairs(sharedStream.lines) do
					file:write(line, '\n')
				end

				file:write('//close shared vars', '\n')
			end
		end

		for k, imp in pairs(folderImports[folder]) do
			local impFile = io.open(imp, 'r')

			if impFile then
				file:write('//open obj '..imp..'\n')

				for impFileLine in impFile:lines() do
					file:write(impFileLine..'\n')
				end

				impFile:close()

				file:write('//close obj '..imp..'\n\n')
			end
		end

		file:write('\n'..'static method objInits_autoRun takes nothing returns nothing')

		for k, imp in pairs(folderImports[folder]) do
			local jData = generatedJs[imp]

			local hasInitMethod = jData.hasInitMethod
			local objType = jData.objType

			if (hasInitMethod and (objType ~= nil)) then
				local function toJassValue(v, jassType)
					if (jassType == nil) then
						jassType = type(v)
					end
			
					if (jassType == 'boolean') then
						return boolToString(v)
					end
					if (jassType == 'string') then
						if isPlainText(v) then
							return v:doubleBackslashes():quote()
						end
					end
			
					return v
				end

				local path = toJassValue(imp)

				imp = getFileName(imp, true):gsub('%.', '_'):trim('['):trim(']')

				local paramsLine = 'function thistype.Init_obj_'..imp..', '..path

				if typeDefs[objType].jassIniter then
					file:write('\n\t'..string.format(typeDefs[objType].jassIniter, paramsLine))
				end
			end
		end

		file:write('\n'..'endmethod')

		file:close()
	end

	--write output
	local outputFile = io.open(OUTPUT_PATH..[[war3mapAdd.j]], 'w+')
	local outputFileAdded = {}

	local function addJToOutput(path)	
		if ((getFileName(path):find('obj', 1, true) ~= 1) and (outputFileAdded[path] == nil)) then
			local file = io.open(path)

			if file then
				outputFileAdded[path] = true
			    outputFile:write('\n'..'//file: '..path..'\n')

				for line in file:lines() do
				   	outputFile:write(line..'\n')
				end

				file:close()

				outputFile:write('\n'..'//end of file: '..path..'\n')
			else
			    log(path..' does not exist')
			end
		end
	end

	local jPathsFile = io.open(logsDir..[[addedJs.txt]], 'w+')

	local jFiles = getFiles(dataPath, '*.j')

	for _, path in pairs(jFiles) do
		addJToOutput(path)
	end

	jPathsFile:write(table.concat(jFiles, '\n'))

	jPathsFile:close()

	--close
	outputFile:close()

	--clearJs()
end]]