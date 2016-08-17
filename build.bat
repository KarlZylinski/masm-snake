call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat"
nasm -fwin32 snake.asm -g -Fvc8 -lsnake.lst
link /debug snake.obj xdisp.lib /entry:main