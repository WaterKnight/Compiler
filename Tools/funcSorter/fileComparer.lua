f1 = io.open("output.j", "r")
f2 = io.open("outputOld.j", "r")

input1=f1:read("*a")
input2=f2:read("*a")

if input1:len()~=input2:len() then
	print("different length")
end

f1:seek("set")
f2:seek("set")

line1=f1:read()

c=1

while line1 do
	line2 = f2:read()

	if line1~=line2 then
		print(c, line1, line2)
		os.execute("pause")
	end

	line1=f1:read()
	c=c+1
end

f1:close()
f2:close()

os.execute("pause")