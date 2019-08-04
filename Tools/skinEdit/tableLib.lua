function tableContains(t, e)
	if (t == nil) then
		return false
	end

	for k, v in pairs(t) do
		if (v == e) then
			return true
		end
	end

	return false
end

function getTableSize(t, nested)
	local c = 0

	for k, val in pairs(t) do
		if (nested and (type(val) == "table")) then
			c = c + getTableSize(val, true)
		else
			c = c + 1
		end
	end

	return c
end

function copyTable(source)
	local result

	if (source == nil) then
		return nil
	end

	result = {}

	for k, v in pairs(source) do
		if (type(v) == "table") then
			result[k] = copyTable(v)
		else
			result[k] = v
		end
	end

	return result
end

function mergeTable(source, toAdd)
	for k, v in pairs(toAdd) do
		if v then
			if (type(v) == "table") then
				if (type(source[k]) ~= "table") then
					source[k] = {}
				end

				mergeTable(source[k], v)
			else
				source[k] = v
			end
		end
	end
end

require "stringLib"

function printTable(t, nestDepth)
	if (nestDepth == nil) then
		nestDepth = 0
	end

	for k, v in pairs(t) do
		if (type(v) == "table") then
			print(string.rep("\t", nestDepth).."//"..k)

			if (nestDepth ~= false) then
				printTable(v, nestDepth + 1)
			end
		else
			if (type(v) == "boolean") then
				v = boolToString(v)
			end

			print(string.rep("\t", nestDepth)..k.." --> "..v)
		end
	end
end