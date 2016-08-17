global _main
extern _ExitProcess@4
extern _xdisp_init
extern _xdisp_deinit
extern _xdisp_process_events
extern _xdisp_set
extern _xdisp_is_window_open
extern _xdisp_left_held
extern _xdisp_up_held
extern _xdisp_right_held
extern _xdisp_down_held
extern _xdisp_time

section .text

move_player:
    enter 0, 3*4

    push 0
    push dword [pos_y]
    push dword [pos_x]
    call _xdisp_set
    add esp, 3*4
    mov eax, dword [pos_x]
    add eax, dword [mov_dir_x]
    mov dword [pos_x], eax    
    mov eax, dword [pos_y]
    add eax, dword [mov_dir_y]
    mov dword [pos_y], eax
    push 1
    push dword [pos_y]
    push dword [pos_x]
    call _xdisp_set
    add esp, 3*4

    leave
    ret

tick:
    enter 0, 0

    call move_player

    leave
    ret


read_input:
    enter 0, 0

    call _xdisp_left_held
    cmp eax, 0
    je .r
    mov dword [mov_dir_x], -1
    mov dword [mov_dir_y], 0
    jmp .e
    .r:
    call _xdisp_right_held
    cmp eax, 0
    je .u
    mov dword [mov_dir_x], 1
    mov dword [mov_dir_y], 0
    jmp .e
    .u:
    call _xdisp_up_held
    cmp eax, 0
    je .d
    mov dword [mov_dir_y], -1
    mov dword [mov_dir_x], 0
    jmp .e
    .d:
    call _xdisp_down_held
    cmp eax, 0
    je .e
    mov dword [mov_dir_y], 1
    mov dword [mov_dir_x], 0
    .e:

    leave
    ret

_main:
    push 0
    push 255
    push 0
    push 4
    push 64
    push 8
    push window_title
    call _xdisp_init
    add esp, 7*4

    push 1
    push dword [pos_x]
    push dword [pos_y]
    call _xdisp_set
    add esp, 3*4

    call _xdisp_time
    fstp dword [ebp-8]
    movss xmm0, dword [ebp-8]
    movss dword [frame_start], xmm0

    .window_loop:
        call read_input
        call _xdisp_time
        fstp dword [ebp-8]
        movss xmm0, dword [ebp-8]
        movss dword [cur_time], xmm0
        subss xmm0, dword [frame_start]
        comiss xmm0, dword [time_per_frame]
        jbe .cont
        movss xmm0, dword [cur_time]
        movss dword [frame_start], xmm0
        call tick
        .cont: call _xdisp_process_events
        call _xdisp_is_window_open
        cmp eax, 0
        jne .window_loop

    push 0
    call _ExitProcess@4

section .data
window_title: db "Snake!", 0
pos_x: dd 4
pos_y: dd 4
mov_dir_x: dd 0
mov_dir_y: dd 0
frame_start: dd 0.0
cur_time: dd 0.0
time_per_frame: dd 0.25