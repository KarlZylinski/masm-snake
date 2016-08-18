call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat"
nasm -fwin32 snake.asm -g -Fcv8 -lsnake.lst
link /debug /INCREMENTAL:NO /nodefaultlib libcmtd.lib snake.obj xdisp.lib /entry:main

rem legacy_stdio_definitions.lib legacy_stdio_wide_specifiers.lib ucrt.lib libvcruntime.lib libcmtd.lib