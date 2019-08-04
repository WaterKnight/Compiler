require 'waterlua'

osLib.clearScreen()

local ntype = type

local time = os.clock()

local logsDir = io.local_dir()..[[Logs\]]

createDir(logsDir)

local errorLog = io.open(logsDir..[[errorLog.txt]], 'w+')

function log(s)
	errorLog:write(s..'\n')
end

local params = {...}

local inputPath = params[1]
local outputPath = params[2]
local dataPath = params[3]

assert(inputPath, 'no inputPath')
assert(outputPath, 'no outputPath')

local input = io.open(inputPath, 'r')

assert(input, 'cannot open '..inputPath)

input:close()

local lines = {}
local linesC = 0

local filesAdded = {}

local loadingParts = {}
local loadingsTotal = 0

local macros = {}
local curMacro

local pathPat = '[A-Za-z0-9_$%.]'
local pathNegPat = '[^A-Za-z0-9_$%.]'

string.readPath = function(line, posStart)
	posStart = line:find(pathPat, posStart)

	if (posStart == nil) then
		return
	end

	local posEnd = line:find(pathNegPat, posStart)

	if posEnd then
		posEnd = posEnd - 1
	else
		posEnd = line:len()
	end

	return line:sub(posStart, posEnd), posStart, posEnd
end

local identifierPat = '[A-Za-z0-9_$]'
local identifierNegPat = '[^A-Za-z0-9_$]'

string.readIdentifier = function(line, posStart)
	posStart = line:find(identifierPat, posStart)

	if (posStart == nil) then
		return
	end

	local posEnd = line:find(identifierNegPat, posStart)

	if posEnd then
		posEnd = posEnd - 1
	else
		posEnd = line:len()
	end

	return line:sub(posStart, posEnd), posStart, posEnd
end

string.reverseReadIdentifier = function(line, pos)
	local len = line:len()

	line, posStart, posEnd = line:reverse():readIdentifier(len - pos + 1)

	return line:reverse(), len - posEnd + 1, len - posStart + 1
end

local identifierExPat = '[A-Za-z0-9_$<>]'
local identifierExNegPat = '[^A-Za-z0-9_$<>]'

string.readIdentifierEx = function(line, posStart)
	posStart = line:find(identifierExPat, posStart)

	if (posStart == nil) then
		return
	end

	local posEnd = line:find(identifierExNegPat, posStart)

	if posEnd then
		posEnd = posEnd - 1
	else
		posEnd = line:len()
	end

	return line:sub(posStart, posEnd), posStart, posEnd
end

