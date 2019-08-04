require 'waterlua'

local params = {...}

local mapPath = params[1]

assert(mapPath, "no map path given")

io.local_require([[..\..\portLib]])

local w3iPath = io.local_dir()..'tempPorted'..'\\'..'war3map.w3i'
local wtsPath = io.local_dir()..'tempPorted'..'\\'..'war3map.wts'

mpqExtract(mapPath, 'war3map.w3i', w3iPath)
mpqExtract(mapPath, 'war3map.wts', wtsPath)

io.local_require([[..\..\wc3binaryFile]])
io.local_require([[..\..\wc3binaryMaskFuncs]])

local root = wc3binaryFile.create()

if io.pathExists(w3iPath) then
	root:readFromFile(w3iPath, infoFileMaskFunc)
end

local t = root.subsByName

local author = root:getVal('mapAuthor')

if author then
	local pos, posEnd = author:find('TRIGSTR_')

	if (pos == 1) then
		local id = author:sub(posEnd + 1)
print('author', author, id, id:sub(id:find('[^0]')))
		local pos = id:find('[^0]')

		id = id:sub(pos)

		author = io.local_loadfile([[..\..\wtsParser.lua]])(wtsPath)[id]
print('id', id, author, mapPath)
		--[[local f = io.open(wtsPath, "r")

		local line = f:read() or ''

		while not line:find('STRING '..id) do
			line = f:read()
		end

		while line:find('{', 1, true) do
			line = f:read()
		end

		local capturedLines = {}

		while not line:find('}', 1, true) do
			capturedLines[#capturedLines + 1] = line

			line = f:read()
		end

		f:close()

		author = table.concat(capturedLines, '')]]
	end
end

return t, author