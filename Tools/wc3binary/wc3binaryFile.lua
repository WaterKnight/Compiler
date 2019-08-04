--wc3binaryFile.lua

require 'waterlua'

io.local_require('miscLib')

wc3binaryFile = {}

function wc3binaryFile.create()
	local this = {}

	local MODE_READING = {
		name = 'reading'
	}

	local MODE_WRITING = {
		name = 'writing'
	}

	local curMode

	local types = {}
	local typeByName = {}

	local function createType(name, size, defVal)
		local this = {
			name = name,
			size = size,
			sizeBit = size * 8,
			defVal = defVal
		}

		types[this] = this
		typeByName[name] = this

		return this
	end

	this.getTypeByName = function(name)
		return typeByName[name]
	end

	local function byteHasBit(num, bit)
		return ((floor(num / pow2(bit - 1)) % 2) == 1)
	end

	local function byteGetBit(num, bit)
		if byteHasBit(num, bit) then
			return 1
		end

		return 0
	end

	local function byteEraseBit(num, bit)
		if byteHasBit(num, bit) then
			return (num - pow2(bit - 1))
		end

		return num
	end

	local function byteAddBit(num, bit)
		if byteHasBit(num, bit) then
			return num
		end

		return (num + pow2(bit - 1))
	end

	local function byteSetBit(num, bit, val)
		if (nilTo0(val) ~= 0) then
			return byteAddBit(num, bit)
		else
			return byteEraseBit(num, bit)
		end
	end

	local function paramsToString(...)
		local arg = {...}
		local result
		local n = select('#', ...)

		for c = 1, n, 1 do
			local v = arg[c]

			if result then
				result = result..', '
			else
				result = ''
			end

			if (ntype(v) == 'string') then
				result = result..tostring(v):quote()
			else
				result = result..tostring(v)
			end
		end

		return '('..result..')'
	end

	local function checkMethodCaller(self)
		if (ntype(self) == 'table') then
			return
		end

		error(debug.getinfo(2).name..': tried to call without a subject, check if you used the "." operator instead of ":"')
	end

	function this:getFullPath()
		checkMethodCaller(self)

		local string result = self.name

		local parent = self.parent

		while parent do
			result = parent.name..'\\'..result

			parent = parent.parent
		end

		return result
	end

	function this:getSub(name)
		checkMethodCaller(self)

		if (name == nil) then
			error('try to access field with nil name')

			return nil
		end

		local sub = self.subsByName[name]

		if (sub == nil) then
			error('field '..name:quote()..' does not exist under node '..self:getFullPath():quote())

			return nil
		end

		return sub
	end

	function this:getVal()
		checkMethodCaller(self)

		return self.val
	end

	function this:getValFromNode(name)
		checkMethodCaller(self)

		local sub = self:getSub(name)

		if (sub == nil) then
			error('getValFromNode - there is no field '..name:quote()..' under node '..self:getFullPath():quote())

			return nil
		end

		local result = sub:getVal()

		return result
	end

	function this:setVal(val)
		checkMethodCaller(self)

		local type = self.type

		local setFunc = type.setFunc

		if setFunc then
			local inputVal = val

			val = setFunc(val)

			if (val == nil) then
				error('cannot set field '..self:getFullPath():quote()..' to <'..tostring(inputVal)..'> ('..type.name..')')

				return
			end
		end

		self.val = val
	end

	function this:setValFromNode(name, val)
		checkMethodCaller(self)

		local sub = self:getSub(name)

		if (sub == nil) then
			error('setValFromNode - there is no field '..name:quote()..' under node '..self:getFullPath():quote())

			return
		end

		sub:setVal(val)
	end

	function this:clear()
		checkMethodCaller(self)

		self.subs = {}
		self.subsCount = 0
		self.subsByName = {}
	end

	local function addBits(field, bits)
		local node = field.parent
		local type = field.type

		local size = type.sizeBit

		field.bits = {}

		local maxBit = 0

		for bit in pairs(bits) do
			if (bit > maxBit) then
				maxBit = bit
			end
		end

		for bit = 1, maxBit, 1 do
			local name = bits[bit]

			if name then
				bit = tonumber(bit)

				if ((bit == nil) or (bit ~= floor(bit))) then
					error('addBits - '..tostring(bit):quote()..' is not a valid flag index (must be integer)')

					return
				end

				if ((bit < 1) or (bit > size)) then
					error('addBits - index '..bit..' is out of bounds for type '..type.name..' (should be within 1-'..size..')')

					return
				end

				if (ntype(name) ~= 'string') then
					error('addBits - '..tostring(name)..' is no string')

					return
				end

				local sub = node.subsByName[name]

				if sub then
					if (sub.posVals == nil) then
						error('addBits - try to redeclare field '..sub:getFullPath():quote())

						return
					end

					sub.posValsCount = sub.posValsCount + 1
					sub.posVals[bit] = sub.posValsCount
				else
					sub = {
						name = name,
						posValsCount = 1,
						posVals = {[bit] = 1},
						val = 0,

						getFullPath = this.getFullPath,
						getVal = this.getVal,
						setVal = this.setVal
					}

					node.subsCount = node.subsCount + 1
					node.subs[node.subsCount] = sub
					node.subsByName[name] = sub
				end

				field.bits[bit] = sub
			end
		end
	end

	local function addData(parent, name, type, bits)
		if ((name == nil) or (type == nil)) then
			error('no name/type passed to add '..paramsToString(name, type))

			return
		end

		if (types[type] == nil) then
			error('try to add with invalid type '..paramsToString(name, type))

			return
		end

		local sub = {
			name = name,
			parent = parent,
			type = type,

			getFullPath = this.getFullPath,
			getVal = this.getVal,
			setVal = this.setVal,

			rename = this.rename
		}

		parent.subsCount = parent.subsCount + 1
		parent.subs[parent.subsCount] = sub
		parent.subsByName[name] = sub

		if bits then
			addBits(sub, bits)
		end

		return sub
	end

	local curReadPos
	local input
	local inputString

	local function readFromInput(offset)
