os.execute("cls")

require "wc3binaryFile"
require "wc3binaryMaskFuncs"

root = wc3binaryFile.create()

root:readFromFile('war3map.wtg', guiTrigMaskFunc)

root:getSub('trig1'):setVal('enabled', 0)

root:getSub('trig1'):print()

root:print("print.txt")

root:writeToFile('output.wtg', guiTrigMaskFunc)