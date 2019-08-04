require "fileLib"
require "stringLib"
require "tableLib"

function createSlk(path)
	local self = {}

	self.fields = {}
	self.objs = {}

	return self
end

function slkAddField(slk, field, defVal)
	slk.fields[field] = {}

	slk.fields[field].defVal = defVal
end

function slkAddObj(slk, obj)
	slk.objs[obj] = {}

	slk.objs[obj].vals = {}
end

function slkObjSetField(slk, obj, field, val)
	if (slk.objs[obj] == nil) then
		slkAddObj(slk, obj)
	end

	slk.objs[obj].vals[field] = val
end

function readSlk(path, onlyHeader)
	path = path..".slk"

	local data = {}
	local file = io.open(path, "r")

	local curX = 0
	local curY = 0
	local maxX = 0
	local maxY = 0

	if (file == nil) then
		print("readSlk: could not open "..path)

		return nil
	end

	for line in file:lines() do
		line = line:split(";")

		if (line[1] == "C") then
			local c = 1
			local val
			local x
			local y

			while line[c] do
				local symbole = line[c]:sub(1, 1)

				if (symbole == "X") then
					x = tonumber(line[c]:sub(2, line[c]:len()))
				end
				if (symbole == "Y") then
					y = tonumber(line[c]:sub(2, line[c]:len()))
				end
				if (symbole == "K") then
					val = line[c]:sub(2, line[c]:len())

					if (val:sub(1, 1) == [["]]) then
						val = val:sub(2, val:len() - 1)
					elseif tonumber(val) then
						val = tonumber(val)
					end
				end

				c = c + 1
			end

			if (x == nil) then
				x = curX
			end
			if (y == nil) then
				y = curY
			end

			if (data[y] == nil) then
				data[y] = {}
			end

			if (x > maxX) then
				maxX = x
			end
			if (y > maxY) then
				maxY = y
			end
			data[y][x] = val

			curX = x
			curY = y
		end
	end

	local self = createSlk(path)

	for x, val in pairs(data[1]) do
		slkAddField(self, val)
	end

	if onlyHeader then
		return self
	end

	local c = 2

	while data[c] do
		local obj = data[c][1]

		if obj then
			for x, val in pairs(data[c]) do
				local field = data[1][x]

				if field then
					slkObjSetField(self, obj, field, val)
				end
			end
		end

		c = c + 1
	end

	return self
end

function writeSlk(slk, path)
	path = path..".slk"

	os.execute([[mkdir ]]..getFolder(path):quote()..[[ 2>NUL]])

	local file = io.open(path, "w+")

	if (file == nil) then
		print("writeSlk: cannot create file at "..path)

		return
	end

	file:write("ID;PWXL;N;E")

	file:write("\nB;X"..getTableSize(slk.fields)..";Y"..(getTableSize(slk.objs) + 1)..";D0")

	local c = 1
	local fieldX = {}

	local function addField(field)
		fieldX[field] = c

		file:write("\nC;X"..c..";Y1;K"..field:quote())

		c = c + 1
	end

	addField(slk.pivotField)

	for field in pairs(slk.fields) do
		if (field ~= slk.pivotField) then
			addField(field)
		end
	end

	local y = 1

	for obj, objData in pairs(slk.objs) do
		y = y + 1

		file:write("\nC;X1;Y"..y..";K"..obj:quote())

		local function writeField(field, val)
			if (field == slk.pivotField) then
				return
			end

			local x = fieldX[field]

			if x then
				if val then
					if (type(val) == "boolean") then
						if val then
							val = 1
						else
							val = 0
						end
					elseif (type(val) == "string") then
						val = val:quote()
					end
				else
					val = [["-"]]
				end

				file:write("\nC;X"..x..";Y"..y..";K"..val)
			else
				print("field not available "..field)
			end
		end

		for field, fieldData in pairs(slk.fields) do
			if (fieldData.defVal and (objData.vals[field] == nil)) then
				writeField(field, fieldData.defVal)
			end
		end

		for field, val in pairs(objData.vals) do
			writeField(field, val)
		end
	end

	file:write("\nE")

	file:close()
end