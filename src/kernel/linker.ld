OUTPUT_FORMAT(elf32-i386)
ENTRY(kernel_image_start)

SECTIONS
{
    . = 0x00010000;

    .text.start : ALIGN(16)
    {
        KEEP(*(.text.start))
    }

    .text : ALIGN(16)
    {
        *(.text)
        *(.text.*)
    }

    .rodata : ALIGN(16)
    {
        *(.rodata)
        *(.rodata.*)
    }

    .data : ALIGN(16)
    {
        *(.data)
        *(.data.*)
    }

    .bss : ALIGN(16)
    {
        *(.bss)
        *(.bss.*)
        *(COMMON)
    }

    /DISCARD/ :
    {
        *(.comment)
        *(.note*)
        *(.eh_frame)
    }
}
