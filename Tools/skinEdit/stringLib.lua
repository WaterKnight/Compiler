function tobool(s)
	if (s == "true") then
		return true
	end
	if (s == "false") then
		return false
	end

	return nil
end

function boolToString(b)
	if b then
		return "true"
	end

	return "false"
end

function trimString(s, rem)
    while s:find(rem, 1, true) do
        s = s:sub(1, s:find(rem, 1, true) - 1)..s:sub(s:find(rem, 1, true) + 1)
    end

    return s
end

string.quote = function(s)
    return "\""..s.."\""
end

function quote(s)
	return string.quote(s)
end

string.dequote = function(s)
	i = 1
	
	while (i <= s:len()) do
	    if (s:sub(i, i) == [["]]) then
	        s = s:sub(1, i - 1)..s:sub(i + 1)
	    else
	        i = i + 1
	    end
	end
	
	return s
end

function dequote(s)
	return string.dequote(s)
end

string.split = function(s, delimiter)
	if (s == nil) then
		return nil
	end
	if (s == "") then
		return {}
        end

	if (type(s) ~= "string") then
		s = tostring(s)
	end

	local results = {}
	local resultsCount = 0
	
	while s:find(delimiter) do
	    resultsCount = resultsCount + 1
	
	    results[resultsCount] = s:sub(1, s:find(delimiter) - 1)
	
	    s = s:sub(s:find(delimiter) + 1)
	end
	
	resultsCount = resultsCount + 1
	
	results[resultsCount] = s
	
	return results
end

string.doubleBackslashes = function(s)
    return string.gsub(s, "\\", "\\\\")
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

function safeString(s)
	if (s == nil) then
		return "nil"
	end
	if (type(s) == "boolean") then
		return boolToString(s)
	end
	if (type(s) == "table") then
		return "{table}"
	end

	return s
end

function concat(a, b)
	return (safeString(a)..safeString(b))
end

function isPlainText(s)
	if s:find("\\") then
		return true
	end

	while s:find(".", 1, true) do
		s = s:sub(s:find(".", 1, true) + 1)
	end

	if (s == "") then
		return true
	end
	if (tonumber(s) or ((s:sub(1, 1) == "'") and (s:sub(s:len(), s:len()) == "'"))) then
		return false
	end
	if (s:len() == 4) then
		return true
	end

	local c = 1

	local ch = s:sub(c, c)

	while ((((ch >= 'A') and (ch <= 'Z')) or tonumber(ch) or (ch == "_")) and (c <= s:len())) do
		c = c + 1

		ch = s:sub(c, c)
	end

	if (c > s:len()) then
		return false
	end

	return true
end