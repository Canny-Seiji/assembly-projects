; Command to run: nasm -f elf32 calculator.asm -o calculator.o && ld -m elf_i386 calculator.o -o calculator && ./calculator

%define SYS_EXIT  1
%define SYS_READ  3
%define SYS_WRITE 4
%define STDIN     0
%define STDOUT    1

section .data
    ; ANSI Color Escape Codes
    CLR_RESET db 27, "[0m", 0
    CLR_CYAN  db 27, "[1;36m", 0
    CLR_YEL   db 27, "[1;33m", 0
    CLR_GREEN db 27, "[1;32m", 0
    CLR_RED   db 27, "[1;31m", 0
    CLR_WHITE db 27, "[1;37m", 0

    ; Styled & Enclosed Menu Box Layout
    menu db 27, "[2J", 27, "[H"                           ; Clear screen & home cursor
         db 27, "[1;36m"
         db "+==========================================+", 10
         db "| ", 27, "[1;37m", "             CALCULATOR MENU            ", 27, "[1;36m", " |", 10
         db "+==========================================+", 10
         db "|                                          |", 10
         db "|  ", 27, "[1;33m", "[A] ", 27, "[1;37m", "Add Numbers                        ", 27, "[1;36m", " |", 10
         db "|  ", 27, "[1;33m", "[S] ", 27, "[1;37m", "Subtract Numbers                   ", 27, "[1;36m", " |", 10
         db "|  ", 27, "[1;33m", "[M] ", 27, "[1;37m", "Multiply Numbers                   ", 27, "[1;36m", " |", 10
         db "|  ", 27, "[1;33m", "[D] ", 27, "[1;37m", "Divide Numbers                     ", 27, "[1;36m", " |", 10
         db "|                                          |", 10
         db "+==========================================+", 10
         db 27, "[0m", 0

    prompt_opt  db 27, "[1;36m", "Enter your choice: ", 27, "[0m", 0
    prompt_num1 db "Enter first number: ", 0
    prompt_num2 db "Enter second number: ", 0

    msg_sum     db 27, "[1;32m", "The sum is ", 27, "[0m", 0
    msg_diff    db 27, "[1;32m", "The difference is ", 27, "[0m", 0
    msg_prod    db 27, "[1;32m", "The product is ", 27, "[0m", 0
    msg_quot    db 27, "[1;32m", "The quotient is ", 27, "[0m", 0
    msg_rem     db 27, "[1;33m", "Remainder: ", 27, "[0m", 0
    msg_err_div db 27, "[1;31m", "Error: Division by zero!", 27, "[0m", 10, 0
    msg_invalid db 27, "[1;31m", "Invalid option!", 27, "[0m", 10, 0
    prompt_again db 10, "Do you want to try again (Y/N): ", 0
    newline      db 10, 0

section .bss
    choice      resb 4
    num_str     resb 16
    out_buf     resb 16
    val1        resd 1
    val2        resd 1

section .text
    global _start

_start:
main_loop:
    ; 1. Display Menu & Prompts
    mov esi, menu
    call print_string

    mov esi, prompt_opt
    call print_string

    mov ecx, choice
    mov edx, 4
    call read_input

    ; Uppercase conversion
    mov al, [choice]
    and al, 0xDF                    

    ; Validate Choice is IN ('A', 'S', 'M', 'D')
    cmp al, 'A'
    je .valid
    cmp al, 'S'
    je .valid
    cmp al, 'M'
    je .valid
    cmp al, 'D'
    jne .invalid

