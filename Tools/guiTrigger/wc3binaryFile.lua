--wc3binaryFile.lua

wc3binaryFile = {}

function wc3binaryFile.create()
	local this = {}

	local dataByName = {}
	local dataPatterns = {}

	local mode

	local types = {}

	local TYPE_BYTE
	local TYPE_SHORT
	local TYPE_INT
	local TYPE_REAL
	local TYPE_UNREAL
	local TYPE_CHAR
	local TYPE_STRIGN
	local TYPE_ID

	local function paramsToString(...)
		local arg = {...}
		local result
		local n = select('#', ...)

		for c = 1, n, 1 do
			local v = arg[c]

			if result then
				result = result..", "
			else
				result = ""
			end

			if (type(v) == "string") then
				result = result..[["]]..tostring(v)..[["]]
			else
				result = result..tostring(v)
			end
		end

		return [[(]]..result..[[)]]
	end

	local function getDataByName(name)
		if (name == nil) then
			print([[try to access field with nil name]])

			return nil
		end

		local d = dataByName[name]

		if (d == nil) then
			print([[field "]]..name..[[" does not exist]])

			return nil
		end

		return d
	end

	this.getVal = function(name)
		local d = getDataByName(name)

		if (d == nil) then
			return nil
		end

		return d.val
	end

	this.setVal = function(name, val)
		local d = getDataByName(name)

		if (d == nil) then
			return
		end

		d.val = val
	end

	local function getDataFlagByName(parentName, subName, ignoreNil)
		local d = getDataByName(parentName)

		if (d == nil) then
			return nil
		end

		local flags = d.flagsByName

		if (flags == nil) then
			print([[field "]]..parentName..[[" has no flags]])

			return nil
		end

		if (subName == nil) then
			print([[try to access flag with nil name of field ]]..parentName)

			return nil
		end

		local flag = flags[subName]

		if (ignoreNil ~= true) then
			if (flag == nil) then
				print([[field "]]..parentName..[[" has no flag "]]..subName..[["]])
			end
		end

		return flag
	end

	this.getValFlag = function(parentName, subName)
		local flag = getDataFlagByName(parentName, subName)

		if (flag == nil) then
			return nil
		end

		return flag.val
	end

	this.setValFlag = function(parentName, subName, val)
		local flag = getDataFlagByName(parentName, subName)

		if (flag == nil) then
			return
		end

		if ((val ~= 0) and (val ~= 1)) then
			print([[setValFlag - flags must be either 1 or 0 ]]..paramsToString(parentName, subName, val))

			return
		end

		flag.val = val

		local d = getDataByName(parentName)

		d.val = 0

		local flags = d.flags

		for bit = 1, #flags, 1 do
			d.val = d.val + flags[bit].val * math.pow(2, bit - 1)
		end
	end

	this.addFlag = function(parentName, subName)
		if (mode == "writing") then
			return
		end

		local parent = getDataByName(parentName)

		if (parent == nil) then
			print([[addFlag - parent does not exist ]]..paramsToString(parentName, subName))

			return
		end

		if (subName == nil) then
			print("addFlag - subName is nil")

			return
		end

		if getDataFlagByName(parentName, subName, true) then
			print([[addFlag - field "]]..parentName..[[" already has flag "]]..subName..[["]])

			return
		end

		local type = parent.type

		if (type.sizeBit >= 0) then
			if (#parent.flags > type.sizeBit - 1) then
				print([[addFlag - field "]]..parentName..[[" already has the max of ]]..type.sizeBit..[[ flags (]]..type.name..[[)]])

				return
			end
		end

		local sub = {}

		sub.name = subName

		local function readBit(val, pos)
			local rest

			if (val == nil) then
				return nil
			end

			for i = 1, pos, 1 do
				rest = val % 2

				val = (val - rest) / 2
			end

			return rest
		end

		sub.val = readBit(parent.val, #parent.flags + 1)

		parent.flags[#parent.flags + 1] = sub
		parent.flagsByName[subName] = sub
	end

	local function splitToFlags(parentName, subNames)
		local parent = getDataByName(parentName)

		if (parent == nil) then
			print([[splitToFlags - parent does not exist ]]..paramsToString(parentName, subNames))

			return
		end

		if (type(subNames) ~= "table") then
			print([[splitToFlags - subNames is not a table]])

			return
		end

		local sizeBit = parent.type.sizeBit
		local val = parent.val

		for i = 1, #subNames, 1 do
			if (i > sizeBit) then
				print([[splitToFlags - subNames table is too big, max ]]..sizeBit..[[ values within (]]..parent.type.name..[[) ]]..paramsToString(parentName, subNames))

				return
			end
			if (type(subNames[i]) ~= "string") then
				print([[splitToFlags - ]]..tostring(subNames[i])..[[ is no string ]]..paramsToString(parentName, subNames))

				return
			end

			local rest = val % 2
			local sub = {}

			sub.name = subNames[i]
			sub.val = rest

			val = (val - rest) / 2

			parent.flags[#parent.flags + 1] = sub
			parent.flagsByName[subNames[i]] = sub
		end
	end

	this.print = function(maxBeforePause)
		local c = 1
		local maxBeforePauseC = 1

		while dataPatterns[c] do
			local d = dataPatterns[c]

			if (d.flags) then
				for c2 = 1, #d.flags, 1 do
					local sub = d.flags[c2]

					print(d.name.."_"..sub.name.." --> "..sub.val)
				end
			else
				print(d.name.." --> "..d.val)
			end

			c = c + 1

			if (maxBeforePauseC == maxBeforePause) then
				maxBeforePauseC = 1
				os.execute("pause")
				os.execute("cls")
			else
				maxBeforePauseC = maxBeforePauseC + 1
			end
		end
	end

	local curPos
	local input

	local function readFromInput(a, b)
		local result = input:sub(a, b)

		if (b > input:len()) then
			return nil
		end

		if (b < a) then
			return nil
		end

		return result
	end

	local function readByte(name)
		local result = readFromInput(curPos, curPos)

		if (result == nil) then
			return nil
		end

		curPos = curPos + TYPE_BYTE.size

		return string.byte(result)
	end

	local function readShort(name)
		local result = 0

		for i = 0, 1, 1 do
			local cut = readFromInput(curPos + i, curPos + i)

			if (cut == nil) then
				return nil
			end

			cut = cut:byte()

			result = result + tonumber(cut) * math.pow(256, i)
		end

		curPos = curPos + TYPE_SHORT.size

		if (result > math.pow(2, TYPE_SHORT.sizeBit) / 2) then
			return (result - math.pow(2, TYPE_SHORT.sizeBit))
		end

		return result
	end

	local function readInt(name)
		local result = 0

		for i = 0, 3, 1 do
			local cut = readFromInput(curPos + i, curPos + i)

			if (cut == nil) then
				return nil
			end

			cut = cut:byte()

			result = result + tonumber(cut) * math.pow(256, i)
		end

		curPos = curPos + TYPE_INT.size

		if (result > math.pow(2, TYPE_INT.sizeBit) / 2) then
			return (result - math.pow(2, TYPE_INT.sizeBit))
		end

		return result
	end

	local function readReal(name)
		local result = ""

		for i = 3, 0, -1 do
			local cut = readFromInput(curPos + i, curPos + i)

			if (cut == nil) then
				return
			end

			cut = cut:byte()

			local num = tonumber(cut)

			for i2 = 7, 0, -1 do
				local quo = math.floor(num / math.pow(2, i2))

				num = num - quo * math.pow(2, i2)
				result = result..quo
			end
		end

		result = result:reverse()

		local exp = 0
		local frac = 1

		for i = 1, 23, 1 do
			frac = frac + result:sub(24 - i, 24 - i) * math.pow(2, -i)
		end
		for i = 24, 31, 1 do
			exp = exp + tonumber(result:sub(i, i)) * math.pow(2, i - 24)
		end
		local sign = result:sub(32, 32)

		result = math.pow(-1, sign) * frac * math.pow(2, exp - 127)

		curPos = curPos + TYPE_REAL.size

		result = math.floor(result * math.pow(10, 2) + 0.5) / math.pow(10, 2)

		return result
	end

	local function readUnreal(name)
		return readReal()
	end

	local function readChar(name)
		local result = readFromInput(curPos, curPos)

		if (result == nil) then
			return nil
		end

		curPos = curPos + TYPE_CHAR.size

		return result
	end

	local function readString(name)
		local til = curPos			

		local cut = readFromInput(til, til)

		if (cut == nil) then
			return nil
		end

		cut = cut:byte()

		while (cut ~= 0) do
			til = til + 1

			cut = readFromInput(til, til)

			if (cut == nil) then
				return nil
			end

			cut = cut:byte()
		end

		local result = readFromInput(curPos, til - 1)

		if (result == nil) then
			result = ""
		end

		curPos = til + 1

		return result
	end

	local function readId(name)
		local result = readFromInput(curPos, curPos + TYPE_ID.size - 1)

		if (result == nil) then
			return nil
		end

		curPos = curPos + TYPE_ID.size

		return result
	end

	local function read(name, type, subFlags)
		if ((name == nil) or (type == nil)) then
			print([[no name/type passed to read ]]..paramsToString(name, type))

			return
		end

		if (types[type] == nil) then
			print([[try to read with invalid type ]]..paramsToString(name, type))

			return
		end

		local val = type.readFunc(name)

		if (val == nil) then
			print([[no ]]..type.name..[[ "]]..name..[[" at pos ]]..(curPos - 1)..[[ (0x]]..string.format("%X", curPos - 1)..[[)]])

			return
		end

		local d = {}

		dataPatterns[#dataPatterns + 1] = d

		d.name = name
		d.type = type

		dataByName[name] = d

		d.val = val

		if subFlags then
			d.flags = {}
			d.flagsByName = {}

			splitToFlags(name, subFlags)
		end
	end

	local output

	local function writeToOutput(val)
		output[#output + 1] = val
	end

	local function writeByte(val)
		writeToOutput(string.char(val))
	end

	local function writeShort(val)
		writeToOutput(string.char(math.floor(val % 256))..string.char(math.floor(val % 65536 / 256)))
	end

	local function writeInt(val)
		for i = 0, 3, 1 do
			writeToOutput(string.char(math.floor(val % math.pow(256, i + 1) / math.pow(256, i))))
		end
	end

	local function writeReal(val)
		if (val == 0) then
			writeToOutput(string.char(0):rep(4))

			return
		end

		if (val < 0) then
			sign = "1"
			val = -val
		else
			sign = "0"
		end

		local exp = math.floor(math.log(val) / math.log(2))

		val = val / math.pow(2, exp)

		local frac = val - math.floor(val)
		local fracString = ""

		for i = 1, 22, 1 do
			frac = frac * 2

			fracString = fracString..math.floor(frac)

			frac = frac - math.floor(frac)
		end

		fracString = fracString..math.floor(frac * 2 + 0.5)

		exp = exp + 127

		local expString = ""

		local i = 1

		for i = 1, 8, 1 do
			expString = expString..(exp % 2)

			exp = math.floor(exp / 2)
		end

		expString = expString:reverse()

		val = sign..expString..fracString

		for i = 3, 0, -1 do
			local function bin2Dec(para)
				local result = 0
				local mult = 1
				local i = 1

				while (i <= para:len()) do
					result = result + tonumber(para:sub(i, i)) * mult

					i = i + 1
					mult = mult * 2
				end

				return result
			end

			local dec = bin2Dec(val:sub(i * 8 + 1, i * 8 + 8):reverse())

			writeToOutput(string.char(dec))
		end
	end

	local function writeUnreal(val)
		writeReal(val)
	end

	local function writeChar(val)
		writeToOutput(val)
	end

	local function writeString(val)
		writeToOutput(val..string.char(0))
	end

	local function writeId(val)
		writeToOutput(val)
	end

	local typeByName = {}

	local function createType(name, size, readFunc, writeFunc, defVal)
		local this = {}

		this.name = name
		this.size = size
		this.sizeBit = size * 8
		this.readFunc = readFunc
		this.writeFunc = writeFunc
		this.defVal = defVal

		types[this] = this
		typeByName[name] = this

		return this
	end

	TYPE_BYTE = createType("byte", 1, readByte, writeByte, string.char(0))
	TYPE_SHORT = createType("short", 2, readShort, writeShort, 0)
	TYPE_INT = createType("int", 4, readInt, writeInt, 0)
	TYPE_REAL = createType("real", 4, readReal, writeReal, 0)
	TYPE_UNREAL = createType("unreal", 4, readUnreal, writeUnreal, 0)
	TYPE_CHAR = createType("char", 1, readChar, writeChar, string.char(0))
	TYPE_STRING = createType("string", -1, readString, writeString, "")
	TYPE_ID = createType("id", 4, readId, writeId, string.char(0):rep(4))

	this.getTypeByName = function(name)
		return typeByName[name]
	end

	local function write(name, type)
		if ((name == nil) or (type == nil)) then
			print([[no name/type passed to write ]]..paramsToString(name, type))

			return
		end

		--if (types[type] == nil) then
		--	print([[try to write with invalid type ]]..paramsToString(name, type))

		--	return
		--end

		local val = this.getVal(name)

		if (val == nil) then
			print([[could not write "]]..name..[[", replace by default value]])

			val = type.defVal
		end

		type.writeFunc(val)
	end

	this.add = function(name, type, useFlags)
		if (types[type] == nil) then
			local typeName = typeByName[type]

			if (typeName == nil) then
				print([[cannot add incorrect type ]]..paramsToString(name, type))

				return
			else
				type = typeName
			end
		end

		if (mode == "reading") then
			read(name, type, useFlags)
		elseif (mode == "writing") then
			write(name, type)
		end
	end

	this.readFromFile = function(path, maskFunc)
		local t = os.clock()

		if (type(maskFunc) ~= "function") then
			print([[writing to file needs valid mask function ]]..paramsToString(path, maskFunc))

			return
		end

		local f = io.open(path, "rb")

		if (f == nil) then
			print(path.." could not be read")

			return
		end

		curPos = 1
		input = f:read("*a")

		f:close()

		mode = "reading"

		maskFunc(this)

		mode = nil

		print([[read ]]..path..[[ in ]]..os.clock() - t..[[ seconds]])
	end

	this.writeToFile = function(path, maskFunc)
		local t = os.clock()

		if (type(maskFunc) ~= "function") then
			print([[writing to file needs valid mask function ]]..paramsToString(path, maskFunc))

			return
		end

		output = {}

		mode = "writing"

		maskFunc(this)

		mode = nil

		local f = io.open(path, "wb+")

		if (f == nil) then
			print("cannot write to "..path)

			return
		end

		local function writeTableToFile(f, t)
			if (#t == 0) then
				return
			end

			local packSize = 7500

			for i = 1, #t / packSize + 1, 1 do
				f:write(unpack(t, (i - 1) * packSize + 1, math.min(i * packSize, #t)))
			end
		end

		writeTableToFile(f, output)

		f:close()

		print([[wrote ]]..path..[[ in ]]..os.clock() - t..[[ seconds]])
	end

	return this
end