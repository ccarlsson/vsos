BITS 16
ORG 0x0000

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

; VGA Console Constants (Phase 4)
; ================================
; VGA text mode framebuffer address (linear, protected mode)
VGA_FRAMEBUFFER equ 0xB8000
; VGA text mode dimensions
VGA_COLS equ 80
VGA_ROWS equ 25
; Size of one character cell (char + attribute = 2 bytes)
VGA_CELL_SIZE equ 2
; Total framebuffer size in bytes
VGA_FRAMEBUFFER_SIZE equ VGA_COLS * VGA_ROWS * VGA_CELL_SIZE
; Default attribute byte: 0x07 = white (0x7) on black (0x0)
; Format: bits 7-4 = background, bits 3-0 = foreground
VGA_DEFAULT_ATTR equ 0x07

; VGA Calling Conventions (Phase 4)
; ==================================
; vga_char: Output single character
;   Input:  AL = ASCII character code
;           (AH or global context) = attribute byte (default 0x07)
;   Output: Framebuffer updated, cursor advanced
;   Side effects: Changes cursor position, modifies framebuffer cells
;
; vga_string: Output null-terminated string
;   Input:  ESI = pointer to buffer with null-terminated string
;   Output: String copied to framebuffer starting at current cursor
;           Cursor advanced to end of string
;   Side effects: Multiple framebuffer updates, cursor advanced
;
; vga_init: Clear framebuffer and reset cursor
;   Input:  none
;   Output: Framebuffer cleared to spaces (0x20) with default attribute (0x07)
;           Cursor position reset to (0, 0)
;   Side effects: Entire framebuffer overwritten

%ifndef FORCE_A20_FAILURE
%define FORCE_A20_FAILURE 0
%endif

%ifndef EXCEPTION_TEST
%define EXCEPTION_TEST 0
%endif

%ifndef INTERRUPT_TEST_MODE
%define INTERRUPT_TEST_MODE 0
%endif

jmp short start
db 'KRNL'

start:
    cli

    mov ax, cs
    mov ds, ax
    mov es, ax

    mov [boot_drive_val], dl

    mov si, msg_ok
    call print_string

    mov si, msg_dl
    call print_string

    mov al, [boot_drive_val]
    call print_hex_byte

    call enable_a20
    call verify_a20
    jc a20_error

    call validate_pm_config
    jc pm_config_error

    lgdt [gdtr]

    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax

    ; Far jump with 32-bit offset into the protected-mode code segment.
    db 0x66
    db 0xEA
    dd KERNEL_LINEAR_BASE + protected_mode_entry
    dw CODE_SEL

a20_error:
    mov si, msg_p1
    call print_string
    jmp halt

pm_config_error:
    mov si, msg_p2
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

    mov ax, [gdtr]
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

msg_ok db 'KERNEL_OK', 0
msg_dl db ' DL=', 0
msg_p1 db 'P1', 0
msg_p2 db 'P2', 0
boot_drive_val db 0

align 8
gdt_start:
    dq 0x0000000000000000
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
gdt_end:

gdtr:
    dw gdt_end - gdt_start - 1
    dd KERNEL_LINEAR_BASE + gdt_start

BITS 32

protected_mode_entry:
    mov ax, DATA_SEL
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, PM_STACK_TOP

    mov esi, KERNEL_LINEAR_BASE + msg_pm_ok
    call print_string_pm

    ; Phase 0: Verify VGA framebuffer accessibility
    call verify_vga_accessible
    jc vga_not_accessible

    mov esi, KERNEL_LINEAR_BASE + msg_vga_ok
    call print_string_pm

vga_not_accessible:

    call init_idt
    sti

%if INTERRUPT_TEST_MODE = 1
    ; Deterministic Phase 3 multi-interrupt path.
    int 0x20
    int 0x20
    int 0x20

    cmp byte [KERNEL_LINEAR_BASE + ih_count], 3
    jb halt_pm
%else
    ; Deterministic Phase 1 interrupt path.
    int 0x20

    cmp byte [KERNEL_LINEAR_BASE + ih_seen], 1
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