--nprint('curReadPos', curReadPos, input[curReadPos + offset])
		return input[curReadPos + offset]
	end

	local function readFromInputString(a, b)
		return inputString:sub(curReadPos + a, curReadPos + b)
	end

	local function readBits(field, fillFrom)
		--fillTo = ((curReadPos - 1) - 1) * 8

		local bits = field.bits

		for bit, name in pairs(bits) do
			--bits[bit].val = bits[bit].val + inputBits[fillTo - floor((bit - 1) / 8) * 8 + bit] * pow2(bits[bit].posVals[bit] - 1)

			bits[bit].val = bits[bit].val + byteGetBit(input[fillFrom + floor((bit - 1) / 8)], (bit - 1) % 8 + 1) * pow2(bits[bit].posVals[bit] - 1)
		end
	end

	local function read(field)
		if (field == nil) then
			error('no field passed to read '..paramsToString(field))

			return
		end

		local type = field.type

		local readFunc = type.readFunc
		local val

		if readFunc then
			local bits = field.bits

			if bits then
				--readBits(field, curReadPos)

				local size = type.size

				if (size > 0) then
					for bit, name in pairs(bits) do
						local byteIndex = curReadPos + floor((bit - 1) / 8)

						bits[bit].val = bits[bit].val + byteGetBit(input[byteIndex], (bit - 1) % 8 + 1) * pow2(bits[bit].posVals[bit] - 1)

						input[byteIndex] = byteEraseBit(input[byteIndex], (bit - 1) % 8 + 1)
					end

					--[[local fillTo = curReadPos + size - 1
					for i = curReadPos, fillTo, 1 do
						local byteOffset = (i - 1) * 8
						local val = input[i]

						for i2 = 1, 8, 1 do
							local rest = val % 2

							val = (val - rest) / 2
							inputBits[byteOffset + i2] = rest
						end
					end]]
				end
			end

			val, posInc = readFunc()

			if (val == nil) then
				error('no '..type.name..' '..field.name:quote()..' at pos '..(curReadPos - 1)..' (0x'..format('%X', curReadPos - 1)..')', true)

				if posInc then
					curReadPos = curReadPos + posInc
				else
					curReadPos = curReadPos + type.size
				end

				field.val = type.defVal
			else
				if posInc then
					curReadPos = curReadPos + posInc
				else
					curReadPos = curReadPos + type.size
				end

				field.val = val
			end
		end

		return sub
	end

	local output
	local outputCount
	local tmpOutput
	local tmpOutputCount

	local function writeToTmp(val)
		tmpOutputCount = tmpOutputCount + 1

		tmpOutput[tmpOutputCount] = val
	end

	local function writeToOutput(val)
		outputCount = outputCount + 1

		output[outputCount] = val
	end

	local function writeBits(field)
		local bits = field.bits

		for bit, name in pairs(bits) do
			local byteIndex = floor((bit - 1) / 8) + 1

			local val = tmpOutput[byteIndex]:byte()

			tmpOutput[byteIndex] = char(byteSetBit(val, (bit - 1) % 8 + 1, byteGetBit(val, bit) + byteGetBit(bits[bit].val, bits[bit].posVals[bit])))
		end
	end

	local function write(field)
		if (field == nil) then
			error('no field passed to write '..paramsToString(field))

			return
		end

		local type = field.type

		local writeFunc = type.writeFunc

		if writeFunc then
			local val = field.val

			if (val == nil) then
				error('could not write '..field:getFullPath():quote()..', replace by default value', true)

				val = type.defVal
			end

			tmpOutput = {}
			tmpOutputCount = 0

			writeFunc(val)
