--typeDefinitions.lua

require 'waterlua'

local readFromInput = readFromInput
local readFromInputString = readFromInputString
local writeToTmp = writeToTmp

io.local_require('miscLib')

local NULL_CHAR = char(0)

local function createByte()
	local this = createType('byte', 1, 0)

	local maxVal = pow2(this.sizeBit) - 1
	local minVal = 0

	this.setFunc = function(val)
		if (isInt(val) ~= true) then
			return
		end

		local result = limit(val, minVal, maxVal)

		return result
	end

	this.readFunc = function()
		local result = readFromInput(0)

		if (result == nil) then
			return
		end

		return result
	end

	this.writeFunc = function(val)
		writeToTmp(char(val))
	end
end

local function createShort()
	local this = createType('short', 2, 0)

	local maxVal = pow2(this.sizeBit - 2) - 1
	local minVal = 0

	this.setFunc = function(val)
		if (isInt(val) ~= true) then
			return
		end

		local result = limit(val, minVal, maxVal)

		return result
	end

	this.readFunc = function()
		local result = 0

		for i = 1, 0, -1 do
			local cut = readFromInput(i)

			if (i == 1) then
				cut = byteEraseBit(cut, 8)
				cut = byteEraseBit(cut, 7)
			end

			if (cut == nil) then
				return
			end

			result = result + tonumber(cut) * pow256(i)
		end

		return result
	end

	this.writeFunc = function(val)
		val = limit(val, minVal, maxVal)

		writeToTmp(char(floor(val % 256)))
		writeToTmp(char(floor(val % 65536 / 256)))
	end
end

local function createInt()
	local this = createType('int', 4, 0)

	local size = pow2(this.sizeBit)

	local maxVal = size / 2 - 1
	local minVal = -size / 2

	this.setFunc = function(val)
		if (isInt(val) ~= true) then
			return
		end

		local result = limit(val, minVal, maxVal)

		return result
	end

	this.readFunc = function()
		local result = 0

		for i = 0, 3, 1 do
			local cut = readFromInput(i)

			if (cut == nil) then
				return
			end

			result = result + tonumber(cut) * pow256(i)
		end

		if (result > maxVal) then
			result = result - size
		end

		return result
	end

	local pow256_0 = 1
	local pow256_1 = 256
	local pow256_2 = pow256(2)
	local pow256_3 = pow256(3)
	local pow256_4 = pow256(4)

	this.writeFunc = function(val)
		val = limit(val, minVal, maxVal)

		writeToTmp(char(floor(val % pow256_1)))
		writeToTmp(char(floor(val % pow256_2 / pow256_1)))
		writeToTmp(char(floor(val % pow256_3 / pow256_2)))
		writeToTmp(char(floor(val % pow256_4 / pow256_3)))
	end
end

local function createFloat()
	local this = createType('float', 4, 0)

	this.setFunc = function(val)
		if (type(val) ~= 'number') then
			return
		end

		return val
	end

	this.readFunc = function()
		local result = {}
		local resultCount = 0

		for i = 0, 3, 1 do
			local cut = readFromInput(i)

			if (cut == nil) then
				return
			end

			local num = tonumber(cut)

			for i2 = 0, 7, 1 do
				local rest = num % 2

				num = (num - rest) / 2

				resultCount = resultCount + 1
				result[resultCount] = rest
			end
		end

		local exp = 0
		local frac = 1

		for i = 1, 23, 1 do
			frac = frac + result[24 - i] * pow2(-i)
		end
		for i = 24, 31, 1 do
			exp = exp + result[i] * pow2(i - 24)
		end

		if (result[32] == 1) then
			result = -frac * pow2(exp - 127)
		else
			result = frac * pow2(exp - 127)
		end

		result = floor(result * 100 + 0.5) / 100

		return result
	end

	this.writeFunc = function(val)
		if (val == 0) then
			for i = 1, this.size, 1 do
				writeToTmp(NULL_CHAR)
			end

			return
		end

		if (val < 0) then
			sign = '1'
			val = -val
		else
			sign = '0'
		end

		local exp = floor(math.log(val) / math.log(2))

		val = val / pow2(exp)

		local frac = val - floor(val)
		local fracString = ''

		for i = 1, 22, 1 do
			frac = frac * 2

			fracString = fracString..floor(frac)

			frac = frac - floor(frac)
		end

		fracString = fracString..math.min(floor(frac * 2 + 0.5), 1)

		exp = exp + 127

		local expString = ''

		local i = 1

		for i = 1, 8, 1 do
			expString = expString..(exp % 2)

			exp = floor(exp / 2)
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

			writeToTmp(char(dec))
		end
	end
end

local function createChar()
	local this = createType('char', 1, NULL_CHAR)

	this.setFunc = function(val)
		if (type(val) ~= 'string') then
			return
		end

		if (val:len() ~= this.size) then
			return
		end

		return val
	end

	this.readFunc = function()
		local result = readFromInputString(0, 0)

		if (result == nil) then
			return
		end

		return result
	end

	this.writeFunc = function(val)
		writeToTmp(val)
	end
end

local function createString()
	local this = createType('string', -1, '')

	this.setFunc = function(val)
		if (type(val) ~= 'string') then
			return
		end

		if val:find(NULL_CHAR) then
			val = val:sub(1, val:find(NULL_CHAR) - 1)
		end

		return val
	end

	this.readFunc = function()
		local til = 0

		local cut = readFromInput(0)

		if (cut == nil) then
			return
		end

		while (cut ~= 0) do
			til = til + 1

			cut = readFromInput(til)

			if (cut == nil) then
				return
			end
		end

		local result = readFromInputString(0, til - 1)

		if (result == nil) then
			result = ''
		end

		return result, til + 1
	end

	this.writeFunc = function(val)
		writeToTmp(val..NULL_CHAR)
	end
end

local function createId()
	local this = createType('id', 4, NULL_CHAR:rep(4))

	this.setFunc = function(val)
		if (type(val) ~= 'string') then
			return
		end

		if (val:len() ~= this.size) then
			return
		end

		return val
	end

	this.readFunc = function()
		local result = readFromInputString(0, this.size - 1)

		if (result == nil) then
			return
		end

		return result
	end

	this.writeFunc = function(val)
		writeToTmp(val)
	end
end

createByte()
createShort()
createInt()
createFloat()
createChar()
createString()
createId()