verify_vga_accessible:
    ; Phase 0: Test 0xB8000 accessibility
    ; Write a test pattern (space + white-on-black) to first cell
    ; Then read it back to verify write succeeded.
    pushad

    mov eax, VGA_FRAMEBUFFER
    mov word [eax], 0x0720  ; space (0x20) with attr (0x07)

    ; Read back and verify
    cmp word [eax], 0x0720
    je .vga_ok

    ; Failed to write/read
    stc
    popad
    ret

.vga_ok:
    clc
    popad
    ret

init_idt:
    pushad

    xor ecx, ecx
.fill_default:
    mov eax, KERNEL_LINEAR_BASE + isr_default_stub
    call set_idt_gate
    inc ecx
    cmp ecx, IDT_ENTRY_COUNT
    jb .fill_default

    mov ecx, 0x20
    mov eax, KERNEL_LINEAR_BASE + isr_timer_stub
    call set_idt_gate

    mov ecx, 0x00
    mov eax, KERNEL_LINEAR_BASE + isr_exc0_stub
    call set_idt_gate

    mov ecx, 0x06
    mov eax, KERNEL_LINEAR_BASE + isr_exc6_stub
    call set_idt_gate

    mov ecx, 0x0D
    mov eax, KERNEL_LINEAR_BASE + isr_exc13_stub
    call set_idt_gate

    popad
    lidt [KERNEL_LINEAR_BASE + idtr]
    ret

set_idt_gate:
    mov edi, KERNEL_LINEAR_BASE + idt_start
    mov ebx, ecx
    shl ebx, 3
    add edi, ebx

    mov bx, ax
    mov [edi + 0], bx
    mov word [edi + 2], CODE_SEL
    mov byte [edi + 4], 0
    mov byte [edi + 5], 0x8E
    shr eax, 16
    mov [edi + 6], ax
    ret

isr_default_stub:
    cli
.default_halt:
    hlt
    jmp .default_halt

isr_timer_stub:
    pushad
    mov byte [KERNEL_LINEAR_BASE + ih_seen], 1
    inc byte [KERNEL_LINEAR_BASE + ih_count]
    mov esi, KERNEL_LINEAR_BASE + msg_ih_ok
    call print_string_pm
    popad
    iret

isr_exc0_stub:
    pushad
    mov eax, [esp + 32]
    mov [KERNEL_LINEAR_BASE + last_exc_eip], eax
    mov dword [KERNEL_LINEAR_BASE + last_exc_error], 0
    mov byte [KERNEL_LINEAR_BASE + last_exc_vector], 0x00
    mov esi, KERNEL_LINEAR_BASE + msg_ix_00
    call print_string_pm
    popad
    jmp exception_halt

isr_exc6_stub:
    pushad
    mov eax, [esp + 32]
    mov [KERNEL_LINEAR_BASE + last_exc_eip], eax
    mov dword [KERNEL_LINEAR_BASE + last_exc_error], 0
    mov byte [KERNEL_LINEAR_BASE + last_exc_vector], 0x06
    mov esi, KERNEL_LINEAR_BASE + msg_ix_06
    call print_string_pm
    popad
    jmp exception_halt

isr_exc13_stub:
    pushad
    mov eax, [esp + 36]
    mov [KERNEL_LINEAR_BASE + last_exc_eip], eax
    mov eax, [esp + 32]
    mov [KERNEL_LINEAR_BASE + last_exc_error], eax
    mov byte [KERNEL_LINEAR_BASE + last_exc_vector], 0x0D
    mov esi, KERNEL_LINEAR_BASE + msg_ix_13
    call print_string_pm
    popad
    jmp exception_halt

exception_halt:
    cli
.halt_loop:
    hlt
    jmp .halt_loop

print_string_pm:
    lodsb
    test al, al
    jz .done

    mov dx, 0x00E9
    out dx, al
    jmp print_string_pm

.done:
    ret

msg_pm_ok db ' PM_OK', 0
msg_vga_ok db ' VGA_OK', 0
msg_ih_ok db ' IH_OK', 0
msg_ix_00 db ' IX_00', 0
msg_ix_06 db ' IX_06', 0
msg_ix_13 db ' IX_13', 0

ih_seen db 0
ih_count db 0
last_exc_vector db 0
align 4
last_exc_error dd 0
last_exc_eip dd 0
align 8

idt_start:
    times IDT_ENTRY_COUNT dq 0
idt_end:

idtr:
    dw IDT_LIMIT
    dd KERNEL_LINEAR_BASE + idt_start
