floor = math.floor
char = string.char
format = string.format
rep = string.rep
byte = string.byte
nerror = error
ntype = type
nprint = print

string.split = function(s, delimiter)
	if (s == nil) then
		return nil
	end
	if (s == '') then
		return {}
        end

	if (type(s) ~= 'string') then
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

function error(s, continue)
	if continue then
		print(s)
	else
		nerror(s)
	end
end

string.quote = function(s)
	return '"'..s..'"'
end

function isInt(a)
	return ((type(a) == 'number') and (floor(a) == a))
end

max = math.max
min = math.min

function limit(val, low, high)
	return max(low, min(val, high))
end

pow2Table = {}

for i = -256, 256, 1 do
	pow2Table[i] = math.pow(2, i)
end	

function pow2(i)
	return pow2Table[i]
end

pow256Table = {}

for i = 0, 4, 1 do
	pow256Table[i] = math.pow(256, i)
end	

function pow256(i)
	return pow256Table[i]
end

function nilTo0(a)
	if a then
		return a
	end

	return 0
end

log10 = math.log10
printRaw = io.write

function createLoadPercDisplay(max, title)
	local this = {}

	local curPerc
	local curVal = 0
	local revert = 0

	printRaw(title)

	function this:inc()
		curVal = curVal + 1

		if (curVal >= max) then
			revert = revert + title:len()

			printRaw(rep('\b', revert))
			printRaw(rep(' ', revert))
			printRaw(rep('\b', revert))

			curPerc = nil
			curVal = nil
			revert = nil
		else
			local newPerc = floor(curVal / max * 100)

			if (newPerc ~= curPerc) then
				if curPerc then
					printRaw(rep('\b', revert)..newPerc..'%')
				else
					printRaw(newPerc..'%')
				end

				curPerc = newPerc
				if (newPerc == 0) then
					revert = 2
				else
					revert = floor(log10(newPerc)) + 2
				end
			end
		end
	end

	return this
end