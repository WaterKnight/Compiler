f1 = io.open("abc.wtg", "rb")
f2 = io.open("D:\\war3map4.wtg", "rb")

input1=f1:read("*a")
input2=f2:read("*a")

if input1:len()~=input2:len() then
	print("different length")
end

for i=1, input1:len(), 1 do
	if input1:sub(i, i)~=input2:sub(i,i) then
		print(i, input1:sub(i, i):byte(), "-->", input2:sub(i, i):byte())
	end
end

f1:close()
f2:close()