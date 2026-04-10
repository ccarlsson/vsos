BITS 16
ORG 0x0000

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

halt:
    cli
    hlt
    jmp halt

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
boot_drive_val db 0
