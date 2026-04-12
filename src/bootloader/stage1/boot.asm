BITS 16
ORG 0x7C00

%ifndef KERNEL_LOAD_SEGMENT
%define KERNEL_LOAD_SEGMENT 0x1000
%endif

%ifndef KERNEL_LOAD_OFFSET
%define KERNEL_LOAD_OFFSET 0x0000
%endif

%ifndef KERNEL_START_LBA
%define KERNEL_START_LBA 1
%endif

%ifndef KERNEL_SECTOR_COUNT
%define KERNEL_SECTOR_COUNT 32
%endif

FLOPPY_TOTAL_SECTORS equ 2880

start:
    cli

    ; Normalize segment assumptions and stack early.
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7A00

    mov [boot_drive], dl

    mov si, msg_boot
    call print_string

    mov si, msg_dl
    call print_string

    mov al, [boot_drive]
    call print_hex_byte

    mov si, msg_load
    call print_string

    ; Validate fixed config before attempting any disk reads.
    mov ax, KERNEL_SECTOR_COUNT
    cmp ax, 1
    jb config_error
    cmp ax, 32
    ja config_error

    mov ax, KERNEL_START_LBA
    cmp ax, 1
    jb config_error

    mov bx, KERNEL_START_LBA
    add bx, KERNEL_SECTOR_COUNT
    cmp bx, FLOPPY_TOTAL_SECTORS
    ja config_error

    mov ax, KERNEL_LOAD_SEGMENT
    mov es, ax
    mov bx, KERNEL_LOAD_OFFSET

    mov ax, KERNEL_START_LBA
    mov cx, KERNEL_SECTOR_COUNT

load_loop:
    push ax
    push bx
    push cx

    call lba_to_chs

    mov ah, 0x02
    mov al, 0x01
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    pop cx
    pop bx
    pop ax

    add bx, 512
    inc ax
    loop load_loop

    mov si, KERNEL_LOAD_OFFSET + 2
    mov ax, [es:si]
    cmp ax, 0x524B
    jne disk_error

    mov ax, [es:si+2]
    cmp ax, 0x4C4E
    jne disk_error

    mov si, msg_enter
    call print_string

    mov dl, [boot_drive]
    jmp 0x1000:0x0000

disk_error:
    mov si, msg_disk_err
    call print_string
    jmp halt

config_error:
    mov si, msg_cfg_err
    call print_string
    jmp halt

halt:
    cli
    hlt
    jmp halt

lba_to_chs:
    mov dx, 0
    mov si, 36
    div si

    mov ch, al

    mov ax, dx
    mov dx, 0
    mov si, 18
    div si

    mov dh, al
    mov cl, dl
    inc cl
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
    mov bl, 0x07
    int 0x10
    pop bx
    ret

print_string:
    lodsb
    test al, al
    jz .done

    ; Mirror characters to QEMU debug console for headless test capture.
    mov dx, 0x00E9
    out dx, al

    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp print_string

.done:
    ret

msg_boot db 'VSOS M1', 0x0D, 0x0A, 'Boot: start', 0x0D, 0x0A, 0
msg_dl db ' DL=', 0
msg_load db 0x0D, 0x0A, 'Boot: loading kernel', 0x0D, 0x0A, 0
msg_enter db 0x0D, 0x0A, 'Boot: entering kernel', 0x0D, 0x0A, 0
msg_disk_err db 'E1', 0
msg_cfg_err db 'E2', 0
boot_drive db 0

times 510 - ($ - $$) db 0
dw 0xAA55
