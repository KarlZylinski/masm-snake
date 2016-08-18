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

move_head:
    push ebp
    mov ebp, esp
    push edx

    call encode_movement_dir
    mov dl, al
    call head_index_from_pos
    add eax, tail_directions
    mov byte [eax], dl

    mov eax, dword [head_x]
    add eax, dword [mov_dir_x]
    mov dword [head_x], eax
    mov eax, dword [head_y]
    add eax, dword [mov_dir_y]
    mov dword [head_y], eax
    push 1
    push dword [head_y]
    push dword [head_x]
    call _xdisp_set
    add esp, 3*4

    pop edx
    mov esp, ebp
    pop ebp
    ret

head_index_from_pos:
    push ebp
    mov ebp, esp
    push edx

    ; index is y * pitch + x
    mov eax, dword [head_y]
    mov edx, board_size
    mul edx
    add eax, dword [head_x]

    pop edx
    mov esp, ebp
    pop ebp
    ret

tail_index_from_pos:
    push ebp
    mov ebp, esp
    push edx

    ; index is y * pitch + x
    mov eax, dword [tail_y]
    mov edx, board_size
    mul edx
    add eax, dword [tail_x]

    pop edx
    mov esp, ebp
    pop ebp
    ret

move_tail:
    push ebp
    mov ebp, esp
    push ebx

    push 0
    push dword [tail_y]
    push dword [tail_x]
    call _xdisp_set
    add esp, 3*4

    mov ebx, dword [tail_x]
    call decode_tail_move_x
    add ebx, eax
    mov dword [tail_x], ebx

    mov ebx, dword [tail_y]
    call decode_tail_move_y
    add ebx, eax
    mov dword [tail_y], ebx

    pop ebx
    mov esp, ebp
    pop ebp
    ret

tick:
    push ebp
    mov ebp, esp

    cmp dword [food_left], 0
    jg .tick_food

    call move_tail
    call move_head
    jmp .e

    .tick_food:
    mov eax, dword [food_left]
    sub eax, 1
    mov dword [food_left], eax
    call move_head

    .e:
    mov esp, ebp
    pop ebp
    ret


read_input:
    push ebp
    mov ebp, esp

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

    mov esp, ebp
    pop ebp
    ret

encode_movement_dir:
    push ebp
    mov ebp, esp

    cmp dword [mov_dir_x], 0
    je .y
    jl .nx
    mov eax, 1 ;right
    jmp .e
    .nx:
    mov eax, 3 ;left
    jmp .e
    .y:
    cmp dword [mov_dir_y], 0
    je .e
    jl .ny
    mov eax, 0 ;up
    jmp .e
    .ny:
    mov eax, 2 ;down

    .e:
    mov esp, ebp
    pop ebp
    ret

decode_tail_move_x:
    push ebp
    mov ebp, esp
    push edx

    call tail_index_from_pos
    add eax, tail_directions
    mov dl, byte [eax]
    cmp dl, 3
    je .l
    cmp dl, 1
    je .r
    mov eax, 0 ; no x movement
    jmp .e
    .r:
    mov eax, 1 ; right
    jmp .e
    .l:
    mov eax, -1 ; left

    .e:
    pop edx
    mov esp, ebp
    pop ebp
    ret

decode_tail_move_y:
    push ebp
    mov ebp, esp
    push edx

    call tail_index_from_pos
    add eax, tail_directions
    mov dl, byte [eax]
    cmp dl, 0
    je .u
    cmp dl, 2
    je .d
    mov eax, 0 ; no x movement
    jmp .e
    .d:
    mov eax, 1 ; down
    jmp .e
    .u:
    mov eax, -1 ; up

    .e:
    pop edx
    mov esp, ebp
    pop ebp
    ret

%macro movd_dword 2
    mov eax, dword [%2]
    mov dword [%1], eax
%endmacro

_main:
    sub esp, 4

    mov dword [mov_dir_x], -1
    call encode_movement_dir
    mov dl, al

    movd_dword head_x, start_pos_x
    movd_dword head_y, start_pos_y
    movd_dword tail_x, start_pos_x
    movd_dword tail_y, start_pos_y
    call tail_index_from_pos
    add eax, tail_directions
    mov byte [eax], dl

    push 0
    push 255
    push 0
    push 4
    push 64
    push board_size
    push window_title
    call _xdisp_init
    add esp, 7*4

    push 1
    push dword [head_x]
    push dword [head_y]
    call _xdisp_set
    add esp, 3*4

    call _xdisp_time
    fstp dword [ebp-4]
    movss xmm0, dword [ebp-4]
    movss dword [frame_start], xmm0

    .window_loop:
        call read_input
        call _xdisp_time
        fstp dword [ebp-4]
        movss xmm0, dword [ebp-4]
        movss dword [cur_time], xmm0
        subss xmm0, dword [frame_start]
        comiss xmm0, dword [time_per_frame]
        jbe .cont
        movss xmm0, dword [cur_time]
        movss dword [frame_start], xmm0
        call tick
        .cont:
        call _xdisp_process_events
        call _xdisp_is_window_open
        cmp eax, 0
        jne .window_loop

    push 0
    call _ExitProcess@4

section .data
window_title: db "Snake!", 0
head_x: dd 0
head_y: dd 0
tail_x: dd 0
tail_y: dd 0
start_pos_x: dd 4
start_pos_y: dd 4
mov_dir_x: dd 0
mov_dir_y: dd 0
frame_start: dd 0.0
cur_time: dd 0.0
time_per_frame: dd 0.25
board_size equ 8
food_left: dd 3
tail_directions: times board_size*board_size db 0 ; index is pos x * board_size + y