local function evalMacros(line)
	local result = {}

	local t = line:split('\n')

	for i = 1, #t, 1 do
		local line = t[i]

		local pos, posEnd = line:find('//! runtextmacro')

		if pos then
			local name, pos, posEnd = line:readIdentifier(posEnd + 1)

			local args = {}

			if pos then
				local pos, posEnd = line:find('%(')

				if pos then
					line = line:sub(posEnd + 1)

					local pos, posEnd = line:lastFind('%)')

					if pos then
						line = line:sub(1, pos - 1)

						local t = line:split(',')
		
						for i = 1, #t, 1 do
							local arg = t[i]:trimSurroundingWhitespace()

							if ((arg:sub(1, 1) == [["]]) and (arg:sub(arg:len(), arg:len()) == [["]])) then
								arg = arg:sub(2, arg:len() - 1)
							end

							if (arg == nil) then
								arg = ''
							end
		
							args[#args + 1] = arg
						end
					end
				end
			end

			local macro = macros[name]

			if macro then
				line = ''

				for i = 2, #macro.lines, 1 do
					local macroLine = macro.lines[i]

					for i2 = 1, #macro.args, 1 do
						macroLine = macroLine:gsub('%$'..macro.args[i2]..'%$', args[i2])
					end

					local t = evalMacros(macroLine)

					for i2 = 1, #t, 1 do
						result[#result + 1] = t[i2]
					end
				end
			else
				error(string.format('macro %s not found', name))
				--addTmpLine(line)
				result[#result + 1] = line
			end
		else
			result[#result + 1] = line
		end
	end

	return result
end

local function evalMacrosTable(t)
	local result = {}

	for i = 1, #t, 1 do
		local t2 = evalMacros(t[i])

		for i2 = 1, #t2, 1 do
			result[#result + 1] = t2[i2]
		end
	end

	return result
end

local function addLine(line, pos)
	local t = line:split('\n')

	local size = #t

	if pos then
		for i = linesC, pos, -1 do
			lines[i + size] = lines[i + size - 1]
		end

		for i = 1, size, 1 do
			lines[pos + i - 1] = t[i]
		end

		linesC = linesC + size
	else
		for k, v in pairs(t) do
			linesC = linesC + 1
			lines[linesC] = v
		end
	end

	return size
end

local funcTypes = {}
local funcTypesByName = {}
local funcTypesByStartWord = {}

local function createFuncType(name, startWord, isStatic, includeParams, forceTrueReturn)
	local this = {}

	this.name = name
	this.startWord = startWord

	this.forceTrueReturn = forceTrueReturn
	this.includeParams = includeParams
	this.isStatic = isStatic

	funcTypes[#funcTypes + 1] = this

	funcTypesByName[name] = this
	funcTypesByStartWord[startWord] = this

	return this
end

local FUNC_TYPE_NORMAL = createFuncType('normal', 'method')
local FUNC_TYPE_OPERATOR = createFuncType('operator', 'operatorMethod')
local FUNC_TYPE_DESTROY = createFuncType('destroy', 'destroyMethod', false, false, true)
local FUNC_TYPE_EVENT = createFuncType('event', 'eventMethod', true, true, true)
local FUNC_TYPE_TIMER = createFuncType('timer', 'timerMethod', true)
local FUNC_TYPE_COND = createFuncType('cond', 'condMethod', true, false, true)
local FUNC_TYPE_COND_EVENT = createFuncType('condEvent', 'condEventMethod', true, true, true)
local FUNC_TYPE_ENUM = createFuncType('enum', 'enumMethod', true, true, true)
local FUNC_TYPE_EXEC = createFuncType('exec', 'execMethod', true, false, true)
local FUNC_TYPE_TRIG = createFuncType('trig', 'trigMethod', true, false, true)
local FUNC_TYPE_COND_TRIG = createFuncType('condTrig', 'condTrigMethod', true, false, true)
local FUNC_TYPE_INIT = createFuncType('init', 'initMethod', true, false, true)

local rawLines = {}
local rawLinesC = 0

local function addRawLine(line)
	if line:isWhitespace() then
		return
	end

	rawLinesC = rawLinesC + 1
	rawLines[rawLinesC] = line
end

local structLookupPaths = {}

local function addJ(path)
	print('addJ', path)

	local returnTable

	if (filesAdded[path] == nil) then
		if (getFileName(path):find('obj', 1, true) == 1) then
			if (getFileName(path) == 'obj.j') then			
				local t = getFolder(path):split('\\')
	
				t[#t] = nil
	
				local c = #t
	
				while (t[c] and not t[c]:endsWith('.struct')) do
					c = c - 1
				end
	
				if t[c] then
					t[c] = t[c]:sub(1, t[c]:len() - string.len('.struct'))
		
					local refPath = table.concat(t, '\\', c)
		
					structLookupPaths[refPath] = path
				end
			end
		else
			local file = io.open(path, 'r')
	
			if (file == nil) then
				log(path..' does not exist')
			end
	
			if file then
				filesAdded[path] = true
	
				addRawLine('//start of file: '..path)
	
				for line in file:lines() do
					addRawLine(line)
				end
	
				addRawLine('//end of file: '..path)
	
				file:close()
			end
		end
	end
end

local files = getFiles(io.local_dir()..[[BasicJs\]], '*.j')

for k, v in pairs(files) do
print('basic', v)
	--addJ(v)
end

if dataPath then
	local files = getFiles(dataPath, '*.j')

	for k, v in pairs(files) do
		addJ(v)
	end
end

addJ(inputPath)

local function compileScript()
	local waitingForCommentEnd
	local waitingForInitMethodEnd

	local lines = {}
	local linesC = 0

	local rawLineNum = 1

	while rawLines[rawLineNum] do
		local line = rawLines[rawLineNum]

		if waitingForCommentEnd then
			local pos, posEnd = line:find('%*%/')

			if pos then
				line = line:sub(posEnd + 1, line:len())
				waitingForCommentEnd = false
			else
				line = nil
			end
		else
			local oldLine = line
			local pos, posEnd = line:find('[^%/]%/%*', 1)

			if (pos == nil) then
				if (line:find('%/%*', 1) == 1) then
					pos, posEnd = line:find('%/%*', 1)
				end
			end

			while pos do
				local pos2, posEnd2 = line:find('%*%/', posEnd + 1)

				if pos2 then
					line = line:sub(1, pos - 1)..line:sub(posEnd2 + 1, line:len())
					waitingForCommentEnd = false
				else
					line = line:sub(1, pos - 1)
					waitingForCommentEnd = true
				end

				pos, posEnd = line:find('[^%/]%/%*', 1)
			end
		end

		if line then
			linesC = linesC + 1
			lines[linesC] = line
		end

		rawLineNum = rawLineNum + 1
	end

	for index, line in pairs(lines) do
		local pos, posEnd = line:find('//[^!]')

		if pos then
			lines[index] = line:sub(1, pos - 1)
		end
	end

	local function getMacrosDefs()
		for i = 1, linesC, 1 do
			local line = lines[i]

			local pos, posEnd = line:find('//! textmacro')

			if pos then
				local name, pos, posEnd = line:readIdentifier(posEnd + 1)

				curMacro = {}

				curMacro.args = {}
				curMacro.lines = {}
				curMacro.name = name

				local pos, posEnd = line:find('takes', posEnd + 1)

				if pos then
					local name, pos, posEnd = line:readIdentifier(posEnd + 1)

					while name do
						curMacro.args[#curMacro.args + 1] = name

						name, pos, posEnd = line:readIdentifier(posEnd + 1)
					end
				end
print('macro', name)
				macros[name] = curMacro
			elseif line:find('//! endtextmacro') then
				curMacro = nil
				lines[i] = ''
			end

			if curMacro then
				curMacro.lines[#curMacro.lines + 1] = line

				lines[i] = ''
			end
		end
	end

	getMacrosDefs()

	lines = evalMacrosTable(lines)
	linesC = #lines

local collectedInputFile = io.open(io.local_dir()..'input.j', 'w+')

writeTable(collectedInputFile, lines)

collectedInputFile:close()

	methods = {}
	funcs = {}
	structs = {}
	injects = {}
	injectTargets = {}
	modules = {}
	moduleImplements = {}
	variables = {}
	staticIfs = {}
	staticIfElses = {}

	typeLists = {}

	typeLists['method'] = methods
	typeLists['func'] = funcs
	typeLists['struct'] = structs
	typeLists['inject'] = injects
	typeLists['injectTarget'] = injectTargets
	typeLists['module'] = modules
	typeLists['moduleImplement'] = moduleImplements
	typeLists['variable'] = variables
	typeLists['staticIf'] = staticIfs
	typeLists['staticIfElse'] = staticElses

	local blockNesting = {}
	local blockNestingDepth = 0
	local curBlock
	local curLine

	local linesPoolNesting = {}
	local linesPoolNestingDepth = 0

	local types = {}
	local typesByName = {}

	local function newType(t)
		types[#types + 1] = t
		typesByName[t] = t
	end

	t_null = {}

	newType(t_null)

	local function throwErrorIf(cond, conObjs, msg, ...)
		if not cond then
			return
		end

		print('ERROR:', string.format(msg, ...))

		for key, obj in pairs(conObjs) do
			if obj.pool then
				print('\t', string.format('%s: %s, line %s (%s)', key, obj.name or '?', obj.poolIndex or '?', obj.pool.name))
			else
				print('\t', string.format('%s: %s', key, obj.name or '?'))
			end

			local c = 2
			obj = obj.parent

			while (obj ~= nil) do
				if obj.pool then
					print(string.rep('\t', c), string.format('^-: %s, line %s (%s)', obj.name or '?', obj.poolIndex or '?', obj.pool.name))
				else
					print(string.rep('\t', c), string.format('^-: %s', obj.name))
				end

				obj = obj.parent
				c = c + 1
			end
		end

		print('ERROR end')
		error('')
	end

	function createElement(type, name, vis)
		assert(typesByName[type], 'unknown type'..tostring(type))

		local this = {}

		local pool = linesPoolNesting[linesPoolNestingDepth]

		if pool then
			this.pool = pool
			this.poolIndex = pool.iterator
		end

		this.nameKey = {}
		this.name = name or tostring(this.nameKey)
		this.type = type
		this.vis = vis

		this.getPath = function(this, source)
			if (source == nil) then
				source = root
			end

			local t = {}

			t[1] = this.name

			local this = this

			if this.parent then	
				while this.parent and (this.parent ~= source) do
					this = this.parent

					table.insert(t, 1, this.name)
				end

				if (this.parent == nil) then
					return
				end
			end

			return table.concat(t, '_')
		end

		this.path = this:getPath()

		this.moveTo = function(this, newParent, index, overwrite)
			local oldPath = this:getPath()
			local oldParent = this.parent

			if (oldParent == newParent) then
				return
			end

			if oldParent then
				oldParent.subList:removeByKey(this.name)

				this.parent = nil

				if this.name then
					if ((this.vis == 'private') or (this.vis == 'public')) then
						oldParent.privateTable[this.name] = nil
					end

					this.nameVis = nil
				end
			end

			if newParent then
				if overwrite then
					if newParent.subList:containsKey(this.name) then
						newParent.subList:getVal(this.name):moveTo(nil)
					end
				else
					throwErrorIf(newParent.subList:containsKey(this.name), {newParent = newParent, objName = this.name, obj = this}, 'newParent %s already has a member called %s', newParent.name, this.name)
				end

				newParent.subList:addAt(this, index, this.name)

				this.parent = newParent

				if this.name then
					if (this.vis == 'private') then
						this.nameVis = newParent.name..'__'..this.name
					elseif (this.vis == 'public') then
						this.nameVis = this.name--newParent.name..'_'..this.name
					else
						this.nameVis = this.name
					end

					if ((this.vis == 'private') or (this.vis == 'public')) then
						newParent.privateTable[this.name] = this.nameVis
					end
				end
			end

			this.path = this:getPath()
		end

		this.copy = function(this)
print('no copy for', this.type)
			return createElement(this.type, this.name, this.vis)
		end

		this.getCallPath = function(this, source)
			if (source == nil) then
				source = root
			end

			local t = {}

			t[1] = this.nameVis

			local this = this

			if this.parent then	
				while this.parent and (this.parent ~= source) do
					this = this.parent

					if (this.type == t_struct) then
						table.insert(t, 1, this.name..'_')
					elseif (this.type == t_scope) then
						table.insert(t, 1, this.name..'_')
					end
				end

				if (this.parent == nil) then
					return
				end
			end

			return table.concat(t, '')
		end

		this.rename = function(this, name)
			local parent = this.parent

			this.name = name

			if parent then
				local index = this.subList:getIndex(name)

				this:moveTo(nil)

				this:moveTo(parent, index)
			end
		end

		this.remove = function(this)
			this:moveTo(nil)

			local typeList = typeLists[this.type]

			if typeList then
				if this.name then
					typeList[this.name] = nil
				end

				for i = 1, #typeList, 1 do
					if (typeList[i] == this) then
						table.remove(typeList, i)
					end
				end
			end
		end

		return this
	end

	function createBlock(type, name, vis)
		assert(typesByName[type], 'unknown type '..tostring(type))

		local this = createElement(type, name, vis)

		this.privateTable = {}

		this.subList = module_dataStructures.createList()

		function this:addSub(sub, index)
			if (ntype(sub) == 'table') then
				sub:moveTo(this, index)
			end
		end

		function this:blockCopy(target)
			assert(target, 'no target')

			for _, sub in this.subList:iter() do
				sub = sub:copy()

				sub:moveTo(target)
			end
		end

		return this
	end

	local function openBlock(this)
		this.headerLine = curLine

		curBlock = this

		blockNestingDepth = blockNestingDepth + 1
		blockNesting[blockNestingDepth] = this
	end

	local function pushLine()
		local pool = linesPoolNesting[linesPoolNestingDepth]

		pool.iterator = pool.iterator + 1

		local i = pool.iterator

		--i = i + 1
		--line = lines[i]

		if (i > pool.linesC) then
			return
		end

		local line = pool.lines[i]

		if line:find('//[^!]') then
			line = line:sub(1, line:find('//[^!]') - 1)
		end

		line = line:trimStartWhitespace()

		curLine = line

		return line, i
	end

	local function closeBlock()
		curBlock.footerLine = curLine

		blockNestingDepth = blockNestingDepth - 1

		curBlock = blockNesting[blockNestingDepth]
	end

	local function scanLine(line, lineNumber, possibleTypes)
		local function scan()
			if possibleTypes then
				line = line:trimStartWhitespace()

				local isStatic
				local vis
				local startWord, pos, posEnd = line:readIdentifier()

				if startWord then
					while ((startWord == 'public') or (startWord == 'private') or (startWord == 'static')) do
						if (startWord == 'private') then
							vis = 'private'
						elseif (startWord == 'public') then
							vis = 'public'
						elseif (startWord == 'static') then
							isStatic = true
						end
	
						startWord, pos, posEnd = line:readIdentifier(posEnd + 1)
					end

					local line2 = line:sub(pos)
	
					local this

					for i = 1, #possibleTypes, 1 do
						this = possibleTypes[i](line2, startWord, vis, isStatic)

						if (this ~= nil) then
							return this
						end
					end
				end
			end

			return line
		end

		local result = scan()

		if (ntype(result) == 'table') then
			return result
		end

		if (ntype(result) == 'string') then
			return t_line.create(result)
		end

		if (result ~= true) then
			error('cannot associate type '..tostring(line)..';'..tostring(result))
		end
	end

	root = createBlock(t_null, 'root')

	t_line = {
		create = function(text)
			local this = createElement(t_line)

			this.headerLine = text

			function this:copy()
				return t_line.create(this.headerLine)
			end

			return this
		end
	}

	newType(t_line)

	function getFromPath(source, target)
		if (source == nil) then
			source = root
		end

		local t = target:split('%.')
		local this = source

		if not this.subList.containsKey(t[1]) then
			while (this and (this.name ~= t[1])) do
				this = this.parent
			end

			if (this == nil) then
				this = root
			else
				this = this.parent
			end
		end

		for i = 1, #t, 1 do
			this = this.subList:getVal(t[i])

			if (this == nil) then
				print(source.name)
				for i, sub in source.subList:iter() do
					print(i, '->', sub.name)
				end

				error('path '..t[i]..' of '..target..' not found')

				return
			end
		end

		return this
	end

	t_injectTarget = {
		create = function(name)
			local this = createBlock(t_injectTarget, name)

			injectTargets[#injectTargets + 1] = this
			injectTargets[name] = this

			function this:copy()
				local new = t_injectTarget.create(this.name)

				this:blockCopy(new)

				return new
			end

			return this
		end,

		scan = function(line, startWord)
			if (startWord ~= 'injectTarget') then
				return
			end

			local name = line:readIdentifier(startWord:len() + 1)

			local this = t_injectTarget.create(name)

			this:moveTo(curBlock)

			return this
		end
	}

	newType(t_injectTarget)

	t_inject = {
		create = function(target)
			local name = 'inject'..(#injects + 1)..': '..target

			local this = createBlock(t_inject, name)
	
			injects[#injects + 1] = this
			injects[name] = this
	
			this.target = target

			function this:copy()
				local new = t_inject.create(this.target)

				this:blockCopy(new)

				return new
			end

			return this
		end,

		scan = function(line, startWord)
			if (startWord ~= 'inject') then
				return
			end

			local target = line:readPath(startWord:len() + 1)

			if ((target == 'main') or (target == 'config')) then
				return
			end

			local this = t_inject.create(target)

			this:moveTo(curBlock)

			openBlock(this)

			local sub, subLineNumber = pushLine()

			while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endinject')) do
				this:addSub(scanLine(sub, subLineNumber, {t_inject.scan, t_method.scan, t_var.scan}))

				sub, subLineNumber = pushLine()
			end

			closeBlock()

			return this
		end
	}

	newType(t_inject)

	t_module = {
		create = function(name, vis)
			local this = createBlock(t_module, name, vis)
	
			modules[#modules + 1] = this
			modules[name] = this

			function this:copy()
				local new = t_module.create(this.name, this.vis)

				this:blockCopy(new)

				return new
			end

			return this
		end,

		scan = function(line, startWord, vis)
			if (startWord ~= 'module') then
				return
			end

			local name = line:readIdentifier(startWord:len() + 1)

			local this = t_module.create(name, vis)

			this:moveTo(curBlock)

			openBlock(this)

			local sub, subLineNumber = pushLine()

			while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endmodule')) do
				this:addSub(scanLine(sub, subLineNumber, {t_moduleImplement.scan, t_inject.scan, t_method.scan, t_var.scan}))

				sub, subLineNumber = pushLine()
			end

			closeBlock()

			return this
		end
	}

	newType(t_module)

	t_moduleImplement = {
		create = function(name, vis)
			local this = createBlock(t_moduleImplement, name, vis)

			moduleImplements[#moduleImplements + 1] = this
			moduleImplements[name] = this

			this.headerLine = [[//implement ]]..name
			this.footerLine = [[//endimplement ]]..name

			function this:copy()
				local new = moduleImplement.create(this.name, this.vis)

				this:blockCopy(new)

				return new
			end

			return this
		end,

		scan = function(line, startWord, vis)
			if (startWord ~= 'implement') then
				return
			end

			local name = line:readIdentifier(startWord:len() + 1)

			local this = t_moduleImplement.create(name, vis)

			this:moveTo(curBlock)

			return this
		end
	}

	newType(t_moduleImplement)

	t_func = {
		create = function(name, vis, isAutoExec, args, returnType)
			local this = createBlock(t_func, name, vis)

			this.isAutoExec = isAutoExec

			this.args = args
			this.returnType = returnType

			funcs[#funcs + 1] = this

			function this:copy()
				local new = func.create(this.name, this.vis, this.isAutoExec, this.args, this.returnType)

				this:blockCopy(new)

				return new
			end

			return this
		end,

		scan = function(line, startWord, vis)
			if (startWord ~= 'function') then
				return
			end

			local isAutoExec
			local pos, posEnd = line:find('%[autoExec%]')

			if pos then
				line = line:sub(1, pos - 1)..line:sub(posEnd + 1)

				isAutoExec = true
			end

			local funcName, pos, posEnd = line:readIdentifierEx(startWord:len() + 1)

			local lineAfterName = line:sub(posEnd + 1)

			local foundParams
			local pos, posEnd = lineAfterName:find('takes ')

			if pos then
				foundParams = true

				lineAfterName = lineAfterName:sub(posEnd + 1)
			end

			local pos, posEnd = lineAfterName:find('returns ')

			local paramsString
			local returnString

			if pos then
				paramsString = lineAfterName:sub(1, pos - 1)
				returnString = lineAfterName:sub(posEnd + 1)
			else
				paramsString = lineAfterName
				returnString = ''
			end

			local args = {}

			if foundParams then
				local name, pos, posEnd = paramsString:readIdentifier()
	
				if name then
					local posEnd = 0
	
					if (name ~= 'nothing') then
						local t = paramsString:split(',')
	
						for i = 1, #t, 1 do
							local index = #args + 1
	
							args[index] = {}
	
							name, pos, posEnd = paramsString:readIdentifier(posEnd + 1)
	
							args[index].type = name
	
							name, pos, posEnd = paramsString:readIdentifier(posEnd + 1)
	
							args[index].name = name
						end
					end
				end
			end

			local name, pos, posEnd = returnString:readIdentifier()

			local returnType

			if name then
				returnType = name
			end

			local this = t_func.create(funcName, vis, isAutoExec, args, returnType)

			this:moveTo(curBlock)

			openBlock(this)

			local sub, subLineNumber = pushLine()

			while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endfunction')) do
				scanLine(sub, subLineNumber, {}):moveTo(this)

				sub, subLineNumber = pushLine()
			end

			closeBlock()

			return this
		end
	}

	newType(t_func)

	t_method = {
		create = function(name, vis, isStatic, funcType, isAutoExec, args, returnType)
			local this = createBlock(t_method, name, vis)

			if (funcType == nil) then
				funcType = FUNC_TYPE_NORMAL
			end

			if (funcType.isStatic or isStatic) then
				this.isStatic = true
			end

			this.funcType = funcType

			this.isAutoExec = isAutoExec

			this.args = args
			this.returnType = returnType

			methods[#methods + 1] = this

			function this:copy()
				local new = t_method.create(this.name, this.vis, this.isStatic, this.funcType, this.isAutoExec, this.args, this.returnType)

				this:blockCopy(new)

				return new
			end

			return this
		end,

		scan = function(line, startWord, vis, isStatic)
			local funcType = funcTypesByStartWord[startWord]

			if (funcType == nil) then
				return
			end

			local isAutoExec
			local pos, posEnd = line:find('%[autoExec%]')

			if pos then
				line = line:sub(1, pos - 1)..line:sub(posEnd + 1)

				isAutoExec = true
			end

			local funcName, pos, posEnd

			if (funcType == FUNC_TYPE_OPERATOR) then
				funcName, pos, posEnd = line:readIdentifierEx(startWord:len() + 1)

				if (funcName == '<') then
					funcName = 'operator<'
				elseif (funcName == '>') then
					funcName = 'operator>'
				else
					error('operatorMethod '..funcName:quote()..' not recognized')
				end
			else
				funcName, pos, posEnd = line:readIdentifierEx(startWord:len() + 1)
			end

			local lineAfterName = line:sub(posEnd + 1)

			local foundParams
			local pos, posEnd = lineAfterName:find('takes ')

			if pos then
				foundParams = true

				lineAfterName = lineAfterName:sub(posEnd + 1)
			end

			local pos, posEnd = lineAfterName:find('returns ')

			local paramsString
			local returnString

			if pos then
				paramsString = lineAfterName:sub(1, pos - 1)
				returnString = lineAfterName:sub(posEnd + 1)
			else
				paramsString = lineAfterName
				returnString = ''
			end

			local args = {}

			if foundParams then
				local name, pos, posEnd = paramsString:readIdentifier()
	
				if name then
					local posEnd = 0
	
					if (name ~= 'nothing') then
						local t = paramsString:split(',')
	
						for i = 1, #t, 1 do
							local index = #args + 1
	
							args[index] = {}
	
							name, pos, posEnd = paramsString:readIdentifier(posEnd + 1)
	
							args[index].type = name
	
							name, pos, posEnd = paramsString:readIdentifier(posEnd + 1)
	
							args[index].name = name
						end
					end
				end
			end

			local name, pos, posEnd = returnString:readIdentifier()

			local returnType

			if name then
				returnType = name
			end

			local this = t_method.create(funcName, vis, isStatic, funcType, isAutoExec, args, returnType)

			this:moveTo(curBlock)

			openBlock(this)

			local sub, subLineNumber = pushLine()

			while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endmethod')) do
				scanLine(sub, subLineNumber, {t_injectTarget.scan}):moveTo(this)

				sub, subLineNumber = pushLine()
			end

			closeBlock()

			return this
		end
	}

	newType(t_method)

	local structSubTypes

	t_struct = {
		create = function(name, vis)
			local this = createBlock(t_struct, name, vis)

			structs[#structs + 1] = this

			local nameVar = t_var.create('NAME', nil)

			nameVar:moveTo(this)

			nameVar.isStatic = true
			nameVar.varType = 'string'
			nameVar.val = ('<'..name..'>'):quote()

			function this:copy()
				local new = struct.create(this.name, this.vis)

				this:blockCopy(new)

				return new
			end

			return this
		end,

		scan = function(line, startWord, vis)
			if (startWord ~= 'struct') then
				return
			end

			local name = line:readIdentifier(startWord:len() + 1)

			local this = t_struct.create(name, vis)

			this:moveTo(curBlock)

			if this.path then
				local refPath = this.path:gsub('_', '\\')
		
				refPath = refPath:split('\\')
	
				for k, v in pairs(refPath) do
					local pos, posEnd = v:find('Folder')
	
					if (pos == 1) then
						refPath[k] = v:sub(posEnd + 1)
					end
	
					local pos, posEnd = v:find('Struct')
	
					if (pos == 1) then
						refPath[k] = v:sub(posEnd + 1)
					end
				end
	
				refPath = table.concat(refPath, '\\')
		
				local targetPath = structLookupPaths[refPath]

				if targetPath then
					t_line.create('//import '..targetPath):moveTo(this)

					local f = io.open(targetPath, 'r')

					local lines = {}
	
					for line in f:lines() do
						lines[#lines + 1] = line
					end
	
					f:close()

					local pool = {}
				
					pool.iterator = 0
					pool.lines = lines
					pool.linesC = #lines
					pool.name = linesPoolNesting[linesPoolNestingDepth].name..'->'..targetPath

					scanLayout(pool, this, structSubTypes)

					t_line.create('//endimport '..targetPath):moveTo(this)
				end
			end

			openBlock(this)

			local sub, subLineNumber = pushLine()

			while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endstruct')) do
				this:addSub(scanLine(sub, subLineNumber, structSubTypes))

				sub, subLineNumber = pushLine()
			end

			closeBlock()

			return this
		end
	}

	newType(t_struct)

	t_scope = {
		create = function(name, vis)
			local this = createBlock(t_scope, name, vis)
	
			function this:copy()
				local new = scope.create(this.name, this.vis)

				this:blockCopy(new)

				return new
			end

			return this
		end,

		scan = function(line, startWord, vis)
			if (startWord ~= 'scope') then
				return
			end

			local name = line:readIdentifier(startWord:len() + 1)

			local this = t_scope.create(name, vis)

			this:moveTo(curBlock)

			openBlock(this)

			local sub, subLineNumber = pushLine()

			while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endscope')) do
				this:addSub(scanLine(sub, subLineNumber, {t_scope.scan, t_globals.scan, t_inject.scan, t_func.scan, t_struct.scan}))

				sub, subLineNumber = pushLine()
			end

			closeBlock()

			return this
		end
	}

	newType(t_scope)

	local headerScope = t_scope.create('HeaderScope')

	headerScope:moveTo(root)

	headerScope.headerLine = [[scope HeaderScope]]
	headerScope.footerLine = [[endscope]]

	t_line.create([[globals]]):moveTo(headerScope)

	local keywords = {}
	
	local function addKeyword(word)
		keywords[word] = word
	end

	addKeyword('endglobals')
	addKeyword('endfunction')
	addKeyword('endmethod')
	addKeyword('endmodule')
	addKeyword('endinject')
	addKeyword('endstruct')
	addKeyword('if')
	addKeyword('else')
	addKeyword('endif')
	addKeyword('call')
	addKeyword('set')

	t_var = {
		create = function(name, vis, varType, isArray, val, isStatic, isConstant)
			local this = createBlock(t_var, name, vis)

			this.varType = varType
			this.val = val
			this.isArray = isArray
			this.isStatic = isStatic
			this.isConstant = isConstant

			variables[#variables + 1] = this

			function this:copy()
				local new = t_var.create(this.name, this.vis, this.varType, this.isArray, this.val, this.isStatic, this.isConstant)

				this:blockCopy(new)

				return new
			end

			return this
		end,

		scan = function(line, startWord, vis, isStatic)
			if keywords[startWord] then
				return
			end

			local isArray
			local isConstant

			local name, pos, posEnd = line:readIdentifier()

			if (name == 'constant') then
				isConstant = true

				name, pos, posEnd = line:readIdentifier(posEnd + 1)
			end

			local varType = name

			name, pos, posEnd = line:readIdentifier(posEnd + 1)

			if (name == 'array') then
				isArray = true

				name, pos, posEnd = line:readIdentifier(posEnd + 1)
			end

			local pos, posEnd = line:find('=', posEnd)

			local val

			if pos then
				val = line:sub(posEnd + 1)
			end

			local this = t_var.create(name, vis, varType, isArray, val, isStatic, isConstant)

			this:moveTo(curBlock)

			return this
		end
	}

	newType(t_var)

	t_staticIf = {
		create = function(name, vis)
			local this = createBlock(t_staticIf, name, vis)
	
			staticIfs[#staticIfs + 1] = this
	
			return this
		end,

		createElse = function(name, vis)
			local this = createBlock(t_staticIfElse, name, vis)
	
			staticIfElses[#staticIfElses + 1] = this

			function this:copy()
				local new = staticIf.create(this.name, this.vis)

				this:blockCopy(new)

				return new
			end

			return this
		end,

		scan = function(line, startWord, vis, isStatic)
			if not isStatic then
				return
			end

			if (startWord ~= 'if') then
				return
			end

			local this = t_staticIf.create('staticIf#'..tostring(#staticIfs), vis) 

			this:moveTo(curBlock)

			openBlock(this)

			local ifPart = createBlock(t_null)

			ifPart:moveTo(this)

			local sub, subLineNumber = pushLine()

			while not ((ntype(sub) == 'string') and ((sub:readIdentifier() == 'endif') or (sub:readIdentifier() == 'else'))) do
				ifPart:addSub(scanLine(sub, subLineNumber, {t_inject.scan, t_method.scan, t_var.scan}))

				sub, subLineNumber = pushLine()
			end

			if (sub:readIdentifier() == 'else') then
				local elsePart = createBlock(t_null)

				elsePart:moveTo(this)

				while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endif')) do
					elsePart:addSub(scanLine(sub, subLineNumber, {t_inject.scan, t_method.scan, t_var.scan}))

					sub, subLineNumber = pushLine()
				end
			end

			closeBlock()

			return this
		end
	}

	newType(t_staticIf)

	t_globals = {
		scan = function(line, startWord, vis)
			if (startWord ~= 'globals') then
				return
			end

			local parent = curBlock

			t_line.create('globals'):moveTo(parent)

			local sub, subLineNumber = pushLine()

			while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endglobals')) do
				parent:addSub(scanLine(sub, subLineNumber, {t_var.scan}))

				sub, subLineNumber = pushLine()
			end

			t_line.create('endglobals'):moveTo(parent)

			return true
		end
	}

	newType(t_globals)

	structSubTypes = {t_struct.scan, t_moduleImplement.scan, t_inject.scan, t_staticIf.scan, t_method.scan, t_var.scan}

	scanLayout = function(pool, parent, subTypes)
		linesPoolNestingDepth = linesPoolNestingDepth + 1
		linesPoolNesting[linesPoolNestingDepth] = pool
	
		openBlock(parent)
	
		local sub, subLineNumber = pushLine()
	
		while sub do
			parent:addSub(scanLine(sub, subLineNumber, subTypes))

			sub, subLineNumber = pushLine()
		end
	
		closeBlock()
		
		linesPoolNestingDepth = linesPoolNestingDepth - 1
	end

	print('scanStructure')

	local pool = {}

	pool.iterator = 0
	pool.lines = lines
	pool.linesC = #lines
	pool.name = 'rootPool'

	local f = io.open(logsDir..'rootPool.txt', 'w+')

	writeTable(f, lines)

	f:close()

	scanLayout(pool, root, {t_globals.scan, t_scope.scan, t_struct.scan, t_inject.scan, t_module.scan, t_func.scan})

	print('end scanLayout')

	for i = 1, #moduleImplements, 1 do
		local this = moduleImplements[i]

		local name = this.name

		local module = modules[name]

		assert(module, 'module '..name..' not found')

		local parent = this.parent
--print(parent.name, 'implement', name)
		--this:moveTo(nil)
--print(i, #moduleImplements)
		module = module:copy()
--local f=io.open('impl.txt', 'w+')
--writeTable(f, module)
--f:close()
--osLib.pause()
		module:moveTo(parent, parent.subList:getIndex(this.name), true)

		module.headerLine = [[//implement ]]..name
		module.footerLine = [[//endimplement ]]..name
	end

	print('endC')

	for i = 1, #injects, 1 do
		local this = injects[i]

--print(this.parent.name, 'inject', this.target)
		local target = getFromPath(this.parent, this.target)

		assert(target, 'inject target '..this.target..' not found')

		local module = this:copy(target)

		module.headerLine = nil
		module.footerLine = nil

		target:addSub(module)

		this:moveTo(nil)
	end

	for i = 1, #injectTargets, 1 do
		local this = injectTargets[i]

		this.headerLine = nil
		this.footerLine = nil
	end

	print('endD')

	for i, sub in root.subList:iter() do
		local k = i
		local v = sub

		local privs = {}
	
		local function editLine(t)
			if (type(t) == 'string') then
				local name, pos, posEnd = t:readIdentifier()
	
				while name do
					local priv = privs[name]

					if priv then
						t = t:sub(1, pos - 1)..priv[#priv]..t:sub(posEnd + 1)
	
						posEnd = pos + priv[#priv]:len() - 1
					end
	
					name, pos, posEnd = t:readIdentifier(posEnd + 1)
				end
			end
	
			return t
		end
	
		local function unfoldSubs(parent, key, t, nestingDepth)
			if (ntype(t) == 'table') then
				if t.privateTable then
					for k2, v2 in pairs(t.privateTable) do
						if (privs[k2] == nil) then
							privs[k2] = {}
						end

						privs[k2][#privs[k2] + 1] = v2
					end
				end

				if t.headerLine then
					t.headerLine = editLine(t.headerLine)
				end	

				if t.subList then
					for i, sub in t.subList:iter() do
						unfoldSubs(t, i, sub, nestingDepth + 1)
					end
				end

				if t.footerLine then
					t.footerLine = editLine(t.footerLine)
				end

				if t.privateTable then
					for k2, v2 in pairs(t.privateTable) do
						privs[k2][#privs[k2]] = nil

						if (#privs[k2] == 0) then
							privs[k2] = nil
						end
					end
				end
			else
				parent.subList:setVal(key, editLine(t))
			end
		end
	
		unfoldSubs(root, k, v, 0)
	end

	print('endE')

	for i = 1, #structs, 1 do
		local k = i
		local struct = structs[i]

		local parent = struct.parent

		assert(parent, 'struct '..tostring(struct.name)..' has no parent')

		while (parent.type == t_struct) do
			struct:moveTo(nil)
			
			local oldName = struct.name

			struct:rename(parent.name..'_'..struct.name)
print(oldName, '->', struct.name)
			struct:moveTo(parent.parent, parent.parent.subList:getIndex(parent.name))

			t_line.create(struct.path..[[ ]]..oldName..[[ = this]]):moveTo(parent, 1)
			t_line.create(struct.path..[[ LinkToStruct_]]..oldName):moveTo(parent, 2)

			parent = parent.parent
		end
	end

	print('endF')

	for i = 1, #structs, 1 do
		local k = i
		local struct = structs[i]
	
		local t = {}

		if struct.vis then
			table.insert(t, struct.vis)
		end
	
		table.insert(t, 'struct')
	
		table.insert(t, struct.nameVis)

		struct.headerLine = table.concat(t, ' ')
	end

	print('endG')

	local function editVariable(var)
		local t = {}
	
		if var.isStatic then
			table.insert(t, 'static')
		end
	
		if var.isConstant then
			table.insert(t, 'constant')
		end
	
		table.insert(t, var.varType)
	
		if var.isArray then
			table.insert(t, 'array')
		end
	
		table.insert(t, var.nameVis)
	
		if var.val then
			table.insert(t, ' = '..var.val)
		end

		var.headerLine = table.concat(t, ' ')
	end

	print('endH')

	for i = 1, #variables, 1 do
		local k = i
		local var = variables[i]

		editVariable(var)
	end

	for i = 1, #funcs, 1 do
		local k = i
		local func = funcs[i]

		local type = func.funcType
	
		local paramsString
	
		if (#func.args == 0) then
			paramsString = 'nothing'
		else
			local t = {}
	
			for i = 1, #func.args, 1 do
				t[i] = func.args[i].type..' '..func.args[i].name
			end
	
			paramsString = table.concat(t, ', ')
		end
	
		local returnTypeString
	
		if (func.returnType == nil) then
			returnTypeString = 'nothing'
		else
			returnTypeString = func.returnType
		end
	
		local prefixes = {}
	
		local prefix
	
		if (#prefixes > 0) then
			prefix = table.concat(prefixes, ' ')..' '
		else
			prefix = ''
		end
	
		func.headerLine = prefix..'function '..func.nameVis..' takes '..paramsString..' returns '..returnTypeString

		if func.isAutoExec then
			t_line.create([[//autoExec]]):moveTo(func, 1)
		end
	end

	local function editMethod(func)
		if func.isAutoExec then
			if false then
			local name = func.name
			local vis = func.vis

			func:rename(name..'_autoExec_final')

			local evalFunc = method.create(name, vis)

			evalFunc:moveTo(func.parent, func.parent.subList:getIndex(func.name) + 1)

			local evalTargetFunc = method.create(name..'_autoExec_evalTarget', 'private')

			evalTargetFunc:moveTo(func.parent, func.parent.subList:getIndex(func.name) + 1)

			evalFunc.isStatic = func.isStatic
			evalTargetFunc.isStatic = true

			local typeC = {}
			local paramsT = {}

			local t = copyTable(func.args)

			if not evalFunc.isStatic then
				local thisParam = {}

				thisParam.name = 'this'
				thisParam.type = 'integer'

				table.insert(t, 1, thisParam)
			end

			for i = 1, #t, 1 do
				local type = t[i].type

				if typeC[type] then
					typeC[type] = typeC[type] + 1
				else
					typeC[type] = 0
				end

				local varName = 'autoExec_arg_'..type..typeC[type]

				local var = headerScope.subList:getVal(varName)

				if (var == nil) then
					var = createVariable(headerScope, nil, varName)

					var.varType = type

					editVariable(var)
				end

				t_line.create([[set ]]..var.name..[[ = ]]..t[i].name):moveTo(evalFunc)

				paramsT[#paramsT + 1] = varName
			end

			t_line.create([[call Code.Run(function thistype.]]..evalTargetFunc.nameVis..[[)]]):moveTo(evalFunc)

			if func.returnType then
				local varName = 'autoExec_result_'..func.returnType

				local var = headerScope.subList:getVal(varName)

				if (var == nil) then
					var = createVariable(headerScope, nil, varName)

					var.varType = func.returnType

					editVariable(var)
				end

				t_line.create([[set ]]..var.name..[[ = ]]..func.nameVis..[[(]]..table.concat(paramsT, ',')..[[)]]):moveTo(evalTargetFunc)
			else
				t_line.create([[call ]]..func.nameVis..[[(]]..table.concat(paramsT, ',')..[[)]]):moveTo(evalTargetFunc)
			end

			editMethod(evalFunc)
			editMethod(evalTargetFunc)
			end
		end

		local type = func.funcType

		local paramsString
	
		if (#func.args == 0) then
			paramsString = 'nothing'
		else
			local t = {}
	
			for i = 1, #func.args, 1 do
				t[i] = func.args[i].type..' '..func.args[i].name
			end
	
			paramsString = table.concat(t, ', ')
		end
	
		local returnTypeString
	
		if (func.returnType == nil) then
			returnTypeString = 'nothing'
	
			if type.forceTrueReturn then
				returnTypeString = 'boolean'
			else
				returnTypeString = 'nothing'
			end
		else
			returnTypeString = func.returnType
		end
	
		local prefixes = {}
	
		if func.isStatic then
			prefixes[#prefixes + 1] = 'static'
		end
	
		local prefix
	
		if (#prefixes > 0) then
			prefix = table.concat(prefixes, ' ')..' '
		else
			prefix = ''
		end
	
		if (type == FUNC_TYPE_INIT) then
			local pos, posEnd = func.headerLine:find(' of ')

			assert(pos, func:getPath()..' has no loading part')
	
			local partName, pos, posEnd = func.headerLine:readIdentifier(posEnd + 1)
	
			partName = partName:upper()
	
			local part = loadingParts[partName]
	
			if (part == nil) then
				part = {}

				part.inits = {}
				part.name = partName

				loadingParts[#loadingParts + 1] = part
				loadingParts[partName] = part
			end

			part.inits[#part.inits + 1] = func
	
			t_line.create([[static method initializer_]]..func.nameVis..[[_autoRun takes nothing returns nothing]]):moveTo(func.parent)
			t_line.create([[call Loading.AddInit_]]..partName..[[(function thistype.]]..func.nameVis..[[, ]]..func:getPath():quote()..[[)]]):moveTo(func.parent)
			t_line.create([[endmethod]]):moveTo(func.parent)
	
			loadingsTotal = loadingsTotal + 1
		end
	
		func.headerLine = prefix..'method '..func.nameVis..' takes '..paramsString..' returns '..returnTypeString
	
		if func.isAutoExec then
			t_line.create([[//autoExec]]):moveTo(func, 1)
		end
	
		if (type == FUNC_TYPE_INIT) then
			--t_line.create([[local ObjThread t = ObjThread.Create("initMethod " + thistype.]]..func.nameVis..[[.name)]]):moveTo(func, 1)
			--t_line.create([[call t.Destroy()]]):moveTo(func)
		end
	
		if (type == FUNC_TYPE_DESTROY) then
			t_line.create([[if this.allocation_destroyed then]]):moveTo(func, 1)
			t_line.create('\t'..[[return]]):moveTo(func, 2)
			t_line.create([[endif]]):moveTo(func, 3)

			t_line.create([[set this.allocation_destroyed = true]]):moveTo(func, 4)

			t_line.create([[call this.subRef()]]):moveTo(func)
		end
	
		if type.includeParams then
			t_line.create([[local EventResponse params = EventResponse.GetTrigger()]]):moveTo(func, 1)
		end
	
		if type.forceTrueReturn then
			for _, val in func.subList:iter() do
				local line = val.headerLine

				if (line:gsub(' ', ''):gsub('\t', '') == 'return') then
					val.headerLine = [[return true]]
				end
			end

			t_line.create([[return true]]):moveTo(func)
		end

		func.footerLine = [[endmethod]]
	end

	print('endI')

	for i = 1, #methods, 1 do
		local k = i
		local func = methods[i]

		editMethod(func)
	end

	print('endJ')

	local function raiseLocalVars(t)
		for i = 1, #t, 1 do
			local func = t[i]
	
			local firstNonLocal
	
			local t2 = {}
	
			for _, val in func.subList:iter() do
				t2[#t2 + 1] = val
			end

			for i2 = 1, #t2, 1 do
				local sub = t2[i2]

				if (ntype(sub) == 'table') then
					if (sub.type == t_line) then
						local line = sub.headerLine

						local name, pos, posEnd = line:readIdentifier()

						if name then
							if firstNonLocal then
								if (name == 'local') then
									local t = {'local'}

									local type, pos, posEnd = line:readIdentifier(posEnd + 1)

									table.insert(t, type)

									local name, pos, posEnd = line:readIdentifier(posEnd + 1)

									if (name == 'array') then
										table.insert(t, 'array')

										name, pos, posEnd = line:readIdentifier(posEnd + 1)
									end

									table.insert(t, name)

									if line:find('=') then
										sub.headerLine = 'set '..line:sub(pos)
									else
										sub:remove(nil)
									end

									t_line.create(table.concat(t, ' ')):moveTo(func, firstNonLocal)
	
									firstNonLocal = firstNonLocal + 1
								end
							else
								if not (name == 'local') then
									firstNonLocal = i2
								end
							end
						end
					end
				end
			end
		end
	end

	raiseLocalVars(methods)
	raiseLocalVars(funcs)

	print('endK ', collectgarbage('count'))

	for key, val in root.subList:iter() do
		local function editLine(parent, t)
			if (type(t) == 'string') then
				t = t:gsub([[//! import]], [[///! import]])

				t = t:gsub(' %/ ', ' *1. / ')
				t = t:gsub(' div ', ' / ')

				local parentPathQ = parent:getPath():gsub([["]], [[\"]])
				local lineQ = t:gsub([["]], [[\"]])

				local pathQ = (parentPathQ..': '..lineQ)

				t = t:gsub('Event%.Create%(', [[Event.Create(]]..pathQ:quote()..[[, ]])
				t = t:gsub('Event%.CreateLimit%(', [[Event.CreateLimit(]]..pathQ:quote()..[[, ]])
				t = t:gsub('UnitList%.Create%(%)', [[UnitList.Create(]]..pathQ:quote()..[[)]])
				t = t:gsub('DebugEx%(', string.format([[DebugEx(%s, %s, ]], parentPathQ:quote(), lineQ:quote()))

				local name, pos, posEnd = t:readIdentifier()

				while name do
					if (name == 'allocate') then
						t = t:sub(1, pos - 1)..'allocCustom'..t:sub(posEnd + 1)

						posEnd = pos + string.len('allocCustom') - 1
					elseif (name == 'deallocate') then
						t = t:sub(1, pos - 1)..'deallocCustom'..t:sub(posEnd + 1)

						posEnd = pos + string.len('deallocCustom') - 1
					end
				
					name, pos, posEnd = t:readIdentifier(posEnd + 1)
				end
				
				local name, pos, posEnd = t:readIdentifier()
				
				if (name == 'initLoad') then
					local name, pos, posEnd = t:readIdentifier(posEnd + 1)

					name = name:upper()

					local part = loadingParts[name]
			
					if (part == nil) then
						part = {}
		
						part.inits = {}
						part.name = name

						loadingParts[#loadingParts + 1] = part
						loadingParts[name] = part
					end

					t = [[call Loading.RunInits_]]..name..[[()]]
				end
			end

			return t
		end
	
		local function unfoldSubs(parent, key, t, nestingDepth)
			if (ntype(t) == 'table') then
				if t.headerLine then
					t.headerLine = editLine(parent, t.headerLine)
				end

				if t.subList then
					for k, v in t.subList:iter() do
						unfoldSubs(t, k, v, nestingDepth + 1)
					end
				end

				if t.footerLine then
					t.footerLine = editLine(parent, t.footerLine)
				end
			else
				parent.subList:setVal(key, editLine(parent, t))
			end
		end
	
		unfoldSubs(root, key, val, 0)
	end

	print('endL', collectgarbage('count'))

	t_line.create([[endglobals]]):moveTo(headerScope)

	local testoutMethods = io.open(logsDir..[[testout_methods.j]], 'w+')
	
	local lines = {}
	
	for _, sub in root.subList:iter() do	
		local function unfoldSubs(t, nestingDepth)
			if (ntype(t) == 'table') then
				if t.headerLine then
					testoutMethods:write('\n', string.rep('\t', nestingDepth), t.headerLine)
					lines[#lines + 1] = string.rep('\t', nestingDepth)..t.headerLine
				end

				if t.subList then
					for _, v in t.subList:iter() do
						unfoldSubs(v, nestingDepth + 1)
					end
				end

				if t.footerLine then
					testoutMethods:write('\n', string.rep('\t', nestingDepth), t.footerLine)
					lines[#lines + 1] = string.rep('\t', nestingDepth)..t.footerLine
				end
			else
				testoutMethods:write('\n', string.rep('\t', nestingDepth), t)
				lines[#lines + 1] = string.rep('\t', nestingDepth)..t
			end
		end
	
		unfoldSubs(sub, 0)
	end

	testoutMethods:close()

	print('wrote file')

	return lines
end

local lines = compileScript()

--print('after compile')
--checkMethods()

local function addLine(line)
	local t = evalMacros(line)

	for i = 1, #t, 1 do
		lines[#lines + 1] = t[i]
	end
end

local t = {logsDir = logsDir, addLine = addLine, loadingParts = loadingParts}

loadfile(io.local_dir()..'tail.lua')(t)

local output = io.open(io.local_dir()..'output.j', 'w+')

print(#lines)

for i = 1, #lines, 1 do
	output:write(lines[i]..'\n')
end

output:close()

copyFile(io.local_dir()..'output.j', outputPath, true)

print(#lines)
print('finished in '..(os.clock() - time)..'seconds')