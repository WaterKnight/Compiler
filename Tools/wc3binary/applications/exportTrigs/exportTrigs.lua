string.quote = function(s)
    return '"'..s..'"'
end

function quote(s)
	return string.quote(s)
end

string.lastFind = function(s, target)
	local result = 0

	while s:find(target, result + 1, true) do
		result = s:find(target, result + 1, true)
	end

	if (result == 0) then
		return nil
	end

	return result
end

function lastFind(s, target)
	return string.lastFind(s, target)
end

function getFileName(s, noExtension)
	while s:find("\\") do
		s = s:sub(s:find("\\") + 1)
	end

	if noExtension then
		if s:lastFind(".") then
			s = s:sub(1, s:lastFind(".") - 1)
		end
	end

	return s
end

function getFolder(s)
	res = ""

	while s:find("\\") do
		res = res..s:sub(1, s:find("\\"))

		s = s:sub(s:find("\\") + 1)
	end

	return res
end

local params = {...}

local wctPath = params[1]

os.execute("cls")

assert(wctPath, "no path given")

print("wctPath: "..wctPath)

local wtgPath = wctPath:sub(1, wctPath:len() - 4)..".wtg"

print("wtgPath: "..wtgPath)

local f = io.open(wctPath, "r")

assert(f, "cannot open (.wct) "..wctPath)

f:close()

local f = io.open(wtgPath, "r")

assert(f, "cannot open (.wtg) "..wtgPath)

f:close()

package.path = package.path..";../../?.lua"

require "wc3binaryFile"
require "wc3binaryMaskFuncs"

local root = wc3binaryFile.create()
local rootGui = wc3binaryFile.create()

root:readFromFile(wctPath, wctMaskFunc)
rootGui:readFromFile(wtgPath, guiTrigMaskFunc)

local outputFolder = getFolder(wctPath)..[[\]]..[[exportTrigs_]]..getFileName(wctPath, true)

os.execute('rmdir 2>NUL /s /q '..outputFolder:quote())

os.execute('mkdir 2>NUL '..outputFolder:quote())

local f = io.open(outputFolder..[[\]].."header.j", "wb+")

local trig = root:getSub('headTrig')

local text = trig:getVal('text')

f:write(text)

f:close()

local catsByIndex = {}

for i = 1, rootGui:getVal('trigCategoriesAmount'), 1 do
	local cat = rootGui:getSub('trigCategory'..i)

	local index = cat:getVal('index')

	catsByIndex[index] = cat
end

local folderPaths = {}

for i = 1, root:getVal('trigsCount'), 1 do
	local trig = root:getSub('trig'..i)
	local trigGui = rootGui:getSub('trig'..i)

	local catIndex = trigGui:getVal('categoryIndex')

	local cat = catsByIndex[catIndex]

	local catName = cat:getVal('name')	

	local folderPath = outputFolder..[[\]]..catName
	local filePath = folderPath..[[\]]..trigGui:getVal('name')..".j"

	if (folderPaths[folderPath] == nil) then
		folderPaths[folderPath] = folderPath

		os.execute('mkdir 2>NUL '..folderPath:quote())
	end

	local f = io.open(filePath, "wb+")

	local text = trig:getVal('text')

	f:write(text)

	f:close()
end