;nasm -f elf32 problem3_grades.asm -o problem3_grades.o
;ld -m elf_i386 problem3_grades.o -o problem3_grades
;./problem3_grades

SYS_EXIT  equ 1
SYS_READ  equ 3
SYS_WRITE equ 4
STDIN     equ 0
STDOUT    equ 1

NAME_CAP  equ 128
ID_CAP    equ 32
GRADE_CAP equ 32

section .data
    prompt_name db 'Enter student name: '
    prompt_name_len equ $ - prompt_name

    prompt_id db 'Enter student ID: '
    prompt_id_len equ $ - prompt_id

    prompt_grade db 'Enter grade: '
    prompt_grade_len equ $ - prompt_grade

    output_name db 'Student Name: '
    output_name_len equ $ - output_name

    output_id db 'Student ID: '
    output_id_len equ $ - output_id

    output_grade db 'Grade: '
    output_grade_len equ $ - output_grade

    output_classification db 'Classification: '
    output_classification_len equ $ - output_classification

    excellent db 'Excellent', 10
    excellent_len equ $ - excellent

    very_good db 'Very Good', 10
    very_good_len equ $ - very_good

    good db 'Good', 10
    good_len equ $ - good

    passed db 'Passed', 10
    passed_len equ $ - passed

    failed db 'Failed', 10
    failed_len equ $ - failed

    invalid_grade db 'INVALID GRADE', 10
    invalid_grade_len equ $ - invalid_grade

    newline db 10

section .bss
    name_buffer resb NAME_CAP
    name_len    resd 1

    id_buffer resb ID_CAP
    id_len    resd 1

    grade_buffer resb GRADE_CAP
    grade_len    resd 1
    grade_value  resd 1
    grade_valid  resd 1

    input_char resb 1

section .text
    global _start

_start:
    ; Read the student's full name
    mov ecx, prompt_name
    mov edx, prompt_name_len
    call print_text

    mov ecx, name_buffer
    mov edx, NAME_CAP
    call read_line
    mov [name_len], eax

    ; Read the student ID as text
    mov ecx, prompt_id
    mov edx, prompt_id_len
    call print_text

    mov ecx, id_buffer
    mov edx, ID_CAP
    call read_line
    mov [id_len], eax

    ; Read the grade
    mov ecx, prompt_grade
    mov edx, prompt_grade_len
    call print_text

    mov ecx, grade_buffer
    mov edx, GRADE_CAP
    call read_line
    mov [grade_len], eax

    ; Assume the grade is invalid until validation succeeds
    mov dword [grade_valid], 0

    ; Convert the ASCII grade to an integer
    mov esi, grade_buffer
    mov ecx, [grade_len]
    call ascii_to_uint
    jc .display_details

    ; A valid grade must not exceed 100
    cmp eax, 100
    ja .display_details

    mov [grade_value], eax
    mov dword [grade_valid], 1

.display_details:
    ; Display the student's name
    mov ecx, output_name
    mov edx, output_name_len
    call print_text

    mov ecx, name_buffer
    mov edx, [name_len]
    call print_text

    mov ecx, newline
    mov edx, 1
    call print_text

    ; Display the student ID exactly as entered
    mov ecx, output_id
    mov edx, output_id_len
    call print_text

    mov ecx, id_buffer
    mov edx, [id_len]
    call print_text

    mov ecx, newline
    mov edx, 1
    call print_text

    ; Display the grade exactly as entered
    mov ecx, output_grade
    mov edx, output_grade_len
    call print_text

    mov ecx, grade_buffer
    mov edx, [grade_len]
    call print_text

    mov ecx, newline
    mov edx, 1
    call print_text

    ; Display the classification label
    mov ecx, output_classification
    mov edx, output_classification_len
    call print_text

    ; Reject malformed grades and grades above 100
    cmp dword [grade_valid], 1
    jne .show_invalid

    ; Check grade boundaries from highest to lowest
    mov eax, [grade_value]

    cmp eax, 90
    jae .show_excellent

    cmp eax, 85
    jae .show_very_good

    cmp eax, 80
    jae .show_good

    cmp eax, 75
    jae .show_passed

    jmp .show_failed

.show_excellent:
    mov ecx, excellent
    mov edx, excellent_len
    call print_text
    jmp .exit

.show_very_good:
    mov ecx, very_good
    mov edx, very_good_len
    call print_text
    jmp .exit

.show_good:
    mov ecx, good
    mov edx, good_len
    call print_text
    jmp .exit

.show_passed:
    mov ecx, passed
    mov edx, passed_len
    call print_text
    jmp .exit

.show_failed:
    mov ecx, failed
    mov edx, failed_len
    call print_text
    jmp .exit

.show_invalid:
    mov ecx, invalid_grade
    mov edx, invalid_grade_len
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

    ; Consume excess input without overflowing the buffer
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

    ; An empty input is invalid
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

exit_program:
    mov eax, SYS_EXIT
    xor ebx, ebx
    int 0x80