extern void debug_print_pm(const char *message);
extern void pm_main(void);

void kmain(void)
{
    debug_print_pm(" C_ENTRY_OK");
    pm_main();
}
