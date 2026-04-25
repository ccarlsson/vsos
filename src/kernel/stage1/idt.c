#include <kernel/idt.h>

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef unsigned long long u64;

#define IDT_ENTRY_COUNT 256u
#define CODE_SEL 0x08u
#define IDT_TYPE_ATTR 0x8Eu

extern void isr_default_stub(void);
extern void isr_timer_stub(void);
extern void isr_keyboard_stub(void);
extern void isr_exc0_stub(void);
extern void isr_exc6_stub(void);
extern void isr_exc13_stub(void);

extern u64 idt_start[IDT_ENTRY_COUNT];

struct __attribute__((packed)) idtr_desc {
    u16 limit;
    u32 base;
};

extern struct idtr_desc idtr;

static u64 idt_gate_from_handler(u32 handler)
{
    u64 gate = 0;

    gate |= (u64)(handler & 0xFFFFu);
    gate |= (u64)CODE_SEL << 16;
    gate |= (u64)IDT_TYPE_ATTR << 40;
    gate |= (u64)((handler >> 16) & 0xFFFFu) << 48;

    return gate;
}

static void idt_set_gate(u32 vector, void (*handler)(void))
{
    idt_start[vector] = idt_gate_from_handler((u32)handler);
}

void init_idt_c(void)
{
    u32 i;

    for (i = 0; i < IDT_ENTRY_COUNT; i++) {
        idt_set_gate(i, isr_default_stub);
    }

    idt_set_gate(0x20u, isr_timer_stub);
    idt_set_gate(0x21u, isr_keyboard_stub);
    idt_set_gate(0x00u, isr_exc0_stub);
    idt_set_gate(0x06u, isr_exc6_stub);
    idt_set_gate(0x0Du, isr_exc13_stub);

    __asm__ volatile ("lidtl %0" : : "m"(idtr));
}
