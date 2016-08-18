call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat"
nasm -fwin32 snake.asm -g -Fcv8 -lsnake.lst
link /INCREMENTAL:NO /nodefaultlib snake.obj xdisp.lib /entry:main /subsystem:windows

rem legacy_stdio_definitions.lib legacy_stdio_wide_specifiers.lib ucrt.lib libvcruntime.lib libcmtd.lib