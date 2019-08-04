del %2

start /wait /min "" "%~dp0VXJWTSOPT.exe" --checkscriptstuff --tweak "%~dp0options.vxtweak" %1 --do %2 --exit

del %2.j

pause