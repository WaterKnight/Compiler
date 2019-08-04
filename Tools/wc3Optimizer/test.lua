params = {...}

local t = os.clock()

require 'alien'

for k, v in pairs(alien) do
	print(k, "->", v, type(v))
end

local SFmpq=alien.load("Storm.dll")

print("---", SFmpq, "---")

local open = SFmpq.SFileGetFileInfo

--open:types{ ret = 'pointer', abi = 'stdcall', 'string' , 'long', 'long', 'pointer' }

for k, v in pairs(SFmpq) do
	print(k, "->", v, type(v))
end

--os.execute('@echo | call "starter.bat" "'..params[1]..'" "'..params[2]..'"')

print(os.clock()-t)

os.execute("pause")