#include <kernel/interrupts.h>

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;

#define PIC1_COMMAND_PORT 0x20u
#define PIC1_DATA_PORT 0x21u
#define PIC2_COMMAND_PORT 0xA0u
#define PIC2_DATA_PORT 0xA1u

#define PIT_CHANNEL0_PORT 0x40u
#define PIT_COMMAND_PORT 0x43u

#define PIC_ICW1_INIT 0x10u
#define PIC_ICW1_ICW4 0x01u
#define PIC_ICW4_8086 0x01u

#define PIC_MASTER_VECTOR_OFFSET 0x20u
#define PIC_SLAVE_VECTOR_OFFSET 0x28u
#define PIC_MASTER_IRQ0_ONLY_MASK 0xFEu
#define PIC_SLAVE_ALL_MASK 0xFFu

#define PIT_COMMAND_RATE_GEN_LOHI 0x34u
#define PIT_DIVISOR_100HZ 11931u

extern void debug_print_pm(const char *message);

extern u8 ih_seen;
extern u8 ih_count;
extern u8 last_exc_vector;
extern u32 last_exc_error;
extern u32 last_exc_eip;

static void outb(u16 port, u8 value)
{
    __asm__ volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}

static void io_wait(void)
{
    outb(0x80u, 0u);
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

    outb(PIC1_DATA_PORT, PIC_MASTER_IRQ0_ONLY_MASK);
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
