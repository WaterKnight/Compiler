require "stringLib"

params = {...}

buildPath = params[1]
buildNum = params[2]

log = io.open("log.txt", "w+")

log:write(table.concat(params, "\n"))

if buildPath then
	os.execute([[copy >NUL ]]..(buildPath..[[\war3map.w3i]]):quote()..[[ input.w3i]])
end

local success = (os.execute([[lua setInfoFile.lua "input.w3i" ]]..tostring(buildNum):quote()) == 0)

if success then
	if buildPath then
		os.execute([[copy >NUL ]]..[[ output.w3i ]]..(buildPath..[[\war3map.w3i]]):quote())
	end
end

log:close()