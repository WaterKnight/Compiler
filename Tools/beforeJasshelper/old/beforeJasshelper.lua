require 'waterlua'

osLib.clearScreen()
osLib.pause()

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

local input = io.local_open(inputPath, 'r')

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
	addJ(v)
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

	local function throwErrorIf(cond, conObjs, msg, ...)
		if not cond then
			return
		end

		print('error', string.format(msg, ...))

		for i = 1, #conObjs, 1 do
			local obj = conObjs[i]

			print(string.format('obj%i: %s, line %s', i, obj.name or '?', obj.poolIndex or '?'))
		end

		error('error thrown')
	end

	function createElement(parent, type, name, vis)
	end

	function createBlock(parent, index, type, name, vis)
		local this = {}

		local pool = linesPoolNesting[linesPoolNestingDepth]
--print('create block', name)
		this.name = name
		if pool then
			this.pool = pool
			this.poolIndex = pool.iterator
		end
		this.privateTable = {}
		this.subs = {}
		this.type = type
		this.vis = vis
if parent and this.name=='Allocation' then
log(parent.name..' -> '..this.name)
end
		this.subList = module_dataStructures.createList()

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

		this.rename = function(this, name)
			local index = this.parentIndex
			local parent = this.parent

			this:moveTo(nil)

			this.name = name

			if index then
				index = index - 1
			end

			this:moveTo(parent, index)
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

					if (this.type == 'struct') then
						table.insert(t, 1, this.name..'_')
					elseif (this.type == 'scope') then
						table.insert(t, 1, this.name..'_')
					end
				end

				if (this.parent == nil) then
					return
				end
			end

			return table.concat(t, '')
		end

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

		this.addSub = function(this, sub, index)
			--[[if (sub == nil) then
				return
			end

			this.subList:add(sub)
			--this.subs[#this.subs + 1] = sub
	
			if sub.vis and sub.name then
				if ((sub.vis == 'private') or (sub.vis == 'public')) then
					this.privateTable[sub.name] = sub.nameVis
				end
			end]]
			if (ntype(sub) == 'table') then
				sub:moveTo(this, index)
			end
		end
	
		this.moveTo = function(this, newParent, index, overwrite)
			local oldPath = this:getPath()
			local oldParent = this.parent

			if (oldParent == newParent) then
				return
			end

			if oldParent then
				local index = this.parentIndex

				--for i = index + 1, #oldParent.subs, 1 do
				--	oldParent.subs[i].parentIndex = i - 1
				--end

				oldParent.subList:remove(this)
				--table.remove(oldParent.subs, index)
				if this.name then
					oldParent.subs[this.name] = nil
				end

				this.parent = nil
				this.parentIndex = nil

				if this.name then
					if ((this.vis == 'private') or (this.vis == 'public')) then
						oldParent.privateTable[this.name] = nil
					end

					this.nameVis = nil
				end
			end

			if newParent then
				if not overwrite then
					throwErrorIf(newParent.subs[this.name], {newParent, newParent.subs[this.name], this}, 'newParent %s already has a member called %s', newParent.name, this.name)
				end

				if this.name then
					if newParent.subs[this.name] then
						newParent.subs[this.name]:moveTo(nil)
					end
				end
	
				if (index == nil) then
					--index = #newParent.subs + 1
				else
					--for i = index, #newParent.subs, 1 do
					--	newParent.subs[i].parentIndex = i + 1
					--end
				end

				newParent.subList:addAt(this, index)
				--table.insert(newParent.subs, index, this)

				if this.name then
					if newParent.subs[this.name] then
						error(newParent.name..' already has a sub '..this.name:quote())
					end

					newParent.subs[this.name] = this
				end

				this.parent = newParent
				this.parentIndex = index

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

		if parent then
			this:moveTo(parent, index)
		end

		this.copy = function(this, newParent, index, overwrite)
			local parent = this.parent
	
			this.parent = nil
	
			local result = copyTable(this)

			this.parent = parent

			local function unfoldSubs(t, nestingDepth)
				if (ntype(t) == 'table') then	
					local member = t.subList.head

					while (member ~= nil) do
						unfoldSubs(member, nestingDepth + 1)

						member = t.subList.memberNext[member]
					end

					--for i = 1, #t.subs, 1 do
					--	unfoldSubs(t.subs[i], nestingDepth + 1)
					--end

					--for i = 1, #t.subs, 1 do
					--	unfoldSubs(t.subs[i], nestingDepth + 1)
					--end
	
					if typeLists[t.type] then
						table.insert(typeLists[t.type], t)
					end
				end
			end
		
			unfoldSubs(result, 0)
	
			--table.insert(typeLists[result.type], result)

			result:moveTo(newParent, index, overwrite)

			return result
		end

		return this
	end
	
	root = createBlock(nil, nil, nil, 'root')
	
	function createLine(parent, index, text)
		local this = createBlock(parent, index, 'line')

		this.headerLine = text

		return this
	end
	
	function getFromPath(source, target)
		if (source == nil) then
			source = root
		end

		local t = target:split('%.')
		local this = source

		if (this.subs[t[1]] == nil) then
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
			this = this.subs[t[i]]

			if (this == nil) then
				print(source.name)
				for i = 1, #source.subs, 1 do
					print(i, '->', source.subs[i].name)
				end

				error('path '..t[i]..' of '..target..' not found')

				return
			end
		end

		return this
	end
	
	function createInjectTarget(parent, index, name)
		local this = createBlock(parent, index, 'injectTarget', name)
	
		injectTargets[#injectTargets + 1] = this
		injectTargets[name] = this
	
		return this
	end
	
	function createInject(parent, index, target)
		local name = 'inject'..(#injects + 1)..': '..target

		local this = createBlock(parent, index, 'inject', name)
	
		injects[#injects + 1] = this
		injects[name] = this
	
		this.target = target
	
		return this
	end
	
	function createModule(parent, index, name, vis)
		local this = createBlock(parent, index, 'module', name, vis)
	
		modules[#modules + 1] = this
		modules[name] = this
	
		return this
	end
	
	function createModuleImplement(parent, index, name, vis)
		local this = createBlock(parent, index, 'moduleImplement', name, vis)
	
		moduleImplements[#moduleImplements + 1] = this
		moduleImplements[name] = this

		this.headerLine = [[//implement ]]..name
		this.footerLine = [[//endimplement ]]..name
	
		return this
	end
	
	function createFunction(parent, index, name, vis)
		local this = createBlock(parent, index, 'function', name, vis)
	
		this.params = {}
	
		funcs[#funcs + 1] = this
	
		return this
	end
	
	function createMethod(parent, index, name, vis)
		local this = createBlock(parent, index, 'method', name, vis)
	
		this.params = {}

		this.funcType = FUNC_TYPE_NORMAL

		methods[#methods + 1] = this

		return this
	end

	local structSubTypes

	function createStruct(parent, index, name, vis)
		local this = createBlock(parent, index, 'struct', name, vis)

		structs[#structs + 1] = this

		local nameVar = createVariable(this, nil, 'NAME', nil)

		nameVar.isStatic = true
		nameVar.varType = 'string'
		nameVar.val = ('<'..name..'>'):quote()

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
				createLine(this, nil, '//import '..targetPath)

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

				scanStructure(pool, this, structSubTypes)

				createLine(this, nil, '//endimport '..targetPath)
			end
		end

		return this
	end
	
	function createScope(parent, index, name, vis)
		local this = createBlock(parent, index, 'scope', name, vis)
	
		return this
	end

	local headerScope = createScope(root, nil, 'HeaderScope')

	headerScope.headerLine = [[scope HeaderScope]]
	headerScope.footerLine = [[endscope]]

	createLine(headerScope, nil, [[globals]])

	keywords = {}
	
	function addKeyword(word)
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

	function createVariable(parent, index, name, vis)
		local this = createBlock(parent, index, 'variable', name, vis)
	
		variables[#variables + 1] = this

		return this
	end
	
	function createStaticIf(parent, index, name, vis)
		local this = createBlock(parent, index, 'staticIf', name, vis)
	
		staticIfs[#staticIfs + 1] = this
	
		return this
	end

	function createStaticIfElse(parent, index, name, vis)
		local this = createBlock(parent, index, 'staticIfElse', name, vis)
	
		staticIfElses[#staticIfElses + 1] = this
	
		return this
	end

	testoutPre=io.open(logsDir..[[testoutPre.txt]], 'w+')
	
	testoutPre:write(table.concat(lines, '\n'))
	
	testoutPre:close()
	
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
	
	local function openBlock(this)
		this.headerLine = curLine

		curBlock = this

		blockNestingDepth = blockNestingDepth + 1
		blockNesting[blockNestingDepth] = this
	end

	local function closeBlock()
		curBlock.footerLine = curLine

		blockNestingDepth = blockNestingDepth - 1

		curBlock = blockNesting[blockNestingDepth]
	end

	scanFuncs = {}

	function getScanFuncName(func)
		return scanFuncs[func]
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

						if this then
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
			return createLine(curBlock, nil, result)
		end
	end

	local function scanInjectTarget(line, startWord)
		if (startWord ~= 'injectTarget') then
			return
		end

		local name = line:readIdentifier(startWord:len() + 1)

		local this = createInjectTarget(curBlock, nil, name)

		return this
	end

	local function scanFunction(line, startWord, vis)
		if (startWord ~= 'function') then
			return
		end

		local isAutoExec
		local pos, posEnd = line:find('%[autoExec%]')

		if pos then
			line = line:sub(1, pos - 1)..line:sub(posEnd + 1)

			isAutoExec = true
		end

		local name, pos, posEnd = line:readIdentifierEx(startWord:len() + 1)

		local this = createFunction(curBlock, nil, name, vis)

		openBlock(this)

		this.isAutoExec = isAutoExec

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

		if foundParams then
			local name, pos, posEnd = paramsString:readIdentifier()
	
			if name then
				local posEnd = 0
	
				if (name ~= 'nothing') then
					local t = paramsString:split(',')
	
					for i = 1, #t, 1 do
						local index = #this.params + 1
	
						this.params[index] = {}
	
						name, pos, posEnd = paramsString:readIdentifier(posEnd + 1)
	
						this.params[index].type = name
	
						name, pos, posEnd = paramsString:readIdentifier(posEnd + 1)
	
						this.params[index].name = name
					end
				end
			end
		end

		local name, pos, posEnd = returnString:readIdentifier()

		if name then
			this.returnType = name
		end

		local sub, subLineNumber = pushLine()

		while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endfunction')) do
			scanLine(sub, subLineNumber, {}):moveTo(this)

			sub, subLineNumber = pushLine()
		end

		closeBlock()

		return this
	end

	local function scanMethod(line, startWord, vis, isStatic)
		local type = funcTypesByStartWord[startWord]

		if (type == nil) then
			return
		end

		local isAutoExec
		local pos, posEnd = line:find('%[autoExec%]')

		if pos then
			line = line:sub(1, pos - 1)..line:sub(posEnd + 1)

			isAutoExec = true
		end

		local name, pos, posEnd

		if (type == FUNC_TYPE_OPERATOR) then
			name, pos, posEnd = line:readIdentifierEx(startWord:len() + 1)

			if (name == '<') then
				name = 'operator<'
			elseif (name == '>') then
				name = 'operator>'
			else
				error('operatorMethod '..name:quote()..' not recognized')
			end
		else
			name, pos, posEnd = line:readIdentifierEx(startWord:len() + 1)
		end

		local this = createMethod(curBlock, nil, name, vis)

		openBlock(this)

		this.isAutoExec = isAutoExec
		this.funcType = type

		if (type.isStatic or isStatic) then
			this.isStatic = true
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

		if foundParams then
			local name, pos, posEnd = paramsString:readIdentifier()
	
			if name then
				local posEnd = 0
	
				if (name ~= 'nothing') then
					local t = paramsString:split(',')
	
					for i = 1, #t, 1 do
						local index = #this.params + 1
	
						this.params[index] = {}
	
						name, pos, posEnd = paramsString:readIdentifier(posEnd + 1)
	
						this.params[index].type = name
	
						name, pos, posEnd = paramsString:readIdentifier(posEnd + 1)
	
						this.params[index].name = name
					end
				end
			end
		end

		local name, pos, posEnd = returnString:readIdentifier()

		if name then
			this.returnType = name
		end

		local sub, subLineNumber = pushLine()

		while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endmethod')) do
			scanLine(sub, subLineNumber, {scanInjectTarget}):moveTo(this)

			sub, subLineNumber = pushLine()
		end

		closeBlock()

		return this
	end

	local function scanVariable(line, startWord, vis, isStatic)
		if keywords[startWord] then
			return
		end

		local parent = curBlock

		local isArray
		local isConstant

		local name, pos, posEnd = line:readIdentifier()

		if (name == 'constant') then
			isConstant = true

			name, pos, posEnd = line:readIdentifier(posEnd + 1)
		end

		local type = name

		name, pos, posEnd = line:readIdentifier(posEnd + 1)

		if (name == 'array') then
			isArray = true

			name, pos, posEnd = line:readIdentifier(posEnd + 1)
		end

		local this = createVariable(parent, nil, name, vis)

		this.isArray = isArray
		this.isConstant = isConstant
		this.isStatic = isStatic
		this.varType = type

		local pos, posEnd = line:find('=', posEnd)

		if pos then
			this.val = line:sub(posEnd + 1)
		end

		return this
	end

	local function scanGlobals(line, startWord, vis)
		if (startWord ~= 'globals') then
			return
		end

		local parent = curBlock

		createLine(parent, nil, 'globals')

		local sub, subLineNumber = pushLine()

		while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endglobals')) do
			parent:addSub(scanLine(sub, subLineNumber, {scanVariable}))

			sub, subLineNumber = pushLine()
		end

		createLine(parent, nil, 'endglobals')

		return true
	end

	local function scanInject(line, startWord)
		if (startWord ~= 'inject') then
			return
		end

		local target = line:readPath(startWord:len() + 1)

		if ((target == 'main') or (target == 'config')) then
			return
		end

		local this = createInject(curBlock, nil, target)

		openBlock(this)

		local sub, subLineNumber = pushLine()

		while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endinject')) do
			this:addSub(scanLine(sub, subLineNumber, {scanInject, scanMethod, scanVariable}))

			sub, subLineNumber = pushLine()
		end

		closeBlock()

		return this
	end

	local function scanModuleImplement(line, startWord, vis)
		if (startWord ~= 'implement') then
			return
		end

		local name = line:readIdentifier(startWord:len() + 1)

		local this = createModuleImplement(curBlock, nil, name, vis)

		return this
	end

	local function scanModule(line, startWord, vis)
		if (startWord ~= 'module') then
			return
		end

		local name = line:readIdentifier(startWord:len() + 1)

		local this = createModule(curBlock, nil, name, vis)

		openBlock(this)

		local sub, subLineNumber = pushLine()

		while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endmodule')) do
			this:addSub(scanLine(sub, subLineNumber, {scanModuleImplement, scanInject, scanMethod, scanVariable}))

			sub, subLineNumber = pushLine()
		end

		closeBlock()

		return this
	end

	local function scanStaticIf(line, startWord, vis, isStatic)
		if not isStatic then
			return
		end

		if (startWord ~= 'if') then
			return
		end

		local this = createStaticIf(curBlock, nil, 'staticIf#'..tostring(#staticIfs), vis) 

		openBlock(this)

		local ifPart = createBlock(this)

		local sub, subLineNumber = pushLine()

		while not ((ntype(sub) == 'string') and ((sub:readIdentifier() == 'endif') or (sub:readIdentifier() == 'else'))) do
			ifPart:addSub(scanLine(sub, subLineNumber, {scanInject, scanMethod, scanVariable}))

			sub, subLineNumber = pushLine()
		end

		if (sub:readIdentifier() == 'else') then
			local elsePart = createBlock(this)

			while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endif')) do
				elsePart:addSub(scanLine(sub, subLineNumber, {scanInject, scanMethod, scanVariable}))

				sub, subLineNumber = pushLine()
			end
		end

		closeBlock()

		return this
	end

	local function scanStruct(line, startWord, vis)
		if (startWord ~= 'struct') then
			return
		end

		local name = line:readIdentifier(startWord:len() + 1)

		local this = createStruct(curBlock, nil, name, vis)

		openBlock(this)

		local sub, subLineNumber = pushLine()

		while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endstruct')) do
			this:addSub(scanLine(sub, subLineNumber, structSubTypes))

			sub, subLineNumber = pushLine()
		end

		closeBlock()

		return this
	end

	structSubTypes = {scanStruct, scanModuleImplement, scanInject, scanStaticIf, scanMethod, scanVariable}

	local function scanScope(line, startWord, vis)
		if (startWord ~= 'scope') then
			return
		end

		local name = line:readIdentifier(startWord:len() + 1)

		local this = createScope(curBlock, nil, name, vis)

		openBlock(this)

		local sub, subLineNumber = pushLine()

		while not ((ntype(sub) == 'string') and (sub:readIdentifier() == 'endscope')) do
			this:addSub(scanLine(sub, subLineNumber, {scanScope, scanGlobals, scanInject, scanFunction, scanStruct}))

			sub, subLineNumber = pushLine()
		end

		closeBlock()

		return this
	end

	scanFuncs[scanFunction] = 'scanFunction'
	scanFuncs[scanGlobals] = 'scanGlobals'
	scanFuncs[scanVariable] = 'scanVariable'
	scanFuncs[scanMethod] = 'scanMethod'
	scanFuncs[scanModule] = 'scanModule'
	scanFuncs[scanModuleImplement] = 'scanModuleImplement'
	scanFuncs[scanInject] = 'scanInject'
	scanFuncs[scanScope] = 'scanScope'
	scanFuncs[scanStruct] = 'scanStruct'
	scanFuncs[scanStaticIf] = 'scanStaticIf'

	scanStructure = function(pool, parent, subTypes)
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

	fileWriteTable(f, lines, '\n')

	f:close()

	scanStructure(pool, root, {scanGlobals, scanScope, scanStruct, scanInject, scanModule, scanFunction})

	print('end scanStructure')

	for i = 1, #moduleImplements, 1 do
		local this = moduleImplements[i]

		local name = this.name

		local module = modules[name]

		assert(module, 'module '..name..' not found')

		local parent = this.parent
		local parentIndex = this.parentIndex
print(parent.name, 'implement', name)
		--this:moveTo(nil)

		module = module:copy(parent, parentIndex, true)

		module.headerLine = [[//implement ]]..name
		module.footerLine = [[//endimplement ]]..name
	end

	print('endC')

	for i = 1, #injects, 1 do
		local this = injects[i]

print(this.parent.name, 'inject', this.target)
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

	for i = 1, #root.subs, 1 do
		local k = i
		local v = root.subs[i]

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
				for k2, v2 in pairs(t.privateTable) do
					if (privs[k2] == nil) then
						privs[k2] = {}
					end

					privs[k2][#privs[k2] + 1] = v2
				end

				if t.headerLine then
					t.headerLine = editLine(t.headerLine)
				end	
	
				for i = 1, #t.subs, 1 do
					unfoldSubs(t, i, t.subs[i], nestingDepth + 1)
				end
	
				if t.footerLine then
					t.footerLine = editLine(t.footerLine)
				end
	
				for k2, v2 in pairs(t.privateTable) do
					privs[k2][#privs[k2]] = nil

					if (#privs[k2] == 0) then
						privs[k2] = nil
					end
				end
			else
				parent.subs[key] = editLine(t)
			end
		end
	
		unfoldSubs(root, k, v, 0)
	end

	for i = 1, #structs, 1 do
		local k = i
		local struct = structs[i]

		local parent = struct.parent

		assert(parent, 'struct '..tostring(struct.name)..' has no parent')

		while (parent.type == 'struct') do
			struct:moveTo(nil)
			
			local oldName = struct.name
			
			struct:rename(parent.name..'_'..struct.name)

			struct:moveTo(parent.parent, parent.parentIndex)
			
--[[local parentIndex = struct:getParentIndex()

table.remove(parent.subs, parentIndex)
parent.subs[struct.name] = nil

table.insert(parent.parent.subs, parent:getParentIndex(), struct)
parent.parent.subs[struct.name] = struct

struct.parent = parent.parent
struct:rename(parent.name..'_'..struct.name)]]

			createLine(parent, 1, struct.path..[[ ]]..oldName..[[ = this]])
			createLine(parent, 2, struct.path..[[ LinkToStruct_]]..oldName)
	
			parent = parent.parent
		end
	end

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
	
		if (#func.params == 0) then
			paramsString = 'nothing'
		else
			local t = {}
	
			for i = 1, #func.params, 1 do
				t[i] = func.params[i].type..' '..func.params[i].name
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
			createLine(func, 1, [[//autoExec]])
		end
	end

	local function editMethod(func)
		if func.isAutoExec then
			if false then
			local name = func.name
			local vis = func.vis

			func:rename(name..'_autoExec_final')

			local evalFunc = createMethod(func.parent, func.parentIndex + 1, name, vis)
			local evalTargetFunc = createMethod(func.parent, func.parentIndex + 1, name..'_autoExec_evalTarget', 'private')

			evalFunc.isStatic = func.isStatic
			evalTargetFunc.isStatic = true

			local typeC = {}
			local paramsT = {}

			local t = copyTable(func.params)

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

				local var = headerScope.subs[varName]

				if (var == nil) then
					var = createVariable(headerScope, nil, varName)

					var.varType = type

					editVariable(var)
				end

				createLine(evalFunc, nil, [[set ]]..var.name..[[ = ]]..t[i].name)

				paramsT[#paramsT + 1] = varName
			end

			createLine(evalFunc, nil, [[call Code.Run(function thistype.]]..evalTargetFunc.nameVis..[[)]])

			if func.returnType then
				local varName = 'autoExec_result_'..func.returnType

				local var = headerScope.subs[varName]

				if (var == nil) then
					var = createVariable(headerScope, nil, varName)

					var.varType = func.returnType

					editVariable(var)
				end

				createLine(evalTargetFunc, nil, [[set ]]..var.name..[[ = ]]..func.nameVis..[[(]]..table.concat(paramsT, ',')..[[)]])
			else
				createLine(evalTargetFunc, nil, [[call ]]..func.nameVis..[[(]]..table.concat(paramsT, ',')..[[)]])
			end

			editMethod(evalFunc)
			editMethod(evalTargetFunc)
			end
		end

		local type = func.funcType

		local paramsString
	
		if (#func.params == 0) then
			paramsString = 'nothing'
		else
			local t = {}
	
			for i = 1, #func.params, 1 do
				t[i] = func.params[i].type..' '..func.params[i].name
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
	
			createLine(func.parent, nil, [[static method initializer_]]..func.nameVis..[[_autoRun takes nothing returns nothing]])
			createLine(func.parent, nil, [[call Loading.AddInit_]]..partName..[[(function thistype.]]..func.nameVis..[[, ]]..func:getPath():quote()..[[)]])
			createLine(func.parent, nil, [[endmethod]])
	
			loadingsTotal = loadingsTotal + 1
		end
	
		func.headerLine = prefix..'method '..func.nameVis..' takes '..paramsString..' returns '..returnTypeString
	
		if func.isAutoExec then
			createLine(func, 1, [[//autoExec]])
		end
	
		if (type == FUNC_TYPE_INIT) then
			--createLine(func, 1, [[local ObjThread t = ObjThread.Create("initMethod " + thistype.]]..func.nameVis..[[.name)]])
			--createLine(func, nil, [[call t.Destroy()]])
		end
	
		if (type == FUNC_TYPE_DESTROY) then
			createLine(func, 1, [[if this.allocation_destroyed then]])
			createLine(func, 2, '\t'..[[return]])
			createLine(func, 3, [[endif]])

			createLine(func, 4, [[set this.allocation_destroyed = true]])

			createLine(func, nil, [[call this.subRef()]])
		end
	
		if type.includeParams then
			createLine(func, 1, [[local EventResponse params = EventResponse.GetTrigger()]])
		end
	
		if type.forceTrueReturn then
			for i = 1, #func.subs, 1 do
				local line = func.subs[i].headerLine

				if (line:gsub(' ', ''):gsub('\t', '') == 'return') then
					func.subs[i].headerLine = [[return true]]
				end
			end

			createLine(func, nil, [[return true]])
		end

		func.footerLine = [[endmethod]]
	end

	for i = 1, #methods, 1 do
		local k = i
		local func = methods[i]

		editMethod(func)
	end

	local function raiseLocalVars(t)
		for i = 1, #t, 1 do
			local func = t[i]
	
			local firstNonLocal
			local c = #func.subs
	
			local t = {}
	
			for i = 1, #func.subs, 1 do
				t[i] = func.subs[i]
			end
	
			for i = 1, #t, 1 do
				local sub = t[i]
	
				if (ntype(sub) == 'table') then
					if (sub.type == 'line') then
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
	
									createLine(func, firstNonLocal, table.concat(t, ' '))
	
									firstNonLocal = firstNonLocal + 1
								end
							else
								if not (name == 'local') then
									firstNonLocal = i
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

	for i = 1, #root.subs, 1 do
		local k = i
		local v = root.subs[i]

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
				t = t:gsub('DebugEx%(', [[DebugEx(]]..parentPathQ:quote()..[[, ]]..lineQ:quote()..[[, ]])

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

				for i = 1, #t.subs, 1 do
					unfoldSubs(t, i, t.subs[i], nestingDepth + 1)
				end

				if t.footerLine then
					t.footerLine = editLine(parent, t.footerLine)
				end
			else
				parent.subs[key] = editLine(parent, t)
			end
		end
	
		unfoldSubs(root, k, v, 0)
	end

	createLine(headerScope, nil, [[endglobals]])

	local testoutMethods = io.open(logsDir..[[testout_methods.j]], 'w+')
	
	local lines = {}
	
	for i = 1, #root.subs, 1 do
		local sub = root.subs[i]
	
		local function unfoldSubs(t, nestingDepth)
			if (ntype(t) == 'table') then
				if t.headerLine then
					testoutMethods:write('\n', string.rep('\t', nestingDepth), t.headerLine)
					lines[#lines + 1] = string.rep('\t', nestingDepth)..t.headerLine
				end
	
				for i = 1, #t.subs, 1 do
					unfoldSubs(t.subs[i], nestingDepth + 1)
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

addLine([[
struct Loading
	static integer LOADING_PARTS_AMOUNT = 0
]])

local f = io.open(logsDir..[[loadingParts.txt]], 'w+')

for i = 1, #loadingParts, 1 do
	local part = loadingParts[i]

	local name = part.name

	addLine([[
		static trigger array LOADING_PARTS_OF_]]..name..[[   
		static integer LOADING_PARTS_OF_]]..name..[[_COUNT = ARRAY_EMPTY

		static integer array LOADING_PARTS_OF_]]..name..[[_CODE_ID
		static string array LOADING_PARTS_OF_]]..name..[[_NAME

		static method AddInit_]]..name..[[ takes code c, string name returns nothing
			set LOADING_PARTS_OF_]]..name..[[_COUNT = LOADING_PARTS_OF_]]..name..[[_COUNT + 1
			set LOADING_PARTS_OF_]]..name..[[[LOADING_PARTS_OF_]]..name..[[_COUNT] = CreateTrigger()

			set LOADING_PARTS_OF_]]..name..[[_CODE_ID[LOADING_PARTS_OF_]]..name..[[_COUNT] = Code.GetId(c)
			set LOADING_PARTS_OF_]]..name..[[_NAME[LOADING_PARTS_OF_]]..name..[[_COUNT] = name

			call TriggerAddCondition(LOADING_PARTS_OF_]]..name..[[[LOADING_PARTS_OF_]]..name..[[_COUNT], Condition(c))
		endmethod

		static method RunInits_]]..name..[[_LabelTrig takes nothing returns boolean
			//call Loading.Load(]]..name:quote()..[[, 0)

			return true
		endmethod

		static method RunInits_]]..name..[[ takes nothing returns boolean
			local integer iteration = LOADING_PARTS_OF_]]..name..[[_COUNT

			loop
				exitwhen (iteration < ARRAY_MIN)

				call Loading.Queue(LOADING_PARTS_OF_]]..name..[[[iteration], LOADING_PARTS_OF_]]..name..[[_CODE_ID[iteration], LOADING_PARTS_OF_]]..name..[[_NAME[iteration])

				set iteration = iteration - 1
			endloop

			return true
		endmethod
	]])

	f:write('\n'..name)

	for i = 1, #part.inits, 1 do
		f:write('\n\t'..part.inits[i]:getPath())
	end
end

f:close()

addLine([[
    static string array DUMMY_STRINGS
    static real DURATION
    static boolean ENDING = false

    static method Ending2 takes nothing returns nothing
        set thistype.ENDING = true
        call FogEnable(true)
        call FogMaskEnable(true)
        call ResetToGameCamera(0.)
        call ResetTerrainFog()
        call SetCameraField(CAMERA_FIELD_FARZ, 5000., 0.)
        call DisplayCineFilter(false)

        call EnableUserUI(true)

        call InfoEx("finished loading in " + R2S(thistype.DURATION) + " seconds")

        call PauseGame(false)
    endmethod

    static method Ending takes nothing returns nothing
        call SetCameraField(CAMERA_FIELD_FARZ, 0., 0.)

        call SetCineFilterBlendMode(BLEND_MODE_BLEND)
        call SetCineFilterTexMapFlags(TEXMAP_FLAG_NONE)
        call SetCineFilterDuration(Initialization.START_DELAY - 1.)
        call SetCineFilterEndColor(255, 255, 255, 0)
        call SetCineFilterStartColor(255, 255, 255, 255)
        call SetCineFilterEndUV(0, 0, 1, 1)
        call SetCineFilterStartUV(0, 0, 1, 1)
        call SetCineFilterTexture("UI\\LoadingScreenBackground.blp")

        call DisplayCineFilter(true)

        call ShowInterface(true, Initialization.START_DELAY - 1.)
    endmethod

    static constant real HEIGHT = 10000.

    static method UpdateCam_Exec takes nothing returns nothing
        call SetTerrainFogEx(0, thistype.HEIGHT, thistype.HEIGHT, 0, 0, 0, 0)
        call SetCameraField(CAMERA_FIELD_FARZ, thistype.HEIGHT, 0.)

        loop
            exitwhen thistype.ENDING

            call SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, 270., 0.)
            call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, 1650., 0.)
            call SetCameraField(CAMERA_FIELD_ZOFFSET, thistype.HEIGHT, 0.)

            call TriggerSleepAction(0.035)
        endloop
    endmethod

    static integer LOADING_PARTS_AMOUNT_PER_PERCENT
    //! runtextmacro CreateQueue("QUEUED")
    static timer QUEUE_TIMER

    implement Allocation
    implement Name

    integer codeId
    string name
    trigger trig

    static method Queue_Exec takes nothing returns nothing
        local integer cur
        local integer i = thistype.LOADING_PARTS_AMOUNT_PER_PERCENT
        local integer max
        local thistype this

        if thistype.QUEUED_IsEmpty() then
            return
        endif

        loop
            exitwhen thistype.QUEUED_IsEmpty()

            set this = thistype.QUEUED_FetchFirst()

            call IncStack(this.codeId)

            if not TriggerEvaluate(this.trig) then
                call DebugEx("LoadingQueue", "Queue_Exec", "could not finish init: " + this.name)
            endif

            call DecStack()

            //call DestroyTrigger(this.trig)

            set this.trig = null

            set i = i - 1
            exitwhen (i < 1)
        endloop

        set cur = thistype.LOADING_PARTS_AMOUNT - thistype.QUEUED_Amount()
        set max = thistype.LOADING_PARTS_AMOUNT

        call SetCinematicScene(0, null, "Please wait for the map to initialize...", I2S(cur) + "/" + I2S(max) + " assets loaded" + Char.BREAK + I2S(R2I(cur * 100. / max)) + Char.PERCENT, 999, 0)

        if thistype.QUEUED_IsEmpty() then
            call PauseTimer(thistype.QUEUE_TIMER)
        endif
    endmethod

    static method Queue takes trigger t, integer codeId, string name returns nothing
        local thistype this = thistype.allocCustom()

        set thistype.LOADING_PARTS_AMOUNT = thistype.LOADING_PARTS_AMOUNT + 1

	set this.codeId = codeId
        set this.name = name
        set this.trig = t

        call thistype.QUEUED_Add(this)
    endmethod

    static method QueueCode takes code c returns nothing
        local string name = LoadStr(FUNCS_TABLE, Code.GetId(c), 0)
        local trigger t = CreateTrigger()

        set thistype.LOADING_PARTS_AMOUNT = thistype.LOADING_PARTS_AMOUNT + 1

        call TriggerAddCondition(t, Condition(c))

        if (name == null) then
            set name = "unknown"
        endif

        call thistype.Queue(t, Code.GetId(c), name)

        set t = null
    endmethod

    static method IsSinglePlayer takes nothing returns boolean
        local gamecache gc = InitGameCache("singlePlayerCheck")
        local boolean result

        call StoreBoolean(gc, "blub", "moo", true)

        set result = SaveGameCache(gc)

        call FlushGameCache(gc)

        set gc = null

        return result
    endmethod

    static method IsSinglePlayer2 takes nothing returns boolean
        local integer c = 0
        local integer i = 15

        loop
            exitwhen (i < 0)

            if ((GetPlayerController(Player(i)) == MAP_CONTROL_USER) and (GetPlayerSlotState(Player(i)) == PLAYER_SLOT_STATE_PLAYING)) then
                set c = c + 1
            endif

            set i = i - 1
        endloop

        return (c < 2)
    endmethod

    static method ExecQueue_Exec takes nothing returns nothing
        local integer amount = thistype.QUEUED_Amount()
        local integer userCount

        if (amount <= 0) then
            return
        endif

        set thistype.LOADING_PARTS_AMOUNT = amount
        set thistype.LOADING_PARTS_AMOUNT_PER_PERCENT = R2I(amount / 100.)

        if IsSinglePlayer() then
            call InfoEx("singlePlayer")
            call PauseGame(true)

            loop
                exitwhen thistype.ENDING

                call ExecuteFunc(thistype.Queue_Exec.name)
                call ExecuteFunc(thistype.Queue_Exec.name)
                call ExecuteFunc(thistype.Queue_Exec.name)
                call ExecuteFunc(thistype.Queue_Exec.name)
                call ExecuteFunc(thistype.Queue_Exec.name)

                call TriggerSleepAction(0)
            endloop
        else
            call TimerStart(thistype.QUEUE_TIMER, 1. / 12, true, function thistype.Queue_Exec)
        endif
    endmethod

    static method ExecQueue takes nothing returns nothing
        call ExecuteFunc(thistype.ExecQueue_Exec.name)
    endmethod

    static method WaitLoop takes nothing returns nothing
        set thistype.DURATION = 0

        loop
            exitwhen thistype.ENDING

            call TriggerSleepAction(1)

            set thistype.DURATION = thistype.DURATION + 1
        endloop
    endmethod

    static method Start takes nothing returns nothing
        local real camX = GetCameraTargetPositionX()
        local real camY = GetCameraTargetPositionY()
        local real z = 3900.

        call EnableUserUI(false)
        call ShowInterface(false, 1)

        call SetCineFilterBlendMode(BLEND_MODE_BLEND)
        call SetCineFilterTexMapFlags(TEXMAP_FLAG_NONE)
        call SetCineFilterDuration(0)
        call SetCineFilterEndColor(255, 255, 255, 255)
        call SetCineFilterStartColor(255, 255, 255, 255)
        call SetCineFilterEndUV(0, 0, 1, 1)
        call SetCineFilterStartUV(0, 0, 1, 1)
        call SetCineFilterTexture("UI\\LoadingScreenBackground.blp")

        call DisplayCineFilter(true)

        call FogEnable(false)
        call FogMaskEnable(false)
//        call SetCameraBounds(camX, camY, camX, camY, camX, camY, camX, camY)

        call ExecuteFunc(thistype.UpdateCam_Exec.name)
        call ExecuteFunc(thistype.WaitLoop.name)
    endmethod

    static method Init takes nothing returns nothing
        set thistype.QUEUE_TIMER = CreateTimer()
    endmethod
endstruct
]])

--initFuncs
addLine([[
struct InitCommon
	static method onInit takes nothing returns nothing
		local ObjThread t = ObjThread.Create("InitCommon")
]])

addLine([[
		call t.Destroy()
	endmethod
endstruct
]])

addLine([[
	globals
		hashtable FUNCS_TABLE
	endglobals
]])

local output = io.open(outputPath, 'w+')

print(#lines)

for i = 1, #lines, 1 do
	output:write(lines[i]..'\n')
end

output:close()

print(#lines)
print('finished in '..(os.clock() - time)..'seconds')