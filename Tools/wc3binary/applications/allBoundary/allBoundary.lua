require 'waterlua'

local params = {...}

local inputPath = params[1]
local w3iPath = params[2]
local outputPath = params[3]
local outputW3iPath = params[4]

local f = io.open(inputPath, "r")

assert(f, "cannot open "..inputPath)

f:close()

package.path = package.path..";../../?.lua"

io.local_require([[..\..\wc3binaryFile]])
io.local_require([[..\..\wc3binaryMaskFuncs]])

local root = wc3binaryFile.create()

root:readFromFile(inputPath, envMaskFunc)

local tilesCount = root:getVal('height') * root:getVal('width')

for i=1, tilesCount, 1 do
	local tile = root:getSub('tile'..format('%i', i))

--	for k, v in pairs(tile:getSub('boundary')) do
--		print(k, "->", v)
--	end

	tile:getSub('boundary').val=1
	tile:getSub('boundary2').val=1
end

root:print('out.txt')

root:writeToFile(outputPath, envMaskFunc)

local rootW3i = wc3binaryFile.create()

local f = io.open(w3iPath, "r")

assert(f, "cannot open "..w3iPath)

f:close()

rootW3i:readFromFile(w3iPath, infoFileMaskFunc)

for k, v in pairs(rootW3i.subsByName) do
	print(k, "->", v)
end

for i=1, 8, 1 do
	rootW3i:getSub('cameraBounds'..i):setVal(0)
end

rootW3i:getSub('mapHeightWithoutBoundaries'):setVal(0)

rootW3i:getSub('boundaryMarginBottom'):setVal(1000)

rootW3i:print('outW3i.txt')

rootW3i:writeToFile(outputW3iPath, infoFileMaskFunc)