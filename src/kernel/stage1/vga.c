#include <kernel/vga.h>

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;

#define VGA_FB_ADDR 0xB8000u
#define VGA_COLS 80u
#define VGA_ROWS 25u
#define VGA_ATTR 0x07u

static volatile u16 *const vga_fb = (volatile u16 *)VGA_FB_ADDR;
static u8 vga_row;
static u8 vga_col;

static u16 vga_cell(char c)
{
    return (u16)(((u16)VGA_ATTR << 8) | (u8)c);
}

static void vga_scroll(void)
{
    u32 row;
    u32 col;

    for (row = 1; row < VGA_ROWS; row++) {
        for (col = 0; col < VGA_COLS; col++) {
            vga_fb[(row - 1) * VGA_COLS + col] = vga_fb[row * VGA_COLS + col];
        }
    }

    for (col = 0; col < VGA_COLS; col++) {
        vga_fb[(VGA_ROWS - 1) * VGA_COLS + col] = vga_cell(' ');
    }
}

static void vga_newline(void)
{
    vga_col = 0;
    vga_row++;

    if (vga_row >= VGA_ROWS) {
        vga_scroll();
        vga_row = VGA_ROWS - 1;
    }
}

void vga_init(void)
{
    u32 i;

    for (i = 0; i < (VGA_COLS * VGA_ROWS); i++) {
        vga_fb[i] = vga_cell(' ');
    }

    vga_row = 0;
    vga_col = 0;
}

void vga_putc(char c)
{
    if (c == '\n') {
        vga_newline();
        return;
    }

    if (c == '\r') {
        vga_col = 0;
        return;
    }

    if (c == '\t') {
        u8 next_tab = (u8)((vga_col + 8u) & (u8)~0x07u);
        while (vga_col < next_tab) {
            vga_putc(' ');
        }
        return;
    }

    vga_fb[(u32)vga_row * VGA_COLS + vga_col] = vga_cell(c);
    vga_col++;

    if (vga_col >= VGA_COLS) {
        vga_newline();
    }
}

void vga_write(const char *s)
{
    while (*s != '\0') {
        vga_putc(*s);
        s++;
    }
}
