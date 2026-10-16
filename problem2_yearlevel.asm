;nasm -f elf32 problem2_yearlevel.asm -o problem2_yearlevel.o
;ld -m elf_i386 problem2_yearlevel.o -o problem2_yearlevel
;./problem2_yearlevel

SYS_EXIT  equ 1
SYS_READ  equ 3
SYS_WRITE equ 4
STDIN     equ 0
STDOUT    equ 1

NAME_CAP equ 128
AGE_CAP  equ 32
YEAR_CAP equ 16

section .data
    prompt_name db 'What is your name? '
    prompt_name_len equ $ - prompt_name

    prompt_age db 'How old are you? '
    prompt_age_len equ $ - prompt_age

    prompt_year db 'What is your year level? '
    prompt_year_len equ $ - prompt_year

    invalid_age db 'INVALID AGE. Enter a non-negative whole number.', 10
    invalid_age_len equ $ - invalid_age

    hello_prefix db 'Hello '
    hello_prefix_len equ $ - hello_prefix

    age_prefix db 'You are '
    age_prefix_len equ $ - age_prefix

    age_suffix db ' years old', 10
    age_suffix_len equ $ - age_suffix

    freshman db 'Freshman', 10
    freshman_len equ $ - freshman

    sophomore db 'Sophomore', 10
    sophomore_len equ $ - sophomore

    junior db 'Junior', 10
    junior_len equ $ - junior

    senior db 'Senior', 10
    senior_len equ $ - senior

    invalid_year db 'INVALID YEAR LEVEL', 10
    invalid_year_len equ $ - invalid_year

    newline db 10

section .bss
    name_buffer resb NAME_CAP
    name_len    resd 1

    age_buffer resb AGE_CAP
    age_value  resd 1
    age_text   resb 10

    year_buffer resb YEAR_CAP
    year_value  resd 1

    input_char resb 1

section .text
    global _start

_start:
    ; Read the full name
    mov ecx, prompt_name
    mov edx, prompt_name_len
    call print_text

    mov ecx, name_buffer
    mov edx, NAME_CAP
    call read_line
    mov [name_len], eax

.read_age:
    ; Read and validate the age
    mov ecx, prompt_age
    mov edx, prompt_age_len
    call print_text

    mov ecx, age_buffer
    mov edx, AGE_CAP
    call read_line

    mov esi, age_buffer
    mov ecx, eax
    call ascii_to_uint
    jc .invalid_age_input

    mov [age_value], eax
    jmp .read_year

.invalid_age_input:
    mov ecx, invalid_age
    mov edx, invalid_age_len
    call print_text
    jmp .read_age

.read_year:
    ; Read and convert the year level
    mov ecx, prompt_year
    mov edx, prompt_year_len
    call print_text

    mov ecx, year_buffer
    mov edx, YEAR_CAP
    call read_line

    mov esi, year_buffer
    mov ecx, eax
    call ascii_to_uint
    jc .invalid_year_input

    mov [year_value], eax
    jmp .display_information

.invalid_year_input:
    mov dword [year_value], 0

.display_information:
    ; Display: Hello <name>
    mov ecx, hello_prefix
    mov edx, hello_prefix_len
    call print_text

    mov ecx, name_buffer
    mov edx, [name_len]
    call print_text

    mov ecx, newline
    mov edx, 1
    call print_text

    ; Display: You are <age> years old
    mov ecx, age_prefix
    mov edx, age_prefix_len
    call print_text

    mov eax, [age_value]
    call uint_to_ascii
    call print_text

    mov ecx, age_suffix
    mov edx, age_suffix_len
    call print_text

    ; Classify the year level
    mov eax, [year_value]

    cmp eax, 1
    je .show_freshman

    cmp eax, 2
    je .show_sophomore

    cmp eax, 3
    je .show_junior

    cmp eax, 4
    je .show_senior

    jmp .show_invalid_year

.show_freshman:
    mov ecx, freshman
    mov edx, freshman_len
    call print_text
    jmp .exit

.show_sophomore:
    mov ecx, sophomore
    mov edx, sophomore_len
    call print_text
    jmp .exit

.show_junior:
    mov ecx, junior
    mov edx, junior_len
    call print_text
    jmp .exit

.show_senior:
    mov ecx, senior
    mov edx, senior_len
    call print_text
    jmp .exit

.show_invalid_year:
    mov ecx, invalid_year
    mov edx, invalid_year_len
    call print_text

.exit:
    call exit_program

print_text:
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    int 0x80
    ret

read_line:
    push ebp

    mov esi, ecx
    mov edi, edx
    xor ebp, ebp

.read_character:
    mov eax, SYS_READ
    mov ebx, STDIN
    mov ecx, input_char
    mov edx, 1
    int 0x80

    cmp eax, 1
    jne .finished

    mov al, [input_char]

    cmp al, 10
    je .finished

    cmp al, 13
    je .read_character

    cmp ebp, edi
    jae .read_character

    mov [esi + ebp], al
    inc ebp
    jmp .read_character

.finished:
    mov eax, ebp
    pop ebp
    ret

ascii_to_uint:
    xor eax, eax

    test ecx, ecx
    jz .invalid

.convert_digit:
    movzx edx, byte [esi]

    cmp edx, '0'
    jb .invalid

    cmp edx, '9'
    ja .invalid

    sub edx, '0'

    ; Reject values greater than 4,294,967,295
    cmp eax, 429496729
    ja .invalid
    jb .safe_to_multiply

    cmp edx, 5
    ja .invalid

.safe_to_multiply:
    imul eax, eax, 10
    add eax, edx

    inc esi
    dec ecx
    jnz .convert_digit

    clc
    ret

.invalid:
    stc
    ret

uint_to_ascii:
    mov edi, age_text + 10
    xor ecx, ecx
    mov ebx, 10

    test eax, eax
    jnz .convert

    dec edi
    mov byte [edi], '0'
    mov ecx, edi
    mov edx, 1
    ret

.convert:
    xor edx, edx
    div ebx

    add dl, '0'
    dec edi
    mov [edi], dl
    inc ecx

    test eax, eax
    jnz .convert

    mov edx, ecx
    mov ecx, edi
    ret

exit_program:
    mov eax, SYS_EXIT
    xor ebx, ebx
    int 0x80