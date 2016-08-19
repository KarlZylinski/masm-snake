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
extern _xdisp_sleep

section .text

%macro movd_dword 2
    mov eax, dword [%2]
    mov dword [%1], eax
%endmacro

move_head:
    push ebp
    mov ebp, esp
    push ebx
    sub esp, 8

    ; save for setting new color later
    movd_dword ebp-4, head_x
    movd_dword ebp-8, head_y

    ; create a new tail movement dir on the block we're moving away from
    call encode_movement_dir
    mov bl, al
    mov ecx, dword [head_x]
    mov edx, dword [head_y]
    call index_from_pos
    add eax, map
    mov byte [eax], bl

    ; add movement dir to head pos
    mov eax, dword [head_x]
    add eax, dword [mov_dir_x]
    mov dword [head_x], eax
    mov eax, dword [head_y]
    add eax, dword [mov_dir_y]
    mov dword [head_y], eax

    ; check collision x
    mov eax, dword[head_x]
    cmp eax, 0
    jl .die
    cmp eax, board_size
    jge .die

    ; check collision y
    mov eax, dword[head_y]
    cmp eax, 0
    jl .die
    cmp eax, board_size
    jge .die

    ; check collision with map
    mov ecx, dword [head_x]
    mov edx, dword [head_y]
    call index_from_pos
    add eax, map
    mov ebx, eax ; save for eat_food removal
    cmp byte [eax], 5 ; 5 means theres food there
    je .eat_food
    cmp byte [eax], 0 ; nothing there
    je .draw

    .die:

    mov ebx, 0xFFFFFFFF
    .die_delay:
        sub ebx, 1
        cmp ebx, 0
        jne .die_delay
        jmp quit

    ; something else here, body part? fail!

    .eat_food: mov eax, dword [food_left]
    add eax, 2
    mov dword [food_left], eax
    mov byte [ebx], 0 ; remove food, gfx doesn't need removing. it is killed by head gfx

    .draw: 

    push 0
    push 155
    push 0
    push dword [ebp-8]
    push dword [ebp-4]
    call _xdisp_set
    add esp, 5*4

    push 0
    push 255
    push 0
    push dword [head_y]
    push dword [head_x]
    call _xdisp_set
    add esp, 5*4

    .e:
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; x in ecx, y in edx
index_from_pos:
    push ebp
    mov ebp, esp
    push ebx

    ; index is y * pitch + x
    mov eax, edx
    mov ebx, board_size
    mul ebx
    add eax, dword ecx

    pop ebx
    mov esp, ebp
    pop ebp
    ret


move_tail:
    push ebp
    mov ebp, esp
    sub esp, 4

    ; hide tail
    push 0
    push 0
    push 0
    push dword [tail_y]
    push dword [tail_x]
    call _xdisp_set
    add esp, 5*4

    ; find index
    mov ecx, dword [tail_x]
    mov edx, dword [tail_y]
    call index_from_pos
    mov dword [ebp-4], eax

    ; mov x pos by tail movement dir in map
    mov ecx, eax
    call decode_tail_move_x
    add eax, dword [tail_x]
    mov dword [tail_x], eax

    ; mov y pos by tail movement dir in map
    mov ecx, dword [ebp-4]
    call decode_tail_move_y
    add eax, dword [tail_y]
    mov dword [tail_y], eax

    ; clear in map so food can spawn there etc
    mov eax, [ebp-4]
    add eax, map
    mov byte [eax], 0

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

    call spawn_food

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
    jl .l
    mov eax, 2 ;right
    jmp .e
    .l:
    mov eax, 4 ;left
    jmp .e
    .y:
    cmp dword [mov_dir_y], 0
    je .e
    jg .d
    mov eax, 1 ;up
    jmp .e
    .d:
    mov eax, 3 ;down

    .e:
    mov esp, ebp
    pop ebp
    ret

decode_tail_move_x:
    push ebp
    mov ebp, esp

    mov eax, ecx
    mov ebx, dword [tail_x]
    add eax, map
    mov dl, byte [eax]
    cmp dl, 4
    je .l
    cmp dl, 2
    je .r
    mov eax, 0 ; no x movement
    jmp .e
    .r:
    mov eax, 1 ; right
    jmp .e
    .l:
    mov eax, -1 ; left

    .e:
    mov esp, ebp
    pop ebp
    ret

decode_tail_move_y:
    push ebp
    mov ebp, esp

    mov eax, ecx
    add eax, map
    mov dl, byte [eax]
    cmp dl, 1
    je .u
    cmp dl, 3
    je .d
    mov eax, 0 ; no y movement
    jmp .e
    .d:
    mov eax, 1 ; down
    jmp .e
    .u:
    mov eax, -1 ; up

    .e:
    mov esp, ebp
    pop ebp
    ret

spawn_food:
    push ebp
    mov ebp, esp
    sub esp, 4
    push ebx

    movss xmm0, dword [cur_time]
    comiss xmm0, dword [spawn_next_food_at]
    jb .e

    mov ebx, 10 ; try placing n times
    .try_get_num:
        ; get a number on [0, number of tiles],
        rdtsc
        and eax, 0xFFF
        mov edx, 0
        mov ecx, board_size*board_size
        div ecx

        mov eax, edx
        add eax, map
        mov cl, byte [eax]
        cmp cl, 0
        je .free

        sub ebx, 1 ; count down number of tries
        cmp ebx, 0
        jg .try_get_num
        jmp .e ; give up

    .free:
    mov byte [eax], 5 ; 5 means food here
    push 0
    push 0
    push 255
    mov eax, edx
    mov edx, 0
    mov ecx, board_size
    div ecx
    push eax ; y in result
    push edx ; x in remainder
    call _xdisp_set
    add esp, 5*4

    ; find a time to spawn next food
    rdtsc
    and eax, 0xF ; max 8 sec
    shr eax, 2 ; max 4 sec
    add eax, 1 ; 1 - 5 sec
    cvtsi2ss xmm0, eax
    addss xmm0, dword [cur_time]
    movss dword [spawn_next_food_at], xmm0

    .e:
    pop ebx
    mov esp, ebp
    pop ebp
    ret

_main:
    sub esp, 4
    mov dword [mov_dir_x], 1

    movd_dword head_x, start_pos_x
    movd_dword head_y, start_pos_y
    movd_dword tail_x, start_pos_x
    movd_dword tail_y, start_pos_y

    push tile_spacing
    push tile_size
    push board_size
    push window_title
    call _xdisp_init
    add esp, 4*4

    push 0
    push 255
    push 0
    push dword [head_x]
    push dword [head_y]
    call _xdisp_set
    add esp, 5*4

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
        jb .cont
        movss xmm0, dword [cur_time]
        movss dword [frame_start], xmm0
        call tick
        .cont:
        push 1
        call _xdisp_sleep
        add esp, 4
        call _xdisp_process_events
        call _xdisp_is_window_open
        cmp eax, 0
        jne .window_loop

    quit: mov eax, 0
    push 0
    call _ExitProcess@4
    ret

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
time_per_frame: dd 0.1
board_size equ 16
tile_size equ 32
tile_spacing equ 0
food_left: dd 2
spawn_next_food_at: dd 1.0
map: times board_size*board_size db 0 ; index is pos x * board_size + y