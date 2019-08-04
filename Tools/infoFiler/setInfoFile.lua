require 'waterlua'

local params = {...}

local inputPath = params[1]
local buildNum = tonumber(params[2])

io.local_require[[..\wc3binary\wc3binaryFile]]
io.local_require[[..\wc3binary\wc3binaryMaskFuncs]]

data = wc3binaryFile.create()

print('input', inputPath, buildNum)

data:readFromFile(inputPath, infoFileMaskFunc)

osLib.pause()

io.local_require[[..\builder\wc3objLib]]

local obj = module_wc3objLib.createObj('wc3obj')

obj:readFromFile('mapInfo.wc3obj')

data:setVal('mapName', obj:getVal('name', 1)..' '..buildNum)
data:setVal('savesAmount', buildNum)
data:setVal('mapAuthor', obj:getVal('author', 1))

data:setVal('loadingScreenIndex', obj:getVal('loadingScreenIndex', 1))
data:setVal('loadingScreenModelPath', obj:getVal('loadingScreenModelPath', 1))

data:writeToFile('output.w3i', infoFileMaskFunc)

osLib.ack()