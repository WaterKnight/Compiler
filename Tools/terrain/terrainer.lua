local params = {...}

local buildPath = params[1]

local path = buildPath..[[\war3map.w3e]]
local path = [[war3map.w3e]]

require "wc3binaryFile"
require "wc3binaryMaskFuncs"

data = wc3binaryFile.create()

data.readFromFile(path, environmentMaskFunc)
print(data.getVal("centerX"), data.getVal("centerY"))
os.execute("pause")
local c=0

local t = os.clock()

for i = 1, data.getVal("height"), 1 do
	for i2 = 1, data.getVal("width"), 1 do
		--data.setVal("tile"..c.."groundHeight", 500)

		c=c+1
	end
end

print(os.clock() - t)

data.writeToFile("abc.w3e", environmentMaskFunc)