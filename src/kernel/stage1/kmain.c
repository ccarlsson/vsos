#include <kernel/vga.h>

extern void debug_print_pm(const char *message);
extern void pm_main(void);

void kmain(void)
{
    debug_print_pm(" C_ENTRY_OK");

    vga_init();
    debug_print_pm(" VGA_INIT_OK");

    vga_putc('A');
    debug_print_pm(" VGA_CHAR_OK");

    vga_write("HELLO");
    debug_print_pm(" VGA_STR_OK");

    vga_write("LINE1\nLINE2");
    debug_print_pm(" VGA_NL_OK");

    {
        int i;
        for (i = 0; i < 82; i++) {
            vga_putc(' ');
        }
    }
    debug_print_pm(" VGA_WRAP_OK");

    {
        int i;
        for (i = 0; i < 30; i++) {
            vga_write("L\n");
        }
    }
    debug_print_pm(" VGA_SCROLL_OK");

    pm_main();
}
