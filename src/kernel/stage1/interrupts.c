#include <kernel/interrupts.h>

typedef unsigned char u8;
typedef unsigned int u32;

extern void debug_print_pm(const char *message);

extern u8 ih_seen;
extern u8 ih_count;
extern u8 last_exc_vector;
extern u32 last_exc_error;
extern u32 last_exc_eip;

static const char *marker_for_vector(u32 vector)
{
    switch (vector) {
    case 0x00u:
        return " IX_00";
    case 0x06u:
        return " IX_06";
    case 0x0Du:
        return " IX_13";
    default:
        return "";
    }
}

void ih_handle_timer_c(void)
{
    ih_seen = 1;
    ih_count++;
    debug_print_pm(" IH_OK");
}

void ih_handle_exception_c(u32 vector, u32 error, u32 eip)
{
    last_exc_vector = (u8)vector;
    last_exc_error = error;
    last_exc_eip = eip;
    debug_print_pm(marker_for_vector(vector));
}
