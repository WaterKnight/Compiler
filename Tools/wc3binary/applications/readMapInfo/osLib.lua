function cutFloat(a)
	return (math.floor(a * 100) / 100)
end

function runOs(cmd, args, options, fromFolder, doNotWait, name)
	cmd = cmd:gsub('/', '\\')

	local fileName = getFileName(cmd)
	local folder = getFolder(cmd)

	--if doNotWait then
	--	cmd = fileName
	--else
		if (folder and (folder ~= "")) then
			cmd = cmd:quote()
		end
	--end

	if options then
		for k, v in pairs(options) do
			v = tostring(v)

			options[k] = '/'..v
		end

		options = table.concat(options, ' ')

		cmd = cmd..' '..options
	end

	if args then
		for k, v in pairs(args) do
			v = tostring(v)

			args[k] = v:quote()
		end

		args = table.concat(args, ' ')

		cmd = cmd..' '..args
	end

	tempC = tempC + 1

	local tempFilePath = [[tempCalls\temp]]..tempC..[[.bat]]

	local file = io.open(tempFilePath, 'w+')

	assert(file, "cannot open "..tempFilePath)

	if (fromFolder and (fromFolder ~= "")) then
		file:write('cd /d '..fromFolder:quote()..'\n')
	end

	if doNotWait then
		file:write(cmd)
	else
		if name then
			file:write('@echo | call '..cmd)
		else
			file:write(cmd)
		end

		file:write("\nexit")
	end

	file:close()

	os.execute("@echo OFF")
	if doNotWait then
		os.execute('start /min '..tempFilePath..' 2>>NUL')
	else
		if (name == nil) then
			name = ""
		end

		os.execute('start /wait /min '..name:quote()..' '..tempFilePath..' >> '..logDetailedPath:quote()..' 2>>NUL')
	end
	os.execute("@echo ON")
end

function runProg(interpreter, path, args, doNotWait)
	path = path:gsub('/', '\\')

	local folder = getFolder(path)
	local fileName = getFileName(path)

	path = fileName

	if interpreter then
		if args then
			local tmp = {}

			for k, v in pairs(args) do
				tmp[k] = v
			end

			for k, v in pairs(tmp) do
				args[k + 1] = v
			end
		else
			args = {}
		end

		args[1] = path
	end

	local t = os.clock()

	print('run '..path)

	if interpreter then
		runOs(interpreter, args, nil, folder, doNotWait, nil)
	else
		runOs(path, args, nil, folder, doNotWait, path)
	end

	log:write('finished '..path..' after '..cutFloat(os.clock() - t)..' seconds\n')
	io.write(' - '..cutFloat(os.clock() - t)..'seconds\n')
end