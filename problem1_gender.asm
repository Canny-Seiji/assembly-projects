;nasm -f elf32 problem1_gender.asm -o problem1_gender.o
;ld -m elf_i386 problem1_gender.o -o problem1_gender
;./problem1_gender

SYS_EXIT  equ 1
SYS_READ  equ 3
SYS_WRITE equ 4
STDIN     equ 0
STDOUT    equ 1

NAME_CAP   equ 128
AGE_CAP    equ 32
GENDER_CAP equ 8

section .data
    prompt_name db 'What is your name? '
    prompt_name_len equ $ - prompt_name

    prompt_age db 'How old are you? '
    prompt_age_len equ $ - prompt_age

    prompt_gender db 'What is your gender? '
    prompt_gender_len equ $ - prompt_gender

    invalid_age db 'INVALID AGE. Enter a non-negative whole number.', 10
    invalid_age_len equ $ - invalid_age

    hello_name db 'Hello '
    hello_name_len equ $ - hello_name

    age_prefix db 'You are '
    age_prefix_len equ $ - age_prefix

    age_suffix db ' years old', 10
    age_suffix_len equ $ - age_suffix

    male_message db 'Hello', 10
    male_message_len equ $ - male_message

    female_message db 'World', 10
    female_message_len equ $ - female_message

    invalid_gender db 'INVALID', 10
    invalid_gender_len equ $ - invalid_gender

    newline db 10

section .bss
    name_buffer   resb NAME_CAP
    name_len      resd 1
    age_buffer    resb AGE_CAP
    age_value     resd 1
    age_text      resb 10
    gender_buffer resb GENDER_CAP
    gender_len    resd 1
    input_char    resb 1

section .text
    global _start

_start:
    ; Read the full name. Spaces remain part of the input.
    mov ecx, prompt_name
    mov edx, prompt_name_len
    call print_text

    mov ecx, name_buffer
    mov edx, NAME_CAP
    call read_line
    mov [name_len], eax

.read_age:
    mov ecx, prompt_age
    mov edx, prompt_age_len
    call print_text

    mov ecx, age_buffer
    mov edx, AGE_CAP
    call read_line

    mov esi, age_buffer
    mov ecx, eax
    call ascii_to_uint
    jc .bad_age
    mov [age_value], eax
    jmp .read_gender

.bad_age:
    mov ecx, invalid_age
    mov edx, invalid_age_len
    call print_text
    jmp .read_age

.read_gender:
    mov ecx, prompt_gender
    mov edx, prompt_gender_len
    call print_text

    mov ecx, gender_buffer
    mov edx, GENDER_CAP
    call read_line
    mov [gender_len], eax

    ; Print: Hello <name>
    mov ecx, hello_name
    mov edx, hello_name_len
    call print_text

    mov ecx, name_buffer
    mov edx, [name_len]
    call print_text

    mov ecx, newline
    mov edx, 1
    call print_text

    ; Print: You are <age> years old
    mov ecx, age_prefix
    mov edx, age_prefix_len
    call print_text

    mov eax, [age_value]
    call uint_to_ascii      
    call print_text

    mov ecx, age_suffix
    mov edx, age_suffix_len
    call print_text

    ; A valid gender input must contain exactly one character.
    cmp dword [gender_len], 1
    jne .gender_invalid

    mov al, [gender_buffer]
    cmp al, 'M'
    je .gender_male
    cmp al, 'm'
    je .gender_male
    cmp al, 'F'
    je .gender_female
    cmp al, 'f'
    je .gender_female
    jmp .gender_invalid

.gender_male:
    mov ecx, male_message
    mov edx, male_message_len
    call print_text
    jmp .exit

.gender_female:
    mov ecx, female_message
    mov edx, female_message_len
    call print_text
    jmp .exit

.gender_invalid:
    mov ecx, invalid_gender
    mov edx, invalid_gender_len
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

    ; If the buffer is full, consume the rest without storing it.
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

    ; Reject values larger than 4,294,967,295.
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
    jnz .next_digit

    dec edi
    mov byte [edi], '0'
    mov ecx, edi
    mov edx, 1
    ret

.next_digit:
    xor edx, edx
    div ebx
    add dl, '0'
    dec edi
    mov [edi], dl
    inc ecx
    test eax, eax
    jnz .next_digit

    mov edx, ecx
    mov ecx, edi
    ret

exit_program:
    mov eax, SYS_EXIT
    xor ebx, ebx
    int 0x80
