require 'waterlua'

local params

io.local_require([[color]])

local t = {}

local function create(pathMap, errorFile)
	assert(pathMap, 'no pathMap')

	local this = {}

	this.pathMap = pathMap
	this.errorFile = errorFile

	this.colors = {}

	function this:addColor(name, red, green, blue, alpha)
		assert(name, 'no name')

		assert((this.colors[name] == nil), 'color '..tostring(name)..' already exists')

		local color = {}

		this.colors[name] = color

		color.red = red or 0
		color.green = green or 0
		color.blue = blue or 0
		color.alpha = alpha or 0

		color.hexString = string.format('%s%s%s%s', dec2hex(color.alpha, 2), dec2hex(color.red, 2), dec2hex(color.green, 2), dec2hex(color.blue, 2))
	end

	this:addColor('DEFAULT', 255, 255, 255, 255)

	local function replace(a, sub, rep)
		if (rep == nil) then
			rep = ''
		end

		while (val:find(sub, 1, true) ~= nil) do
			val = val:sub(1, val:find(sub, 1, true) - 1)..rep..val:sub(val:find(sub, 1, true) + rep:len() + 1, val:len())
		end

		return val
	end

	function this:exec(sourceField, inVal, lv, doColor, sourcePath)
		local val = tostring(inVal)

		while (val:findInner('<', '>') ~= nil) do
			local tagStart, tagEnd = val:findInner('<', '>')

			local isOuter = (val:find('<') == tagStart)

			local subbedPart = val:sub(tagStart + 1, tagEnd - 1)

			local replaceVal

			local field = subbedPart
			local targetPath

			if (field:find(':', 1, true) ~= nil) then
				targetPath = field:sub(1, field:find(':', 1, true) - 1)
				field = field:sub(field:find(':', 1, true) + 1, field:len())

				targetPath = pathMap:toFullPath(sourcePath, targetPath, 'wc3obj')
			else
				targetPath = path
			end

			local mods = {}

			if (field:find(',', 1, true) ~= nil) then
				mods = field:sub(field:find(',', 1, true) + 1, field:len()):split(',')

				field = field:sub(1, field:find(',', 1, true) - 1)
			end

			local lastChar = field:sub(field:len(), field:len())
			local level
			local pos = 1

			while (tonumber(lastChar) ~= nil) do
				if (level == nil) then
					level = 0
				end

				level = level + tonumber(lastChar) * pos

				field = field:sub(1, field:len() - 1)

				lastChar = field:sub(field:len(), field:len())
				pos = pos + 1
			end

			if (level == nil) then
				level = lv
			end

			local sheet

			if (targetPath ~= nil) then
				sheet = getSheetFromPath(targetPath)
			end

			if (sheet ~= nil) then
				if ((sheet:getVal(field, level) ~= nil) or (sheet:getVal(field, level) ~= nil)) then
					local val = sheet:getVal(field, level) or sheet:getVal(field, 1)

					if (type(val) == 'string') then
						if val:find('<level>') or val:find('<prevLevel>') then
							val = val:gsub('<level>', '<level,'..(level - lv)..'>')
							val = val:gsub('<prevLevel>', '<prevLevel,'..(level - lv)..'>')
						end
					end

					replaceVal = val
				elseif (field == 'level') then
					replaceVal = lv
				elseif (field == 'prevLevel') then
					replaceVal = lv - 1
				else
					--errorFile:write('\n\nin '..path..'\n\t'..'cannot find field '..field..' ('..level..') of '..targetPath)
				end
			else
				if (targetPath == nil) then
					targetPath = 'no targetPath'
				end

				--errorFile:write('\n\nin '..path..'\n\t'..'cannot find sheet '..targetPath)
			end

			local s

			if (replaceVal ~= nil) then
				if ((type(replaceVal) == 'string') and replaceVal:find('<.*>')) then
					replaceVal = replaceTags(sourceField, replaceVal, lv, false, targetPath)
				end

				local val = replaceVal

				local c = 1

				while (mods[c] ~= nil) do						
					if (mods[c] == '%') then
						if (tonumber(val) ~= nil) then
							val = tostring(val * 100)..'%'
						end
					elseif (mods[c] == '-') then							
						if (tonumber(val) ~= nil) then
							val = tostring(-tonumber(val))
						end
					elseif ((tonumber(val) ~= nil) and (tonumber(mods[c]) ~= nil)) then
						val = tostring(tonumber(val) + tonumber(mods[c]))
					elseif ((mods[c] == 'asSecs') and (tonumber(val) ~= nil)) then
						local num = tonumber(val)

						if ((num == 1) or (num == -1)) then
							val = tostring(val)..' second'
						else
							val = tostring(val)..' seconds'
						end
					else
						local ops = {}

						ops['+'] = '+'
						ops['-'] = '-'
						ops['*'] = '*'
						ops['/'] = '/' 

						local op = ops[mods[c]:sub(1, 1)]
						local num = mods[c]:sub(2, mods[c]:len())

						if ((tonumber(val) ~= nil) and (op ~= nil) and (tonumber(num) ~= nil)) then
							if (op == '+') then
								val = tostring(tonumber(val) + tonumber(num))
							elseif (op == '-') then
								val = tostring(tonumber(val) - tonumber(num))
							elseif (op == '*') then
								val = tostring(tonumber(val) * tonumber(num))
							elseif (op == '/') then
								val = tostring(tonumber(val) / tonumber(num))
							end
						end
					end

					c = c + 1
				end

				replaceVal = val

				s = replaceVal

				if (doColor == true) and isOuter and (sourceField ~= field) then
					s = module_color.engold(s)
				end
			else
				s = '§'..subbedPart..'$'

				if isOuter then
					s = module_color.engold(s)
				end
			end

			val = val:sub(1, tagStart - 1)..s..val:sub(tagEnd + 1, val:len())
		end

		val = val:gsub('§', '<')
		val = val:gsub('%$', '>')

		string.findlast = function(s, target)
			local pos = 0
			local posEnd
			local cap

			while s:find(target, pos + 1) do
				pos, posEnd, cap = s:find(target, pos + 1)
			end

			if (pos == 0) then
				return nil
			end

			return pos, posEnd, cap
		end

		local openingTagStart, openingTagEnd, params = val:findlast('<color=([A-Za-z0-9_%,]+)>')

		while (openingTagStart ~= nil) do
			params = params:split(',')

			local colStartName = params[1]
			local colEndName = params[2]

			if (colStartName == nil) then
				colStartName = 'DEFAULT'

				if (errorFile ~= nil) then
					errorFile:write('no color specified')
				end
			end

			colStart = this.colors[colStartName]

			if (colStart == nil) then
				colStart = this.colors['DEFAULT']

				if (errorFile ~= nil) then
					errorFile:write('color '..colStartName:quote()..' not defined')
				end
			end

			if (colEnd ~= nil) then
				colEnd = this.colors[colEndName]

				if (colEnd == nil) then
					colEnd = this.colors['DEFAULT']

					if (errorFile ~= nil) then
						errorFile:write('color '..colEndName:quote()..' not defined')
					end
				end
			end

			local closingTagStart, closingTagEnd = val:find('</color>', openingTagEnd + 1, true)

			if (closingTagStart == nil) then
				closingTagStart = val:len()
				closingTagEnd = val:len()
			end

			local function reduceLen(s)
				local i = 1
				local len = 0

				while (i <= s:len()) do
					if (s:sub(i, i + module_color.START:len() - 1) == Color.START) then
						i = i + module_color.START:len() + 4 * 2 - 1
					else
						len = len + 1
					end

					i = i + 1
				end

				return len
			end

			local function gradPos(s, colorStart, colorEnd, pos)
				if (pos == 1) then
					return colorStart.hexString
				end
				if (pos == reduceLen(s)) then
					return colorEnd.hexString
				end

				local alphaStart = colorStart.alpha
				local redStart = colorStart.red
				local greenStart = colorStart.green
				local blueStart = colorStart.blue

				local alphaEnd = colorEnd.alpha
				local redEnd = colorEnd.red
				local greenEnd = colorEnd.green
				local blueEnd = colorEnd.blue

				local len = reduceLen(s)

				local alphaAdd = math.floor((alphaEnd - alphaStart) / len)
				local redAdd = math.floor((redEnd - redStart) / len)
				local greenAdd = math.floor((greenEnd - greenStart) / len)
				local blueAdd = math.floor((blueEnd - blueStart) / len)

				pos = pos - 1

				return dec2hex(alphaStart + pos * alphaAdd)..dec2hex(redStart + pos * redAdd)..dec2hex(greenStart + pos * greenAdd)..dec2hex(blueStart + pos * blueAdd)
			end

			local inter = val:sub(openingTagEnd + 1, closingTagStart - 1)

			if (colEnd ~= nil) then
				local pos, posEnd = inter:find(module_color.RESET)

				while (pos ~= nil) do
					posRed = reduceLen(inter:sub(1, pos - 1)) + 1

					inter = inter:sub(1, pos - 1)..module_color.START..gradPos(inter, colStartName, colEndName, posRed)..inter:sub(posEnd + 1, inter:len())

					pos, posEnd = inter:find(module_color.RESET)
				end
			else
				inter = inter:gsub(module_color.RESET, module_color.START..colStartName)
			end

			val = val:sub(1, openingTagEnd)..inter..val:sub(closingTagStart, val:len())

			closingTagStart, closingTagEnd = val:find('</color>', openingTagEnd + 1, true)

			if (closingTagStart == nil) then
				closingTagStart = val:len()
				closingTagEnd = val:len()
			end

			local function grad(s, colorStart, colorEnd)
				if (colorEnd == nil) then
					return module_color.START..colorStart.hexString..s..module_color.RESET
				end

				local alphaStart = colorStart.alpha
				local redStart = colorStart.red
				local greenStart = colorStart.green
				local blueStart = colorStart.blue

				local alphaEnd = colorEnd.alpha
				local redEnd = colorEnd.red
				local greenEnd = colorEnd.green
				local blueEnd = colorEnd.blue

				local len = reduceLen(s)

				local alphaAdd = math.floor((alphaEnd - alphaStart) / len)
				local redAdd = math.floor((redEnd - redStart) / len)
				local greenAdd = math.floor((greenEnd - greenStart) / len)
				local blueAdd = math.floor((blueEnd - blueStart) / len)

				local result = ''

				local openingInterStart, openingInterEnd = s:find(module_color.START..'........')

				if (openingInterStart == nil) then
					openingInterStart = s:len() + 1
				end

				for i = 1, openingInterStart - 1, 1 do
					if (i == 1) then
						result = result..module_color.START..colorStart.hexString
					elseif (i == s:len()) then
						result = result..module_color.START..colorEnd.hexString
					else
						result = result..module_color.START..dec2hex(alphaStart + (i - 1) * alphaAdd)..dec2hex(redStart + (i - 1) * redAdd)..dec2hex(greenStart + (i - 1) * greenAdd)..dec2hex(blueStart + (i - 1) * blueAdd)
					end

					result = result..s:sub(i, i)
				end

				local closingInterStart
				local closingInterEnd

				if (openingInterStart <= s:len()) then
					closingInterStart, closingInterEnd = s:findlast(module_color.START..'........', openingInterEnd + 1)
				end

				result = result..s:sub(openingInterStart, closingInterEnd)

				if (closingInterStart ~= nil) then
					for i = closingInterEnd + 1, s:len(), 1 do
						if (i == 1) then
							result = result..module_color.START..colorStart.hexString
						elseif (i == s:len()) then
							result = result..module_color.START..colorEnd.hexString
						else
							result = result..module_color.START..dec2hex(alphaEnd - (s:len() - i) * alphaAdd)..dec2hex(redEnd - (s:len() - i) * redAdd)..dec2hex(greenEnd - (s:len() - i) * greenAdd)..dec2hex(blueEnd - (s:len() - i) * blueAdd)
						end

						result = result..s:sub(i, i)
					end
				end

				return result
			end

			local inter = val:sub(openingTagEnd + 1, closingTagStart - 1)

			val = val:sub(1, openingTagStart - 1)..grad(inter, colStart, colEnd)..val:sub(closingTagEnd + 1, val:len())

			openingTagStart, openingTagEnd, params = val:findlast('<color=([A-Za-z0-9_,]+)>')
		end

		val = val:gsub(module_color.RESET..module_color.RESET, module_color.RESET)
		val = val:gsub(module_color.RESET..module_color.START, module_color.START)
		val = val:gsub(module_color.START..'........'..module_color.START, module_color.START)

		local pos, posEnd = val:findInner('<', '>')

		if (pos ~= nil) then
			local t = {}

			while pos do
				local subbedPart = val:sub(pos + 1, posEnd - 1)

				t[#t + 1] = subbedPart

				val = val:sub(1, pos - 1)..'$'..subbedPart..'$'..val:sub(posEnd + 1, val:len())
		
				pos, posEnd = val:findInner('<', '>')
			end

			if (errorFile ~= nil) then
				local lines = {}

				local function addLine(line)
					lines[#lines + 1] = line
				end

				addLine('')
				addLine('path='..tostring(path))

				addLine('sourceField='..tostring(sourceField))
				addLine('level='..tostring(lv))
				addLine('doColor='..tostring(doColor))

				addLine('before: '..tostring(inVal))
				addLine('after: '..tostring(val))

				addLine('could not replace: '..table.concat(t, ','))

				writeTable(errorFile, lines)
			end
		end

		if (val:find('<') ~= nil) then
			val = val:gsub('<', '$')

			if (errorFile ~= nil) then
				local lines = {}

				local function addLine(line)
					lines[#lines + 1] = line
				end

				addLine('\npath='..tostring(path))
				addLine('sourceField='..tostring(sourceField))
				addLine('level='..tostring(lv))
				addLine('doColor='..tostring(doColor))

				addLine('before: '..tostring(inVal))
				addLine('after: '..tostring(val))

				addLine('contains unclosed tags')

				writeTable(errorFile, lines)
			end
		end

		return val
	end

	return this
end

t.create = create

tagReplacement = t