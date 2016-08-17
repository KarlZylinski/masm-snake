call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat"
nasm -fwin32 snake.asm -g
link /debug snake.obj xdisp.lib