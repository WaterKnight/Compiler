require "stringLib"

wc3objLib = {}

wc3objLib.create = function(path)
	local this = {}

	local maxX
	local maxY
	local table = {}

	local function loadIn()
		local file = io.open(path, "r")

		local curY = 0

		for line in file:lines() do
			if line then
				local curX = 0
				curY = curY + 1

				table[curY] = {}

				for i, s in pairs(line:split("\t")) do
					curX = curX + 1

					if ((maxX == nil) or (curX > maxX)) then
						maxX = curX
					end

	                		if tonumber(s) then
						if ((table[curY][1] == "raw") or (table[curY][1] == "baseRaw")) then
							table[curY][curX] = s
						else
							table[curY][curX] = tonumber(s)
						end
					elseif (tobool(s) ~= nil) then
						table[curY][curX] = tobool(s)
					else
						table[curY][curX] = s
					end
				end
			end
		end

		file:close()

		maxY = curY
	end

	loadIn()

	this.table = table

	local arrayFields = {}
	local levelsAmount = 0
	local levelVals = {}
	local vals = {}

	for y = 1, maxY, 1 do
		local field = table[y][1]

		if (field and (field ~= "") and (field ~= "field") and (field:find("//", 1, true) ~= 1)) then
			if vals[field] then
				for x = 1, maxX, 1 do
					level = table[1][x]
					if vals[field][x] then
						if table[y][x] then
							vals[field][x] = vals[field][x]..";"..table[y][x]
						else
							vals[field][x] = vals[field][x]..";"
						end
					else
						if table[y][x] then
							vals[field][x] = ";"..table[y][x]
						else
							vals[field][x] = ";"
						end
					end

					if (level == "value") then
						level = 1
					end

					if (type(level) == "number") then
						if levelVals[field][level] then
							if table[y][x] then
								levelVals[field][level] = levelVals[field][level]..";"..table[y][x]
							else
								levelVals[field][level] = levelVals[field][level]..";"
							end
						else
							if table[y][x] then
								levelVals[field][level] = ";"..table[y][x]
							else
								levelVals[field][level] = ";"
							end
						end
					end
				end
			else
				vals[field] = {}
				levelVals[field] = {}

				for x = 1, maxX, 1 do
					level = table[1][x]
					vals[field][x] = table[y][x]

					if (level == "value") then
						level = 1
					end

					if (type(level) == "number") then
						if (level > levelsAmount) then
							levelsAmount = level
						end

						levelVals[field][level] = table[y][x]
						if ((level ~= 0) and (level ~= 1) and table[y][x]) then
							arrayFields[field] = field
						end
					end
				end
			end
		end
	end

	this.arrayFields = arrayFields
	this.levelsAmount = levelsAmount
	this.levelVals = levelVals
	this.vals = vals

	local jassIdentCol

	for x = 1, maxX, 1 do
		if (table[1][x] == "jass ident") then
			jassIdentCol = x
		end
	end

	this.jassIdentCol = jassIdentCol

	return this
end