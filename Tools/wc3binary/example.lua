os.execute("cls")

require "wc3binaryFile"
require "wc3binaryMaskFuncs"

root = wc3binaryFile.create()

root:readFromFile('war3map.w3i', infoFileMaskFunc)

root:print("print.txt")