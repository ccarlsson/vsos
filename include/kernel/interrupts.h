#ifndef VSOS_KERNEL_INTERRUPTS_H
#define VSOS_KERNEL_INTERRUPTS_H

void init_hw_interrupts_c(void);
void ih_handle_timer_c(void);
void ih_handle_keyboard_c(void);
void ih_handle_exception_c(unsigned int vector, unsigned int error, unsigned int eip);

#endif
