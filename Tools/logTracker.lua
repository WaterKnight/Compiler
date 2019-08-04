require 'waterlua'

osLib.clearScreen()

require 'socket'

function sleep(timeout)
	socket.sleep(timeout)
end

local params = {...}

local folderPath = params[1]
local waitSignal = params[2]

assert(folderPath, 'no path')

if waitSignal then
	local filePath = folderPath..[[\signal.ini]]

	os.remove(filePath)

	print("waiting for signal...")

	while (file == nil) do
		sleep(0.1)
		file = io.open(filePath, "r")
	end

	file:close()

	os.remove(filePath)
end

local function readSessionId()
	local filePath = folderPath..[[\index.ini]]

	local file = io.open(filePath, "r")

	assert(file, "cannot open "..filePath)

	local input = file:read("*a")

	local search = [[SetPlayerName%(GetLocalPlayer%(%), "(%d+)"%)]]

	local pos, posEnd, sessionId = input:find(search)

	file:close()

	return sessionId
end

local sessionId = readSessionId()

print("sessionId: "..sessionId)

os.execute("mode con:lines=550")

local lines = {}
local linesC = 0

fileMaxLines = 499

local fileIndex = 0

local mergesLinesI
local mergesLinesTable

while true do
	local fileLines = {}
	local fileLinesC = 0
	local filePath = folderPath..[[\Session]]..sessionId..[[\log_]]..fileIndex..[[.txt]]

	print(filePath)

	mergesLinesI = 0

	while (fileLinesC < fileMaxLines) do
		local file = io.open(filePath, "rb")

		while (file == nil) do
			sleep(0.1)

			file = io.open(filePath, "rb")
		end

		local function convLine(line)
			if (line == nil) then
				return
			end

			local pos, posEnd = line:find([[	call Preload( "")]], 1, true)

			if ((pos == nil) or (pos ~= 1)) then
				return
			end

			line = line:sub(posEnd + 1, line:len() - 3)

			return line
		end

		fileLinesC = 0

		local rawString = file:read("*a")

		local rawLines = rawString:split(string.char(13)..string.char(10))

		--local rawLine = file:read()
		local rawLineI = 1

		local rawLine = rawLines[1]

		while rawLine do
			local line = convLine(rawLine)

			if line then
				fileLinesC = fileLinesC + 1
				fileLines[fileLinesC] = line
			end

			--rawLine = file:read()
			rawLineI = rawLineI + 1
			rawLine = rawLines[rawLineI]
		end

		file:close()

		for i = linesC % fileMaxLines + 1, fileLinesC, 1 do
			local line = fileLines[i]

			linesC = linesC + 1
			lines[linesC] = line

			local pos, posEnd = line:find(":cmd")

			if (pos == 1) then
				local t = line:sub(posEnd + 1):split(" ")

				for i = 1, #t, 1 do
					local field
					local val

					local pos, posEnd = t[i]:find("=")

					if pos then
						field = t[i]:sub(1, pos - 1)
						val = t[i]:sub(posEnd + 1)
					end

					if (field == "mergeLines") then
						mergesLinesI = tonumber(val)
						mergesLinesTable = {}
					end
				end
			else
				if (mergesLinesI > 0) then
					mergesLinesI = mergesLinesI - 1
					mergesLinesTable[#mergesLinesTable + 1] = line

					if (mergesLinesI == 0) then
						print(table.concat(mergesLinesTable, ""))
					end
				else
					print(line)
				end
			end
		end

		sleep(0.1)
	end
print("next file")
	fileIndex = fileIndex + 1
end