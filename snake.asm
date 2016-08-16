global _main
extern _ExitProcess@4
extern _xdisp_init
extern _xdisp_deinit
extern _xdisp_process_events
extern _xdisp_set
extern _xdisp_display
extern _xdisp_is_window_open

section .text
_main:
    push 50
    push 220
    push 70
    push 4
    push 64
    push 8
    push window_title
    call _xdisp_init
    add esp, 7*4

    push 1
    push 2
    push 3
    call _xdisp_set
    add esp, 3*4

    call _xdisp_display

    .window_loop:
        call _xdisp_process_events
        call _xdisp_is_window_open
        cmp eax, 0
        jne .window_loop

    push 0
    call _ExitProcess@4

section .data
window_title: db "Snake!", 0
move: dd 0
color: dd 0
