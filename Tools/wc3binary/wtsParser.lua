local params = {...}

local wtsPath = params[1]

assert(wtsPath, 'no wts path given')

local f = io.open(wtsPath, "rb")

local line = f:read('*a')

f:close()

line = line:gsub('//[^\n]*\n', '')

local t = {}

for k, v in line:gmatch('STRING ([%d]+)[\n%s]*{([^}]*)[\n]*}') do
	local key = k
	local val = v

	val = val:match('^%c*(.*)')
	val = val:match('^(.*%C)')

	t[key] = val
end

return t