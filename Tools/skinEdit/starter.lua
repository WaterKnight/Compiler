require "stringLib"

params = {...}

rootPath = params[1]
buildPath = params[2]

local success = (os.execute("lua skinEditor.lua "..rootPath:quote().." "..buildPath:quote()) == 0)

if success then
	os.execute([[copy >NUL ]]..[[ output.txt ]]..(buildPath..[[\war3mapSkin.txt]]):quote())
end