--nprint('write', field.name, field.type.name, val)
			if field.bits then
				writeBits(field)
			end

			for i = 1, tmpOutputCount, 1 do
--nprint(tmpOutput[i]:byte())
				writeToOutput(tmpOutput[i])
			end
		end

		return field
	end

	function this:add(name, type, bits)
		checkMethodCaller(self)

		local result

		if (types[type] == nil) then
			local typeName = typeByName[type]

			if (typeName == nil) then
				error('cannot add incorrect type '..paramsToString(name, type))

				return
			else
				type = typeName
			end
		end

		if (curMode == MODE_READING) then
			result = addData(self, name, type, bits)

			read(result)
		elseif (curMode == MODE_WRITING) then
			result = self:getSub(name)

			write(result)
		else
			result = addData(self, name, type, bits)
		end

		return result
	end

	function this:addNode(name)
		checkMethodCaller(self)

		if (name == nil) then
			error('addNode - no name passed')

			return
		end

		if (curMode == MODE_WRITING) then
			local result = self:getSub(name)

			return result
		end

		local parent = self
		local sub = {
			name = name,
			parent = parent,

			add = this.add,
			addNode = this.addNode,
			clear = this.clear,
			rename = this.rename,
			getSub = this.getSub,
			getVal = this.getValFromNode,
			setVal = this.setValFromNode,
			getFullPath = this.getFullPath,
			print = this.print,
			readFromFile = this.readFromFile,
			writeToFile = this.writeToFile,

			subs = {},
			subsCount = 0,
			subsByName = {}
		}

		parent.subsCount = parent.subsCount + 1
		parent.subs[parent.subsCount] = sub
		parent.subsByName[name] = sub

		return sub
	end

	function this:rename(name)
		checkMethodCaller(self)

		if (name == nil) then
			error('rename - no name passed')

			return
		end

		local parent = self.parent

		if (parent == nil) then
			self.name = name

			return
		end

		parent.subsByName[self.name] = nil

		parent.subsByName[name] = self

		self.name = name
	end

	function this:print(firstArg)
		checkMethodCaller(self)

		if ((firstArg == nil) or isInt(firstArg)) then
			local maxBeforePause = firstArg
			local maxBeforePauseC = 1

			local function printSubs(parent, nestDepth)
				local function writeLine(s)
					nprint(rep('\t', nestDepth)..s)
				end

				if parent.subs then
					for i = 1, parent.subsCount, 1 do
						local sub = parent.subs[i]

						if (maxBeforePauseC == maxBeforePause) then
							maxBeforePauseC = 1
							os.execute('pause')
							os.execute('cls')
						else
							maxBeforePauseC = maxBeforePauseC + 1
						end

						if sub.val then
							writeLine(sub.name..' --> '..tostring(sub.val))
						else
							writeLine(sub.name)
						end

						printSubs(sub, nestDepth + 1)
					end
				end
			end

			printSubs(self, 0)
		elseif (ntype(firstArg) == 'string') then
			local f = io.open(firstArg, 'w+')

			if (f == nil) then
				error('print - could not write to path '..firstArg:quote())

				return
			end

			local c = 0

			local function countSubs(parent)
				if parent.subs then
					for i = 1, parent.subsCount, 1 do
						c = c + 1

						countSubs(parent.subs[i])
					end
				end
			end

			countSubs(self)

			local loadDisplay = createLoadPercDisplay(c + 1, 'printing values...')
			local t = os.clock()

			local tmp = {}
			local tmpCount = 0

			local function printSubs(parent, nestDepth)
				local function writeLine(s)
					tmpCount = tmpCount + 1
					tmp[tmpCount] = rep('\t', nestDepth)..s..'\n'
				end

				if parent.subs then
					for i = 1, parent.subsCount, 1 do
						local sub = parent.subs[i]

						if sub.val then
							writeLine(sub.name..' --> '..tostring(sub.val))
						else
							writeLine(sub.name)
						end

						loadDisplay:inc()

						printSubs(sub, nestDepth + 1)
					end
				end
			end

			printSubs(self, 0)

			if (tmpCount > 0) then
				local packSize = 7500

				for i = 1, tmpCount / packSize + 1, 1 do
					f:write(unpack(tmp, (i - 1) * packSize + 1, min(i * packSize, tmpCount)))
				end
			end

			f:close()

			loadDisplay:inc()

			nprint('printed '..firstArg:quote()..' in '..(os.clock() - t)..' seconds')
		else
			error('print - first argument must be either integer or string')
		end
	end

	function this:readFromFile(path, maskFunc)
		checkMethodCaller(self)

		self:clear()

		local t = os.clock()

		if (ntype(maskFunc) ~= 'function') then
			error('reading from file needs valid mask function '..paramsToString(path, maskFunc))

			return
		end

		local f = io.open(path, 'rb')

		if (f == nil) then
			error(path:quote()..' could not be read')

			return
		end

		curReadPos = 1
		inputBits = {}
		inputString = f:read('*a')

		local inputCount = inputString:len()

		if (inputCount > 0) then
			local packSize = 7997

			input = {inputString:byte(1, min(packSize, inputCount))}

			for i = 2, inputCount / packSize + 1, 1 do
				for k,v in pairs({inputString:byte((i - 1) * packSize + 1, min(i * packSize, inputCount))}) do
					input[((i - 1) * packSize) + k] = v
				end
			end
		else
			input = {}
		end

		--input = {}
		--for i = 1, inputString:len(), 1 do
		--	input[i] = inputString:sub(i, i):byte()

			--[[local byteOffset = (i - 1) * 8
			local val = input[i]

			for i2 = 1, 8, 1 do
				local rest = val % 2

				val = (val - rest) / 2
				inputBits[byteOffset + i2] = rest
			end]]
		--end

		f:close()

		curMode = MODE_READING

		maskFunc(self, curMode.name)

		curMode = nil

		nprint('read '..path:quote()..' in '..(os.clock() - t)..' seconds')
	end

	function this:writeToFile(path, maskFunc)
		checkMethodCaller(self)

		local t = os.clock()

		if (ntype(maskFunc) ~= 'function') then
			error('writing to file needs valid mask function '..paramsToString(path, maskFunc))

			return
		end

		output = {}
		outputCount = 0

		curMode = MODE_WRITING

		maskFunc(self, curMode.name)

		curMode = nil

		local f = io.open(path, 'wb+')

		if (f == nil) then
			error('cannot write to '..path:quote())

			return
		end

		if (outputCount > 0) then
			local packSize = 7500

			for i = 1, outputCount / packSize + 1, 1 do
				f:write(unpack(output, (i - 1) * packSize + 1, min(i * packSize, outputCount)))
			end
		end

		f:close()

		nprint('wrote '..path:quote()..' in '..(os.clock() - t)..' seconds')
	end

	local function include(path)
		local child = io.local_loadfile(path..'.lua')

		if (child == nil) then
			local lookupPaths = package.path:split(";")

			local c = 1

			while ((child == nil) and lookupPaths[c]) do
				print(getFolder(lookupPaths[c])..path..'.lua')
				child = io.local_loadfile(getFolder(lookupPaths[c])..path..'.lua')

				c = c + 1
			end
		end

		assert(child, "cannot include "..path)

		local env = getfenv(child)

		for name, val in pairs(env) do
			env._G[name] = val
		end

		local i = 1

		while true do
			local name, val = debug.getlocal(2, i)

			if (name == nil) then
				break
			end

			if (name:find('(', 1, true) ~= 1) then
				env._G[name] = val
			end

			i = i + 1
		end

		child()

		return child
	end

	include('typeDefinitions')

	local root = {
		name = 'root',

		add = this.add,
		addNode = this.addNode,
		clear = this.clear,
		getFullPath = this.getFullPath,
		getSub = this.getSub,
		getVal = this.getValFromNode,
		setVal = this.setValFromNode,
		print = this.print,
		readFromFile = this.readFromFile,
		writeToFile = this.writeToFile,

		subs = {},
		subsCount = 0,
		subsByName = {}
	}

	return root, this
end