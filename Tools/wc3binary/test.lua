os.execute("cls")

require "wc3binaryFile"
require "wc3binaryMaskFuncs"

root = wc3binaryFile.create()
rootGui = wc3binaryFile.create()

--root:readFromFile('war3map.w3a', objExMaskFunc)

--root:print("print.txt")

--root:writeToFile('output.w3a', objExMaskFunc)

--root:readFromFile('war3map.w3r', rectMaskFunc)

root:readFromFile('war3map.wct', wctMaskFunc)
rootGui:readFromFile('war3map.wtg', guiTrigMaskFunc)

root:print("print.txt")
rootGui:print("print2.txt")

os.execute('rmdir /s /q output')

catsByIndex = {}

for i = 1, rootGui:getVal('trigCategoriesAmount'), 1 do
	local cat = rootGui:getSub('trigCategory'..i)

	local index = cat:getVal('index')

	catsByIndex[index] = cat
end

for i = 1, root:getVal('trigsCount'), 1 do
	local trig = root:getSub('trig'..i)
	local trigGui = rootGui:getSub('trig'..i)

	local catIndex = trigGui:getVal('categoryIndex')

	local cat = catsByIndex[catIndex]

	local catName = cat:getVal('name')	

	local folderPath = [[output\]]..catName
	local filePath = folderPath..[[\]]..trigGui:getVal('name')..".j"

	print(filePath)

	os.execute('mkdir '..folderPath)

	local f = io.open(filePath, "wb+")

	local text = trig:getVal('text')

	f:write(text)

	f:close()
end