local params = {...}

local map = params[1]
local thisPath = [[D:\Warcraft III\Mapping\DWC\Tools\ObjectMorpher]]
local targetPath = thisPath..[[\Input]]

os.execute("mkdir "..[["]]..targetPath..[["]])

os.execute([[D:/Warcra~1/Mapping/DWC/Tools/jassnewgenpack5d/grimext/FileExporter.exe "]]..map..[[" "]]..thisPath..[[" "]]..targetPath)

os.execute([[lua objectMorpher.lua "Input"]])