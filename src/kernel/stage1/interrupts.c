#include <kernel/interrupts.h>
#include <kernel/vga.h>

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;

#define PIC1_COMMAND_PORT 0x20u
#define PIC1_DATA_PORT 0x21u
#define PIC2_COMMAND_PORT 0xA0u
#define PIC2_DATA_PORT 0xA1u

#define PIT_CHANNEL0_PORT 0x40u
#define PIT_COMMAND_PORT 0x43u
#define PS2_DATA_PORT 0x60u

#define PIC_ICW1_INIT 0x10u
#define PIC_ICW1_ICW4 0x01u
#define PIC_ICW4_8086 0x01u

#define PIC_MASTER_VECTOR_OFFSET 0x20u
#define PIC_SLAVE_VECTOR_OFFSET 0x28u
#define PIC_MASTER_IRQ0_ONLY_MASK 0xFEu
#define PIC_MASTER_IRQ0_IRQ1_MASK 0xFCu
#define PIC_SLAVE_ALL_MASK 0xFFu

#define PIT_COMMAND_RATE_GEN_LOHI 0x34u
#define PIT_DIVISOR_100HZ 11931u

#define PIC_EOI 0x20u
#define KBD_EXPECTED_MAKE_CODE 0x1Eu

extern void debug_print_pm(const char *message);

extern u8 ih_seen;
extern u8 ih_count;
extern u8 hi_hw_tick_count;
extern u8 keyboard_irq_test_mode;
extern u8 kbd_irq_seen;
extern u8 kbd_scancode_match;
extern u8 last_kbd_scancode;
extern u8 last_exc_vector;
extern u32 last_exc_error;
extern u32 last_exc_eip;

static u8 inb(u16 port)
{
    u8 value;
    __asm__ volatile ("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

static void outb(u16 port, u8 value)
{
    __asm__ volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}

static void io_wait(void)
{
    outb(0x80u, 0u);
}

static u8 pic_master_mask(void)
{
    if (keyboard_irq_test_mode != 0u) {
        return PIC_MASTER_IRQ0_IRQ1_MASK;
    }

    return PIC_MASTER_IRQ0_ONLY_MASK;
}

static char ascii_for_scancode(u8 scancode)
{
    switch (scancode) {
    case KBD_EXPECTED_MAKE_CODE:
        return 'a';
    case 0x1Cu:
        return '\n';
    default:
        return '\0';
    }
}

static void init_pic(void)
{
    outb(PIC1_COMMAND_PORT, (u8)(PIC_ICW1_INIT | PIC_ICW1_ICW4));
    io_wait();
    outb(PIC2_COMMAND_PORT, (u8)(PIC_ICW1_INIT | PIC_ICW1_ICW4));
    io_wait();

    outb(PIC1_DATA_PORT, PIC_MASTER_VECTOR_OFFSET);
    io_wait();
    outb(PIC2_DATA_PORT, PIC_SLAVE_VECTOR_OFFSET);
    io_wait();

    outb(PIC1_DATA_PORT, 0x04u);
    io_wait();
    outb(PIC2_DATA_PORT, 0x02u);
    io_wait();

    outb(PIC1_DATA_PORT, PIC_ICW4_8086);
    io_wait();
    outb(PIC2_DATA_PORT, PIC_ICW4_8086);
    io_wait();

    outb(PIC1_DATA_PORT, pic_master_mask());
    outb(PIC2_DATA_PORT, PIC_SLAVE_ALL_MASK);
}

static void init_pit(void)
{
    u16 divisor = PIT_DIVISOR_100HZ;
    outb(PIT_COMMAND_PORT, PIT_COMMAND_RATE_GEN_LOHI);
    outb(PIT_CHANNEL0_PORT, (u8)(divisor & 0xFFu));
    outb(PIT_CHANNEL0_PORT, (u8)((divisor >> 8) & 0xFFu));
}

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

void init_hw_interrupts_c(void)
{
    init_pic();
    init_pit();
    debug_print_pm(" HI_INIT_OK");
    if (keyboard_irq_test_mode != 0u) {
        debug_print_pm(" KBD_INIT_OK");
    }
}

void ih_handle_timer_c(void)
{
    hi_hw_tick_count++;
    ih_seen = 1;
    ih_count++;
    if (hi_hw_tick_count == 1u) {
        debug_print_pm(" HI_IRQ0_OK");
    }
    if (hi_hw_tick_count == 3u) {
        debug_print_pm(" HI_TICKS_3");
    }
    debug_print_pm(" IH_OK");
    outb(PIC1_COMMAND_PORT, PIC_EOI);
}

void ih_handle_keyboard_c(void)
{
    u8 scancode = inb(PS2_DATA_PORT);
    char decoded;

    last_kbd_scancode = scancode;

    if (kbd_irq_seen == 0u) {
        kbd_irq_seen = 1u;
        debug_print_pm(" KBD_IRQ1_OK");
    }

    if (scancode == KBD_EXPECTED_MAKE_CODE && kbd_scancode_match == 0u) {
        kbd_scancode_match = 1u;
        debug_print_pm(" KBD_SC_OK");
    }

    if ((scancode & 0x80u) == 0u) {
        decoded = ascii_for_scancode(scancode);
        if (decoded != '\0') {
            vga_putc(decoded);
        }
    }

    outb(PIC1_COMMAND_PORT, PIC_EOI);
}

void ih_handle_exception_c(u32 vector, u32 error, u32 eip)
{
    last_exc_vector = (u8)vector;
    last_exc_error = error;
    last_exc_eip = eip;
    debug_print_pm(marker_for_vector(vector));
}
