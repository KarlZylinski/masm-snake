call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat"
nasm -fwin32 snake.asm -g -Fcv8 -lsnake.lst
link /debug /INCREMENTAL:NO snake.obj xdisp.lib /entry:main