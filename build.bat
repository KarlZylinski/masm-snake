call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat"
nasm -fwin32 snake.asm -g -Fcv8 -lsnake.lst
link /debug /INCREMENTAL:NO /nodefaultlib libcmtd.lib snake.obj xdisp.lib /entry:main /subsystem:windows