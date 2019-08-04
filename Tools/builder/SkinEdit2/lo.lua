f=io.open("SkinMetaData.slk", r)

if f then
	print("success")
	f:close()
else
	print("fail")
end

print("lo")