params = {...}

map = params[1]

f = io.open(map, "rb")

if f then
	print("addHeader")

	orig = f:read("*a")

	f:close()

	f = io.open(map, "wb")

	if f then
		local function writeInt(val)
			for i = 0, 3, 1 do
				f:write(string.char(math.floor(val % math.pow(256, i + 1) / math.pow(256, i))))
			end
		end

		local function writeId(val)
			f:write(val)
		end

		local function writeString(val)
			f:write(val..string.char(0))
		end

		writeId("HM3W")

		writeInt(0) --unknown
		writeString("dwc")

		local flags = {}
		local flagsInt = 0

		flags[1] = true --hide minimap
		flags[2] = false --modify ally priorities
		flags[3] = true --melee map
		flags[4] = false --initial map size large, never modified
		flags[5] = false --masked areas partially visible
		flags[6] = false --fixed player force setting
		flags[7] = false --use custom forces
		flags[8] = false --use custom techtree
		flags[9] = false --use custom abilities
		flags[10] = false --use custom upgrades
		flags[11] = false --map properties window opened before
		flags[12] = false --show water waves on cliff shores
		flags[13] = false --show water waves on rolling shores

		local c = 1

		while (flags[c] ~= nil) do
			--if flags[c] then
				flagsInt = flagsInt + math.pow(2, c - 1)
			--end

			c = c + 1
		end

		writeInt(flagsInt)

		writeInt(7) --max players

		while (f:seek("end") < 512) do
			f:write(string.char(0))
		end

		f:write(orig)
	else
		print("addHeader - could not write file")
	end
else
	print("addHeader - could not read file")
end