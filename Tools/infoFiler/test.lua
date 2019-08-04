local params = {...}

require "wc3binaryFile"
require "wc3binaryMaskFuncs"

data = wc3binaryFile.create()

data.readFromFile("war3map.w3i", infoFileMaskFunc)

data.setVal("loadingScreenIndex", 0)

data:print()

os.execute("pause")

data.writeToFile("D:\\war3map.w3i", infoFileMaskFunc)