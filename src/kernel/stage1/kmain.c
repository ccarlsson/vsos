#include <kernel/vga.h>

extern void debug_print_pm(const char *message);
extern void pm_main(void);

static void show_boot_status(void)
{
    vga_write("Kernel: protected mode\n");
    vga_write("Kernel: VGA ready\n");
    vga_write("Kernel: init complete\n");
}

void kmain(void)
{
    debug_print_pm(" C_ENTRY_OK");

    vga_init();
    show_boot_status();
    debug_print_pm(" VGA_INIT_OK");

    vga_putc(' ');
    debug_print_pm(" VGA_CHAR_OK");

    vga_write("Kernel: VGA ready\n");
    debug_print_pm(" VGA_STR_OK");

    vga_write("Kernel: init complete\n");
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
            vga_write(" \n");
        }
    }
    debug_print_pm(" VGA_SCROLL_OK");

    vga_init();
    show_boot_status();

    pm_main();
}
