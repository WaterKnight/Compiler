require 'waterlua'

local mpqeditorPath = configParser(io.toAbsPath('portLib.conf')).mpqeditorPath

mpqPort = {}

function createMpqPort()
	local this = {}

	this.lines = {}
	this.listedFiles = {}
	this.listfilePath = (io.local_dir()..[[listfile.txt]])
	this.extractTargetPaths = {}

	function this:addLine(line)
		this.lines[#this.lines + 1] = line
	end

	function this:addImport(sourcePath, targetPath)
		sourcePath = io.toAbsPath(sourcePath)

		this:addLine([[a %s ]]..sourcePath:quote()..[[ ]]..targetPath:quote()..[[]])
	end

	function this:addExtract(sourcePath, targetPath)
		targetPath = io.toAbsPath(targetPath)

		local targetFolder = getFolder(targetPath)

		this.listedFiles[#this.listedFiles + 1] = sourcePath
		this.extractTargetPaths[#this.extractTargetPaths + 1] = targetPath

		print('addExtract', sourcePath, targetFolder)

		this:addLine([[e %s ]]..sourcePath:quote()..[[ ]]..targetFolder:quote()..[[ /fp]])
	end

	function this:commit(mpqPath)
		for i = 1, #this.extractTargetPaths, 1 do
			lfs.mkdir(getFolder(this.extractTargetPaths[i]))
		end

		local lines = {}

		lines[#lines + 1] = string.format([[o %s ]]..this.listfilePath:quote(), mpqPath:quote())

		for i = 1, #this.lines, 1 do
			lines[#lines + 1] = string.format(this.lines[i], mpqPath:quote())
		end

		local listfile = io.open(this.listfilePath, "w+")

		listfile:write(table.concat(this.listedFiles, '\n'))

		listfile:close()

		local scriptPath = io.toAbsPath('portDataScript.txt')

		local f = io.open(scriptPath, 'w+')

		f:write(table.concat(lines, '\n'))

		f:close()

		runProg(nil, mpqeditorPath, {scriptPath}, {'console'})
	end

	return this
end

function mpqExtract(mpqPath, sourcePath, targetPath)
	local newPort = createMpqPort()

	newPort:addExtract(sourcePath, targetPath)

	newPort:commit(mpqPath)
end