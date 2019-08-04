require 'waterlua'

local t = {}

local typeDefs = {}

t.typeDefs = typeDefs

for _, path in pairs(getFiles(io.local_dir()..[[Defs\]], '*.lua')) do
	local extension = getFileName(path, true)

	local f = loadfileSyntaxCheck(path, true)

	assert(f, 'could not open '..tostring(path))

	typeDefs[extension] = f
end

loaderLib = t