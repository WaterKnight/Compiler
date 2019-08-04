require 'waterlua'

local t = {}

local function create(specsType, specsPath, path)
	assert(specsType, 'no type')

	local this = {}

	this.path = path

	this.fields = {}
	this.arrayFields = {}
	this.sections = {}

	function this:isDummy()
		if (this:getVal('dummy') == true) then
			return true
		end

		local classes = totable(this:getVal('classes'))

		if tableContains(classes, 'DUMMY') then
			return true
		end

		return false
	end

	this.type = specsType

	local function addSection(name, defaultCols)
		local sectionData = {}

		this.sections[name] = sectionData

		sectionData.fields = {}

		if defaultCols then
			sectionData.defaultCols = copyTable(defaultCols)
		else
			sectionData.defaultCols = {}
		end
	end

	addSection('common', {'field'})
	addSection('typeSpecific', {'field'})
	addSection('custom', {'field', 'jass ident', 'array'})
	addSection('extra')

	this.customFields = {}

	function this:addField(section, field, jassIdent)
		local sectionData = this.sections[section]

		assert(sectionData, 'section '..tostring(section)..' not available')

		assert(field, 'no field')

		local fieldData = this.fields[field]

		assert((fieldData == nil), 'field '..tostring(field)..' already used')

		local fieldData = {}

		sectionData.fields[field] = fieldData
		this.fields[field] = fieldData

		fieldData.isArray = false
		fieldData.jassIdent = jassIdent
		fieldData.jassType = jassIdent
		--fieldData.jassIdent = jassIdent or field
		fieldData.section = sectionData
		fieldData.vals = {}

		if (section == 'custom') then
			this.customFields[#this.customFields + 1] = field
		end
	end

	function this:addCustomField(field, jassIdent)
		this:addField('custom', field, jassIdent)
	end

	function this:addFieldsFromSpecsPath(path)
		assert(path, 'no path')

		local type = this.type

		assert(type, 'no type')

		--see what fields belongs to which category

		local fieldDict = {}

		--common
		local commonPath = path..[[ObjectEditor\common.txt]]

		local f = io.open(commonPath, 'r')

		assert(f, 'cannot open '..tostring(commonPath))

		for line in f:lines() do
			local vals = line:split('\t')

			local field = vals[1]

			if (field and (field ~= '')) then
				if (this.fields[field] == nil) then
					this:addField('common', field)
				end
			end
		end

		f:close()

		--typeSpecific
		local typeSpecificPath = path..[[ObjectEditor\types\]]..type..[[.txt]]

		local f = io.open(typeSpecificPath, 'r')

		assert(f, 'cannot open '..tostring(typeSpecificPath))

		for line in f:lines() do
			local vals = line:split('\t')

			local field = vals[1]

			if (field and (field ~= '')) then
				if (this.fields[field] == nil) then
					this:addField('typeSpecific', field)
				end
			end
		end

		f:close()
	end

	if specsPath then
		this:addFieldsFromSpecsPath(specsPath)
	end

	this.levelsAmount = 0

	function this:hasVal(field, col)
		assert(field, 'no field')

		local fieldData = this.fields[field]

		if (fieldData == nil) then
			return false
		end

		if (col == nil) then
			return true
		end

		return (fieldData.vals[col] ~= nil)
	end

	function this:getVal(field, col)
		assert(field, 'no field')

		local fieldData = this.fields[field]

		if (fieldData == nil) then
			return nil
		end

		if (col == nil) then
			col = 1
		end

		return fieldData.vals[col]
	end

	function this:setVal(field, val, col)
		local fieldData = this.fields[field]

		if (fieldData == nil) then
			this:addField('extra', field)

			fieldData = this.fields[field]
		end

		assert(fieldData, 'field '..tostring(field)..' not available')

		if (col == nil) then
			col = 1
		elseif (col == 'value') then
			col = 1
		elseif tonumber(col) then
			col = tonumber(col)
		end

		fieldData.vals[col] = val

		if (type(col) == 'number') then
			if (col > this.levelsAmount) then
				this.levelsAmount = col
			end

			if (val ~= nil) then
				if (col ~= 1) then
					fieldData.isArray = true
					this.arrayFields[field] = field
				end
			end

			if (fieldData.jassIdent == nil) then
				local jassType

				local level = 0
				local lastValType

				while ((level <= this.levelsAmount) and (jassType ~= 'string')) do
					local val = this:getVal(field, level)

					if (val ~= nil) then
						local valType = type(val)

						if ((jassType ~= nil) and (valType ~= lastValType)) then
							jassType = 'string'
						elseif (valType == 'boolean') then
							jassType = 'boolean'

							lastValType = valType
						elseif (valType == 'number') then
							if (jassType ~= 'real') then
								if math.isInt(val) then
									jassType = 'integer'
								else
									jassType = 'real'
								end

								lastValType = valType
							end
						else
							jassType = 'string'

							lastValType = valType
						end
					end

					level = level + 1
				end

				fieldData.jassType = jassType
			end
		end

		if (type(val) == 'table') then
			val.size = #val
		end

		if (col == 'array') then
			if val then
				fieldData.isArray = true
				this.arrayFields[field] = field
			else
				fieldData.isArray = false
				this.arrayFields[field] = nil
			end
		elseif ((col == 'jass ident') or (col == 'jassIdent')) then
			if (val ~= nil) then
				fieldData.jassIdent = val
				fieldData.jassType = val
			end
		end
	end

	function this:setDefVal(field, val, col)
		if (this.fields[field] == nil) then
			this:addField('extra', field)
		end

		local fieldData = this.fields[field]

		--assert(fieldData, 'field '..tostring(field)..' not available')

		if (this:getVal(field, col) == nil) then
			this:setVal(field, val, col)
		end
	end

	function this:addVal(field, val, col)
		local fieldData = this.fields[field]

		assert(fieldData, 'field '..tostring(field)..' not available')

		if ((col == 'array') or (col == 'jass ident') or (col == 'jassIdent')) then
			this:setVal(field, val, col)

			return
		end

		local prevVal = fieldData[col]

		if (prevVal == nil) then
			this:setVal(field, val, col)
		else
			if (type(prevVal) == 'table') then
				prevVal.size = prevVal.size + 1

				prevVal[prevVal.size] = val
			else
				local t = {}

				t[1] = prevVal
				t[2] = val

				t.size = 2

				this:setVal(field, t, col)
			end
		end
	end

	local function addVal(field, val, col)
		if (type(val) == 'string') then
			local t = val:split(';')

			for i = 1, #t, 1 do
				this:addVal(field, t[i], col)
			end
		else
			this:addVal(field, val, col)
		end
	end

	local function readFromFile0(path)
		assert(path, 'wc3objLib.create: no path given')


		--load grid

		local grid = {}
		local maxX
		local maxY

		local function loadIn()
			local file = io.open(path, 'r')

			local curY = 0

			for line in file:lines() do
				if line then
					local curX = 0
					curY = curY + 1

					grid[curY] = {}

					for i, s in pairs(line:split('\t')) do
						curX = curX + 1

						if ((maxX == nil) or (curX > maxX)) then
							maxX = curX
						end

						if (tonumber(s) ~= nil) then
							if ((grid[curY][1] == 'raw') or (grid[curY][1] == 'baseRaw')) then
								grid[curY][curX] = s
							else
								grid[curY][curX] = tonumber(s)
							end
						elseif (tobool(s) ~= nil) then
							grid[curY][curX] = tobool(s)
						else
							if (s == '') then
								s = nil
							end

							grid[curY][curX] = s
						end
					end
				end
			end

			file:close()

			maxY = curY
		end

		loadIn()

		local customCols

		if (grid[1][1] == 'field') then
			customCols = {}

			for x = 1, maxX, 1 do
				customCols[x] = grid[1][x]
			end
		end

		for y = 1, maxY, 1 do
			local field = grid[y][1]

			if (field ~= nil) then
				field = tostring(field)

				if ((field ~= '') and (field ~= 'field') and (field:find('//', 1, true) ~= 1)) then
					if (this.fields[field] == nil) then
						this:addCustomField(field)
					end

					for x = 1, maxX, 1 do
						local val = grid[y][x]

						local col

						if (customCols ~= nil) then
							col = customCols[x]
						else
							col = x - #this.fields[field].section.defaultCols
						end

						addVal(field, val, col)
					end
				end
			end
		end
	end

	local function readFromFile1(path)
		assert(path, 'wc3objLib.create: no path given')


		--load grid
		local grid = {}
		local maxX
		local maxY

		local function loadIn()
			local file = io.open(path, 'r')

			local curY = 0

			for line in file:lines() do
				if line then
					local curX = 0
					curY = curY + 1

					grid[curY] = {}

					for i, s in pairs(line:split('\t')) do
						curX = curX + 1

						if ((maxX == nil) or (curX > maxX)) then
							maxX = curX
						end

		                		if tonumber(s) then
							grid[curY][curX] = tonumber(s)
						elseif (tobool(s) ~= nil) then
							grid[curY][curX] = tobool(s)
						else
							if (s == '') then
								s = nil
							end

							grid[curY][curX] = s
						end
					end
				end
			end

			file:close()

			maxY = curY
		end

		loadIn()

		local customCols

		if (grid[1][1] == 'field') then
			customCols = {}

			for x = 1, maxX, 1 do
				customCols[x] = grid[1][x]
			end
		end

		for y = 1, maxY, 1 do
			local field = grid[y][1]

			if (field ~= nil) then
				field = tostring(field)

				if ((field ~= '') and (tonumber(field) == nil) and (field ~= 'field') and (field:find('//', 1, true) ~= 1)) then
					if (this.fields[field] == nil) then
						this:addCustomField(field)
					end

					for x = 1, maxX, 1 do
						if (grid[y][x] ~= nil) then
							local col

							if (customCols ~= nil) then
								col = customCols[x]
							else
								col = x - #this.fields[field].section.defaultCols
							end

							addVal(field, val, col)
						end
					end
				end
			end
		end

		return this
	end

	function this:writeToFile(path)
		assert(path, 'no path')

		assert(false, 'function not yet implemented')

		local f = io.open(path, 'w+')

		f:close()
	end

	function this:readFromFile(path)
		assert(path, 'no path')

		local f = io.open(path, 'r')

		local version = f:read()

		f:close()

		version = tonumber(version)

		if (version == 1) then
			readFromFile1(path)
		else
			readFromFile0(path)
		end

		this.path = path
	end

	return this
end

t.create = create

wc3objSheet = t