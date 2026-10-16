;nasm -f elf32 problem4_atm.asm -o problem4_atm.o
;ld -m elf_i386 problem4_atm.o -o problem4_atm
;./problem4_atm

SYS_EXIT  equ 1
SYS_READ  equ 3
SYS_WRITE equ 4
STDIN     equ 0
STDOUT    equ 1

CORRECT_PIN      equ 1234
STARTING_BALANCE equ 10000

NAME_CAP   equ 128
PIN_CAP    equ 32
AMOUNT_CAP equ 32

section .data
    balance dd STARTING_BALANCE

    prompt_name db 'Enter account name: '
    prompt_name_len equ $ - prompt_name

    prompt_pin db 'Enter PIN: '
    prompt_pin_len equ $ - prompt_pin

    prompt_amount db 'Enter withdrawal amount: '
    prompt_amount_len equ $ - prompt_amount

    access_granted db 'ACCESS GRANTED', 10
    access_granted_len equ $ - access_granted

    access_denied db 'ACCESS DENIED', 10
    access_denied_len equ $ - access_denied

    current_balance db 'Current Balance: PHP '
    current_balance_len equ $ - current_balance

    withdrawal_successful db 'WITHDRAWAL SUCCESSFUL', 10
    withdrawal_successful_len equ $ - withdrawal_successful

    amount_withdrawn db 'Amount Withdrawn: PHP '
    amount_withdrawn_len equ $ - amount_withdrawn

    remaining_balance db 'Remaining Balance: PHP '
    remaining_balance_len equ $ - remaining_balance

    invalid_amount db 'INVALID AMOUNT', 10
    invalid_amount_len equ $ - invalid_amount

    insufficient_funds db 'INSUFFICIENT FUNDS', 10
    insufficient_funds_len equ $ - insufficient_funds

    invalid_multiple db 'AMOUNT MUST BE A MULTIPLE OF 100', 10
    invalid_multiple_len equ $ - invalid_multiple

    newline db 10

section .bss
    name_buffer resb NAME_CAP

    pin_buffer resb PIN_CAP
    pin_len    resd 1

    amount_buffer resb AMOUNT_CAP
    amount_len    resd 1
    amount_value  resd 1

    number_text resb 10
    input_char  resb 1

section .text
    global _start

_start:
    ; Read the full account name
    mov ecx, prompt_name
    mov edx, prompt_name_len
    call print_text

    mov ecx, name_buffer
    mov edx, NAME_CAP
    call read_line

    ; Read the PIN
    mov ecx, prompt_pin
    mov edx, prompt_pin_len
    call print_text

    mov ecx, pin_buffer
    mov edx, PIN_CAP
    call read_line
    mov [pin_len], eax

    ; Convert and verify the PIN
    mov esi, pin_buffer
    mov ecx, [pin_len]
    call ascii_to_uint
    jc .deny_access

    cmp eax, CORRECT_PIN
    jne .deny_access

    ; The correct PIN was entered
    mov ecx, access_granted
    mov edx, access_granted_len
    call print_text

    ; Display the starting balance
    mov ecx, current_balance
    mov edx, current_balance_len
    call print_text

    mov eax, [balance]
    call print_uint

    mov ecx, newline
    mov edx, 1
    call print_text

    ; Request the withdrawal amount
    mov ecx, prompt_amount
    mov edx, prompt_amount_len
    call print_text

    mov ecx, amount_buffer
    mov edx, AMOUNT_CAP
    call read_line
    mov [amount_len], eax

    ; Convert the withdrawal amount
    mov esi, amount_buffer
    mov ecx, [amount_len]
    call ascii_to_uint
    jc .show_invalid_amount

    ; First check: amount must be greater than zero
    test eax, eax
    jz .show_invalid_amount

    mov [amount_value], eax

    ; Second check: amount must not exceed the balance
    cmp eax, [balance]
    ja .show_insufficient_funds

    ; Third check: amount must be divisible by 100
    mov eax, [amount_value]
    xor edx, edx
    mov ebx, 100
    div ebx

    test edx, edx
    jnz .show_invalid_multiple

    ; All checks passed, so update the balance
    mov eax, [balance]
    sub eax, [amount_value]
    mov [balance], eax

    ; Display successful withdrawal
    mov ecx, withdrawal_successful
    mov edx, withdrawal_successful_len
    call print_text

    mov ecx, amount_withdrawn
    mov edx, amount_withdrawn_len
    call print_text

    mov eax, [amount_value]
    call print_uint

    mov ecx, newline
    mov edx, 1
    call print_text

    mov ecx, remaining_balance
    mov edx, remaining_balance_len
    call print_text

    mov eax, [balance]
    call print_uint

    mov ecx, newline
    mov edx, 1
    call print_text

    jmp .exit

.deny_access:
    mov ecx, access_denied
    mov edx, access_denied_len
    call print_text
    jmp .exit

.show_invalid_amount:
    mov ecx, invalid_amount
    mov edx, invalid_amount_len
    call print_text
    jmp .exit

.show_insufficient_funds:
    mov ecx, insufficient_funds
    mov edx, insufficient_funds_len
    call print_text
    jmp .exit

.show_invalid_multiple:
    mov ecx, invalid_multiple
    mov edx, invalid_multiple_len
    call print_text

.exit:
    call exit_program

print_text:
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    int 0x80
    ret

print_uint:
    call uint_to_ascii
    call print_text
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
    mov edi, number_text + 10
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