.valid:
    mov [choice], al

    ; 2. Input First & Second Numbers
    mov esi, prompt_num1
    call get_number
    mov [val1], eax

    mov esi, prompt_num2
    call get_number
    mov [val2], eax

    ; 3. Execute Selected Operation
    mov al, [choice]
    mov eax, [val1]

    cmp byte [choice], 'A'
    je .do_add
    cmp byte [choice], 'S'
    je .do_sub
    cmp byte [choice], 'M'
    je .do_mul

    ; Division handling
    mov ebx, [val2]
    test ebx, ebx
    jz .div_zero
    cdq                             ; Sign-extend EAX into EDX:EAX
    idiv ebx                        ; EAX = quotient, EDX = remainder
    
    push edx                        ; Save remainder on stack
    push eax                        ; Save quotient on stack

    ; Print Quotient Label and Value
    mov esi, msg_quot
    call print_string
    pop eax                         ; Restore quotient
    mov edi, out_buf
    call int_to_string
    mov esi, CLR_GREEN
    call print_string
    mov esi, out_buf
    call print_string
    mov esi, CLR_RESET
    call print_string
    mov esi, newline
    call print_string

    ; Check if remainder exists (EDX != 0)
    pop edx                         ; Restore remainder
    test edx, edx
    jz ask_again                    ; If remainder is 0, skip remainder printing

    ; Print Remainder Label and Value
    push edx
    mov esi, msg_rem
    call print_string
    pop eax                         ; Pass remainder to int_to_string
    mov edi, out_buf
    call int_to_string
    mov esi, CLR_YEL
    call print_string
    mov esi, out_buf
    call print_string
    mov esi, CLR_RESET
    call print_string
    mov esi, newline
    call print_string
    jmp ask_again

.do_add:
    add eax, [val2]
    mov esi, msg_sum
    jmp .print_result

.do_sub:
    sub eax, [val2]
    mov esi, msg_diff
    jmp .print_result

.do_mul:
    imul eax, [val2]
    mov esi, msg_prod

.print_result:
    push eax
    call print_string             
    pop eax
    
    mov edi, out_buf
    call int_to_string
    mov esi, CLR_GREEN
    call print_string
    mov esi, out_buf
    call print_string
    mov esi, CLR_RESET
    call print_string
    mov esi, newline
    call print_string
    jmp ask_again

.div_zero:
    mov esi, msg_err_div
    call print_string
    jmp ask_again

.invalid:
    mov esi, msg_invalid
    call print_string

ask_again:
    mov esi, prompt_again
    call print_string

    mov ecx, choice
    mov edx, 4
    call read_input

    mov al, [choice]
    cmp al, 'y'
    je main_loop
    cmp al, 'Y'
    je main_loop

    ; Exit
    mov eax, SYS_EXIT
    xor ebx, ebx
    int 0x80

; =========================================================================
; HELPER FUNCTIONS
; =========================================================================

get_number:
    call print_string
    mov ecx, num_str
    mov edx, 16
    call read_input
    mov esi, num_str

; ASCII to Integer (parse_int)
parse_int:
    xor eax, eax
    xor ecx, ecx
    mov bl, [esi]
    cmp bl, '-'
    jne .loop
    inc ecx
    inc esi
.loop:
    mov bl, [esi]
    sub bl, '0'
    js .done                        ; If character < '0', exit loop
    cmp bl, 9
    jg .done                        ; If character > '9', exit loop
    imul eax, 10
    movzx ebx, bl
    add eax, ebx
    inc esi
    jmp .loop
.done:
    test ecx, ecx
    jz .ret
    neg eax
.ret:
    ret

; Integer to ASCII String
int_to_string:
    push edi
    test eax, eax
    jns .pos
    mov byte [edi], '-'
    inc edi
    neg eax
.pos:
    mov ebx, 10
    xor ecx, ecx
.div_loop:
    xor edx, edx
    div ebx
    add dl, '0'
    push edx
    inc ecx
    test eax, eax
    jnz .div_loop
.write_loop:
    pop edx
    mov [edi], dl
    inc edi
    loop .write_loop
    mov byte [edi], 0
    pop edi
    ret

; Print and Read
print_string:
    pusha
    mov edi, esi
    xor eax, eax
    or ecx, -1
    repne scasb
    not ecx
    dec ecx
    mov edx, ecx
    mov ecx, esi
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    int 0x80
    popa
    ret

read_input:
    mov eax, SYS_READ
    mov ebx, STDIN
    int 0x80
    ret