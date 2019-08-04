local params = {...}

rootPath = params[1]
buildPath = params[2]

assert(rootPath, 'no rootPath')
assert(buildPath, 'no buildPath')

local outputFile = io.open(rootPath..[[war3mapWEplacements.j]], "w+")

local binDir = [[D:\Warcraft III\Mapping\Compiler\Tools\wc3binary\]]

require 'wc3libs'

local war3mapUnits = wc3binaryFile.create()
local war3mapRects = wc3binaryFile.create()

war3mapUnits:readFromFile(buildPath..[[war3mapUnits.doo]], dooUnitsMaskFunc)
war3mapRects:readFromFile(buildPath..[[war3map.w3r]], rectMaskFunc)

local lines = {}
	
table.insert(lines, "struct preplaced")
	
table.insert(lines, "implement Allocation")
table.insert(lines, "implement List")
	
for i = 1, war3mapUnits:getVal("unitsCount"), 1 do
	local unit = war3mapUnits:getSub("unit"..i)

	local editorID = unit:getVal("editorID")

	table.insert(lines, "static thistype unit_"..editorID)
end
	
table.insert(lines, "boolean enabled")
table.insert(lines, "integer ownerIndex")
table.insert(lines, "integer typeId")
table.insert(lines, "real x")
table.insert(lines, "real y")
table.insert(lines, "real angle")
table.insert(lines, "thistype waygateTarget")

table.insert(lines, [[//! runtextmacro CreateList("UNITS")]])
	
table.insert(lines, "static method createUnit takes boolean enabled, integer typeId, integer ownerIndex, real x, real y, real angle, thistype waygateTarget returns thistype")
table.insert(lines, "local thistype this = thistype.allocate()")

table.insert(lines, "set this.enabled = enabled")
table.insert(lines, "set this.ownerIndex = ownerIndex")
table.insert(lines, "set this.typeId = typeId")
table.insert(lines, "set this.x = x")
table.insert(lines, "set this.y = y")
table.insert(lines, "set this.angle = angle")
table.insert(lines, "set this.waygateTarget = waygateTarget")
	
table.insert(lines, "call thistype.UNITS_Add(this)")
	
table.insert(lines, "return this")
table.insert(lines, "endmethod")
	
table.insert(lines, "static method initUnits")
	
for i = 1, war3mapUnits:getVal("unitsCount"), 1 do
	local unit = war3mapUnits:getSub("unit"..i)

	local enabled = boolToString(unit:getVal("targetAcquisition") ~= -2)
	local typeId = unit:getVal("type")
	local ownerIndex = unit:getVal("ownerIndex")
	local x = unit:getVal("x")
	local y = unit:getVal("y")
	local angle = string.format("%.3f", unit:getVal("angle"))
	local waygateTargetIndex = unit:getVal("waygateTargetRectIndex")
	local editorID = unit:getVal("editorID")

	local waygateTarget = "NULL"

	if (waygateTargetIndex > -1) then
		local rectNum = 1
		local rectCount = war3mapRects:getVal("rectsCount")

		while ((rectNum <= rectCount) and (war3mapRects:getSub("rect"..rectNum):getVal("index") ~= waygateTargetIndex)) do
			rectNum = rectNum + 1
		end

		if (rectNum <= rectCount) then
			waygateTarget = "rect_"..war3mapRects:getSub("rect"..rectNum):getVal("name"):gsub(" ", "_")
		end
	end

	local t = {}

	table.insert(t, enabled)
	table.insert(t, "'"..typeId.."'")
	table.insert(t, ownerIndex)
	table.insert(t, x)
	table.insert(t, y)
	table.insert(t, angle)
	table.insert(t, waygateTarget)

	table.insert(lines, "set thistype.unit_"..editorID.." = thistype.createUnit("..table.concat(t, ", ")..")")
end

table.insert(lines, "endmethod")

for i = 1, war3mapRects:getVal("rectsCount"), 1 do
	local unit = war3mapRects:getSub("rect"..i)

	local editorID = unit:getVal("name"):gsub(" ", "_")

	table.insert(lines, "static thistype rect_"..editorID)
end

table.insert(lines, "real minX")
table.insert(lines, "real minY")
table.insert(lines, "real maxX")
table.insert(lines, "real maxY")

table.insert(lines, [[//! runtextmacro CreateList("RECTS")]])

table.insert(lines, "static method createRect takes real minX, real maxX, real minY, real maxY returns thistype")
table.insert(lines, "local thistype this = thistype.allocate()")

table.insert(lines, "set this.minX = minX")
table.insert(lines, "set this.maxX = maxX")
table.insert(lines, "set this.minY = minY")
table.insert(lines, "set this.maxY = maxY")
table.insert(lines, "set this.x = (minX + maxX) / 2")
table.insert(lines, "set this.y = (minY + maxY) / 2")

table.insert(lines, "call this.RECTS_Add(this)")
	
table.insert(lines, "return this")
table.insert(lines, "endmethod")

table.insert(lines, "static method initRects")
	
for i = 1, war3mapRects:getVal("rectsCount"), 1 do
	local rect = war3mapRects:getSub("rect"..i)

	local minX = rect:getVal("minX")
	local maxX = rect:getVal("maxX")
	local minY = rect:getVal("minY")
	local maxY = rect:getVal("maxY")
	local name = rect:getVal("name"):gsub(" ", "_")

	local t = {}

	table.insert(t, minX)
	table.insert(t, maxX)
	table.insert(t, minY)
	table.insert(t, maxY)

	table.insert(lines, "set thistype.rect_"..name.." = thistype.createRect("..table.concat(t, ", ")..")")
end

table.insert(lines, "endmethod")

table.insert(lines, "endstruct")

outputFile:write(table.concat(lines, "\n"))

outputFile:close()