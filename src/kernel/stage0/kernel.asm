BITS 16

%ifndef CODE_SEL
CODE_SEL equ 0x08
%endif

%ifndef DATA_SEL
DATA_SEL equ 0x10
%endif

PM_STACK_TOP equ 0x0009FC00
A20_PORT equ 0x92
KERNEL_LINEAR_BASE equ 0x00010000
EXPECTED_CODE_SEL equ 0x08
EXPECTED_DATA_SEL equ 0x10
IDT_ENTRY_COUNT equ 256
IDT_LIMIT equ (IDT_ENTRY_COUNT * 8) - 1

%ifndef FORCE_A20_FAILURE
%define FORCE_A20_FAILURE 0
%endif

%ifndef EXCEPTION_TEST
%define EXCEPTION_TEST 0
%endif

%ifndef INTERRUPT_TEST_MODE
%define INTERRUPT_TEST_MODE 0
%endif

%define RM_OFF(sym) (sym - kernel_image_start)

extern kmain
extern init_idt_c
extern init_hw_interrupts_c
extern ih_handle_timer_c
extern ih_handle_exception_c

global kernel_image_start
global start
global pm_main
global debug_print_pm
global idt_start
global idtr
global isr_default_stub
global isr_timer_stub
global isr_exc0_stub
global isr_exc6_stub
global isr_exc13_stub
global ih_seen
global ih_count
global last_exc_vector
global last_exc_error
global last_exc_eip

SECTION .text.start

kernel_image_start:
    jmp short start
    db 'KRNL'

start:
    cli

    mov ax, cs
    mov ds, ax
    mov es, ax

    mov [RM_OFF(boot_drive_val)], dl

    mov si, RM_OFF(msg_ok)
    call print_string

    mov si, RM_OFF(msg_dl)
    call print_string

    mov al, [RM_OFF(boot_drive_val)]
    call print_hex_byte

    call enable_a20
    call verify_a20
    jc a20_error

    call validate_pm_config
    jc pm_config_error

    lgdt [RM_OFF(gdtr)]

    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax

    db 0x66
    db 0xEA
    dd protected_mode_entry
    dw CODE_SEL

a20_error:
    mov si, RM_OFF(msg_p1)
    call print_string
    jmp halt

pm_config_error:
    mov si, RM_OFF(msg_p2)
    call print_string
    jmp halt

halt:
    cli
    hlt
    jmp halt

enable_a20:
    in al, A20_PORT
    or al, 0x02
    and al, 0xFE
    out A20_PORT, al
    ret

verify_a20:
%if FORCE_A20_FAILURE
    stc
    ret
%endif

    pushf
    cli
    push ax
    push bx
    push ds
    push es
    push si
    push di

    xor ax, ax
    mov ds, ax
    mov si, 0x0500
    mov ax, 0xFFFF
    mov es, ax
    mov di, 0x0510

    mov bl, [ds:si]
    mov bh, [es:di]

    mov byte [ds:si], 0x00
    mov byte [es:di], 0xFF

    cmp byte [ds:si], 0xFF
    jne .enabled

    stc
    jmp .restore

.enabled:
    clc

.restore:
    mov [ds:si], bl
    mov [es:di], bh

    pop di
    pop si
    pop es
    pop ds
    pop bx
    pop ax
    popf
    ret

validate_pm_config:
    mov ax, CODE_SEL
    cmp ax, EXPECTED_CODE_SEL
    jne .invalid

    mov ax, DATA_SEL
    cmp ax, EXPECTED_DATA_SEL
    jne .invalid

    mov ax, [RM_OFF(gdtr)]
    cmp ax, gdt_end - gdt_start - 1
    jne .invalid

    clc
    ret

.invalid:
    stc
    ret

print_hex_byte:
    push ax
    push bx

    mov bl, al
    mov al, bl
    shr al, 4
    call print_hex_nibble

    mov al, bl
    and al, 0x0F
    call print_hex_nibble

    pop bx
    pop ax
    ret

print_hex_nibble:
    and al, 0x0F
    cmp al, 10
    jb .digit
    add al, 'A' - 10
    jmp .emit

.digit:
    add al, '0'

.emit:
    mov dx, 0x00E9
    out dx, al

    push bx
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x0A
    int 0x10
    pop bx
    ret

print_string:
    lodsb
    test al, al
    jz .done

    mov dx, 0x00E9
    out dx, al

    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x0A
    int 0x10
    jmp print_string

.done:
    ret

SECTION .data

msg_ok db 'KERNEL_OK', 0
msg_dl db ' DL=', 0
msg_p1 db 'P1', 0
msg_p2 db 'P2', 0
msg_pm_ok db ' PM_OK', 0
msg_c_entry_ok db ' C_ENTRY_OK', 0
msg_ih_ok db ' IH_OK', 0
msg_ix_00 db ' IX_00', 0
msg_ix_06 db ' IX_06', 0
msg_ix_13 db ' IX_13', 0
boot_drive_val db 0

align 8
gdt_start:
    dq 0x0000000000000000
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
gdt_end:

gdtr:
    dw gdt_end - gdt_start - 1
    dd gdt_start

align 4
ih_seen db 0
ih_count db 0
last_exc_vector db 0
align 4
last_exc_error dd 0
last_exc_eip dd 0
align 8
idt_start:
    times IDT_ENTRY_COUNT dq 0
idtr:
    dw IDT_LIMIT
    dd idt_start

BITS 32

SECTION .text

protected_mode_entry:
    mov ax, DATA_SEL
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, PM_STACK_TOP

    mov esi, msg_pm_ok
    call print_string_pm

    call kmain
    jmp halt_pm

pm_main:
    call init_idt_c
    call init_hw_interrupts_c
    sti

%if INTERRUPT_TEST_MODE = 1
    int 0x20
    int 0x20
    int 0x20

    cmp byte [ih_count], 3
    jb halt_pm
%else
    int 0x20

    cmp byte [ih_seen], 1
    jne halt_pm
%endif

%if EXCEPTION_TEST = 1
    xor edx, edx
    div edx
%elif EXCEPTION_TEST = 2
    ud2
%endif

halt_pm:
    cli
    hlt
    jmp halt_pm

isr_default_stub:
    cli
.default_halt:
    hlt
    jmp .default_halt

isr_timer_stub:
    pushad
    call ih_handle_timer_c
    popad
    iret

isr_exc0_stub:
    pushad
    mov eax, [esp + 32]
    push eax
    push dword 0
    push dword 0x00
    call ih_handle_exception_c
    add esp, 12
    popad
    jmp exception_halt

isr_exc6_stub:
    pushad
    mov eax, [esp + 32]
    push eax
    push dword 0
    push dword 0x06
    call ih_handle_exception_c
    add esp, 12
    popad
    jmp exception_halt

isr_exc13_stub:
    pushad
    mov eax, [esp + 36]
    mov edx, [esp + 32]
    push eax
    push edx
    push dword 0x0D
    call ih_handle_exception_c
    add esp, 12
    popad
    jmp exception_halt

exception_halt:
    cli
.halt_loop:
    hlt
    jmp .halt_loop

debug_print_pm:
    push ebp
    mov ebp, esp
    push esi
    mov esi, [ebp + 8]
    call print_string_pm
    pop esi
    pop ebp
    ret

print_string_pm:
    lodsb
    test al, al
    jz .done

    mov dx, 0x00E9
    out dx, al
    jmp print_string_pm

.done:
    ret
