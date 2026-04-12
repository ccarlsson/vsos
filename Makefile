BOOT_SRC := src/bootloader/stage1/boot.asm
BOOT_BIN := build/boot.bin
BOOT_INVALID_BIN := build/boot.invalid.bin
KERNEL_SRC := src/kernel/stage0/kernel.asm
KERNEL_C_MAIN_SRC := src/kernel/stage1/kmain.c
KERNEL_C_VGA_SRC := src/kernel/stage1/vga.c
KERNEL_C_IDT_SRC := src/kernel/stage1/idt.c
KERNEL_C_IH_SRC := src/kernel/stage1/interrupts.c
KERNEL_LD_SCRIPT := src/kernel/linker.ld
KERNEL_BIN := build/kernel.bin
KERNEL_ELF := build/kernel.elf
KERNEL_ASM_OBJ := build/kernel.stage0.o
KERNEL_C_MAIN_OBJ := build/kernel.stage1.o
KERNEL_C_VGA_OBJ := build/kernel.vga.o
KERNEL_C_IDT_OBJ := build/kernel.idt.o
KERNEL_C_IH_OBJ := build/kernel.interrupts.o
KERNEL_C_OBJS := $(KERNEL_C_MAIN_OBJ) $(KERNEL_C_VGA_OBJ) $(KERNEL_C_IDT_OBJ) $(KERNEL_C_IH_OBJ)
CC32 ?= gcc
LD32 ?= ld
OBJCOPY ?= objcopy
C32_CFLAGS := -m32 -ffreestanding -fno-pic -fno-pie -fno-stack-protector -Wall -Wextra -Iinclude
LD32_FLAGS := -m elf_i386 -T $(KERNEL_LD_SCRIPT)
C_TOOLCHAIN_PROBE_SRC := tests/c-kernel-transition/probes/freestanding_probe.c
C_TOOLCHAIN_PROBE_OBJ := build/freestanding_probe.o
KERNEL_PM_A20FAIL_BIN := build/kernel.pm.a20fail.bin
KERNEL_PM_A20FAIL_ELF := build/kernel.pm.a20fail.elf
KERNEL_PM_A20FAIL_ASM_OBJ := build/kernel.pm.a20fail.stage0.o
KERNEL_PM_BADSEL_BIN := build/kernel.pm.badsel.bin
KERNEL_PM_BADSEL_ELF := build/kernel.pm.badsel.elf
KERNEL_PM_BADSEL_ASM_OBJ := build/kernel.pm.badsel.stage0.o
KERNEL_IH_DIV0_BIN := build/kernel.ih.div0.bin
KERNEL_IH_DIV0_ELF := build/kernel.ih.div0.elf
KERNEL_IH_DIV0_ASM_OBJ := build/kernel.ih.div0.stage0.o
KERNEL_IH_UD2_BIN := build/kernel.ih.ud2.bin
KERNEL_IH_UD2_ELF := build/kernel.ih.ud2.elf
KERNEL_IH_UD2_ASM_OBJ := build/kernel.ih.ud2.stage0.o
KERNEL_IH_MULTI_BIN := build/kernel.ih.multi.bin
KERNEL_IH_MULTI_ELF := build/kernel.ih.multi.elf
KERNEL_IH_MULTI_ASM_OBJ := build/kernel.ih.multi.stage0.o
DISK_IMG := build/disk.img
DISK_PM_T2_IMG := build/disk-pm-t2.img
DISK_PM_T3_IMG := build/disk-pm-t3.img
DISK_IH_T2_IMG := build/disk-ih-t2.img
DISK_IH_T3_IMG := build/disk-ih-t3.img
DISK_IH_T4_IMG := build/disk-ih-t4.img
KERNEL_HI_T2_BIN := build/kernel.hi.t2.bin
KERNEL_HI_T2_ELF := build/kernel.hi.t2.elf
KERNEL_HI_T2_ASM_OBJ := build/kernel.hi.t2.stage0.o
DISK_HI_T2_IMG := build/disk-hi-t2.img

.PHONY: all clean check-c-toolchain check-c-t1 check-boot check-qemu-m1 disk-image check-qemu-m2 check-qemu-t5 check-qemu-t3 check-qemu-t4 check-pm-t1 check-pm-t2 check-pm-t3 check-pm-all check-ih-t1 check-ih-t2 check-ih-t3 check-ih-t4 check-ih-all check-hi-t1 check-hi-t2 check-hi-t3 check-hi-all check-vga-t1 check-vga-t2 check-vga-t3 check-vga-t4 check-vga-t5 check-vga-t6 check-vga-all check-t1 check-t2 check-t3 check-t4 check-t5 check-all

all: $(BOOT_BIN) $(KERNEL_BIN)

$(BOOT_BIN): $(BOOT_SRC)
	mkdir -p build
	nasm -f bin -o $(BOOT_BIN) $(BOOT_SRC)

$(BOOT_INVALID_BIN): $(BOOT_SRC)
	mkdir -p build
	nasm -f bin -DKERNEL_SECTOR_COUNT=0 -o $(BOOT_INVALID_BIN) $(BOOT_SRC)

$(KERNEL_C_MAIN_OBJ): $(KERNEL_C_MAIN_SRC)
	mkdir -p build
	$(CC32) $(C32_CFLAGS) -c -o $(KERNEL_C_MAIN_OBJ) $(KERNEL_C_MAIN_SRC)

$(KERNEL_C_VGA_OBJ): $(KERNEL_C_VGA_SRC)
	mkdir -p build
	$(CC32) $(C32_CFLAGS) -c -o $(KERNEL_C_VGA_OBJ) $(KERNEL_C_VGA_SRC)

$(KERNEL_C_IDT_OBJ): $(KERNEL_C_IDT_SRC)
	mkdir -p build
	$(CC32) $(C32_CFLAGS) -c -o $(KERNEL_C_IDT_OBJ) $(KERNEL_C_IDT_SRC)

$(KERNEL_C_IH_OBJ): $(KERNEL_C_IH_SRC)
	mkdir -p build
	$(CC32) $(C32_CFLAGS) -c -o $(KERNEL_C_IH_OBJ) $(KERNEL_C_IH_SRC)

$(KERNEL_ASM_OBJ): $(KERNEL_SRC)
	mkdir -p build
	nasm -f elf32 -o $(KERNEL_ASM_OBJ) $(KERNEL_SRC)

$(KERNEL_ELF): $(KERNEL_ASM_OBJ) $(KERNEL_C_OBJS) $(KERNEL_LD_SCRIPT)
	mkdir -p build
	$(LD32) $(LD32_FLAGS) -o $(KERNEL_ELF) $(KERNEL_ASM_OBJ) $(KERNEL_C_OBJS)

$(KERNEL_BIN): $(KERNEL_ELF)
	mkdir -p build
	$(OBJCOPY) -O binary $(KERNEL_ELF) $(KERNEL_BIN)

$(KERNEL_PM_A20FAIL_ASM_OBJ): $(KERNEL_SRC)
	mkdir -p build
	nasm -f elf32 -DFORCE_A20_FAILURE=1 -o $(KERNEL_PM_A20FAIL_ASM_OBJ) $(KERNEL_SRC)

$(KERNEL_PM_A20FAIL_ELF): $(KERNEL_PM_A20FAIL_ASM_OBJ) $(KERNEL_C_OBJS) $(KERNEL_LD_SCRIPT)
	mkdir -p build
	$(LD32) $(LD32_FLAGS) -o $(KERNEL_PM_A20FAIL_ELF) $(KERNEL_PM_A20FAIL_ASM_OBJ) $(KERNEL_C_OBJS)

$(KERNEL_PM_A20FAIL_BIN): $(KERNEL_PM_A20FAIL_ELF)
	mkdir -p build
	$(OBJCOPY) -O binary $(KERNEL_PM_A20FAIL_ELF) $(KERNEL_PM_A20FAIL_BIN)

$(KERNEL_PM_BADSEL_ASM_OBJ): $(KERNEL_SRC)
	mkdir -p build
	nasm -f elf32 -DCODE_SEL=0x18 -o $(KERNEL_PM_BADSEL_ASM_OBJ) $(KERNEL_SRC)

$(KERNEL_PM_BADSEL_ELF): $(KERNEL_PM_BADSEL_ASM_OBJ) $(KERNEL_C_OBJS) $(KERNEL_LD_SCRIPT)
	mkdir -p build
	$(LD32) $(LD32_FLAGS) -o $(KERNEL_PM_BADSEL_ELF) $(KERNEL_PM_BADSEL_ASM_OBJ) $(KERNEL_C_OBJS)

$(KERNEL_PM_BADSEL_BIN): $(KERNEL_PM_BADSEL_ELF)
	mkdir -p build
	$(OBJCOPY) -O binary $(KERNEL_PM_BADSEL_ELF) $(KERNEL_PM_BADSEL_BIN)

$(KERNEL_IH_DIV0_ASM_OBJ): $(KERNEL_SRC)
	mkdir -p build
	nasm -f elf32 -DEXCEPTION_TEST=1 -o $(KERNEL_IH_DIV0_ASM_OBJ) $(KERNEL_SRC)

$(KERNEL_IH_DIV0_ELF): $(KERNEL_IH_DIV0_ASM_OBJ) $(KERNEL_C_OBJS) $(KERNEL_LD_SCRIPT)
	mkdir -p build
	$(LD32) $(LD32_FLAGS) -o $(KERNEL_IH_DIV0_ELF) $(KERNEL_IH_DIV0_ASM_OBJ) $(KERNEL_C_OBJS)

$(KERNEL_IH_DIV0_BIN): $(KERNEL_IH_DIV0_ELF)
	mkdir -p build
	$(OBJCOPY) -O binary $(KERNEL_IH_DIV0_ELF) $(KERNEL_IH_DIV0_BIN)

$(KERNEL_IH_UD2_ASM_OBJ): $(KERNEL_SRC)
	mkdir -p build
	nasm -f elf32 -DEXCEPTION_TEST=2 -o $(KERNEL_IH_UD2_ASM_OBJ) $(KERNEL_SRC)

$(KERNEL_IH_UD2_ELF): $(KERNEL_IH_UD2_ASM_OBJ) $(KERNEL_C_OBJS) $(KERNEL_LD_SCRIPT)
	mkdir -p build
	$(LD32) $(LD32_FLAGS) -o $(KERNEL_IH_UD2_ELF) $(KERNEL_IH_UD2_ASM_OBJ) $(KERNEL_C_OBJS)

$(KERNEL_IH_UD2_BIN): $(KERNEL_IH_UD2_ELF)
	mkdir -p build
	$(OBJCOPY) -O binary $(KERNEL_IH_UD2_ELF) $(KERNEL_IH_UD2_BIN)

$(KERNEL_IH_MULTI_ASM_OBJ): $(KERNEL_SRC)
	mkdir -p build
	nasm -f elf32 -DINTERRUPT_TEST_MODE=1 -o $(KERNEL_IH_MULTI_ASM_OBJ) $(KERNEL_SRC)

$(KERNEL_IH_MULTI_ELF): $(KERNEL_IH_MULTI_ASM_OBJ) $(KERNEL_C_OBJS) $(KERNEL_LD_SCRIPT)
	mkdir -p build
	$(LD32) $(LD32_FLAGS) -o $(KERNEL_IH_MULTI_ELF) $(KERNEL_IH_MULTI_ASM_OBJ) $(KERNEL_C_OBJS)

$(KERNEL_IH_MULTI_BIN): $(KERNEL_IH_MULTI_ELF)
	mkdir -p build
	$(OBJCOPY) -O binary $(KERNEL_IH_MULTI_ELF) $(KERNEL_IH_MULTI_BIN)

$(DISK_IMG): $(BOOT_BIN) $(KERNEL_BIN)
	mkdir -p build
	dd if=/dev/zero of=$(DISK_IMG) bs=512 count=2880 status=none
	dd if=$(BOOT_BIN) of=$(DISK_IMG) conv=notrunc status=none
	dd if=$(KERNEL_BIN) of=$(DISK_IMG) bs=512 seek=1 conv=notrunc status=none

$(DISK_PM_T2_IMG): $(BOOT_BIN) $(KERNEL_PM_A20FAIL_BIN)
	mkdir -p build
	dd if=/dev/zero of=$(DISK_PM_T2_IMG) bs=512 count=2880 status=none
	dd if=$(BOOT_BIN) of=$(DISK_PM_T2_IMG) conv=notrunc status=none
	dd if=$(KERNEL_PM_A20FAIL_BIN) of=$(DISK_PM_T2_IMG) bs=512 seek=1 conv=notrunc status=none

$(DISK_PM_T3_IMG): $(BOOT_BIN) $(KERNEL_PM_BADSEL_BIN)
	mkdir -p build
	dd if=/dev/zero of=$(DISK_PM_T3_IMG) bs=512 count=2880 status=none
	dd if=$(BOOT_BIN) of=$(DISK_PM_T3_IMG) conv=notrunc status=none
	dd if=$(KERNEL_PM_BADSEL_BIN) of=$(DISK_PM_T3_IMG) bs=512 seek=1 conv=notrunc status=none

$(DISK_IH_T2_IMG): $(BOOT_BIN) $(KERNEL_IH_DIV0_BIN)
	mkdir -p build
	dd if=/dev/zero of=$(DISK_IH_T2_IMG) bs=512 count=2880 status=none
	dd if=$(BOOT_BIN) of=$(DISK_IH_T2_IMG) conv=notrunc status=none
	dd if=$(KERNEL_IH_DIV0_BIN) of=$(DISK_IH_T2_IMG) bs=512 seek=1 conv=notrunc status=none

$(DISK_IH_T3_IMG): $(BOOT_BIN) $(KERNEL_IH_UD2_BIN)
	mkdir -p build
	dd if=/dev/zero of=$(DISK_IH_T3_IMG) bs=512 count=2880 status=none
	dd if=$(BOOT_BIN) of=$(DISK_IH_T3_IMG) conv=notrunc status=none
	dd if=$(KERNEL_IH_UD2_BIN) of=$(DISK_IH_T3_IMG) bs=512 seek=1 conv=notrunc status=none

$(DISK_IH_T4_IMG): $(BOOT_BIN) $(KERNEL_IH_MULTI_BIN)
	mkdir -p build
	dd if=/dev/zero of=$(DISK_IH_T4_IMG) bs=512 count=2880 status=none
	dd if=$(BOOT_BIN) of=$(DISK_IH_T4_IMG) conv=notrunc status=none
	dd if=$(KERNEL_IH_MULTI_BIN) of=$(DISK_IH_T4_IMG) bs=512 seek=1 conv=notrunc status=none

$(KERNEL_HI_T2_ASM_OBJ): $(KERNEL_SRC)
	mkdir -p build
	nasm -f elf32 -DHARDWARE_IRQ_TEST_MODE=1 -o $(KERNEL_HI_T2_ASM_OBJ) $(KERNEL_SRC)

$(KERNEL_HI_T2_ELF): $(KERNEL_HI_T2_ASM_OBJ) $(KERNEL_C_OBJS) $(KERNEL_LD_SCRIPT)
	mkdir -p build
	$(LD32) $(LD32_FLAGS) -o $(KERNEL_HI_T2_ELF) $(KERNEL_HI_T2_ASM_OBJ) $(KERNEL_C_OBJS)

$(KERNEL_HI_T2_BIN): $(KERNEL_HI_T2_ELF)
	mkdir -p build
	$(OBJCOPY) -O binary $(KERNEL_HI_T2_ELF) $(KERNEL_HI_T2_BIN)

$(DISK_HI_T2_IMG): $(BOOT_BIN) $(KERNEL_HI_T2_BIN)
	mkdir -p build
	dd if=/dev/zero of=$(DISK_HI_T2_IMG) bs=512 count=2880 status=none
	dd if=$(BOOT_BIN) of=$(DISK_HI_T2_IMG) conv=notrunc status=none
	dd if=$(KERNEL_HI_T2_BIN) of=$(DISK_HI_T2_IMG) bs=512 seek=1 conv=notrunc status=none

disk-image: $(DISK_IMG)

check-c-toolchain:
	mkdir -p build
	command -v $(CC32) >/dev/null
	command -v $(LD32) >/dev/null
	command -v $(OBJCOPY) >/dev/null
	$(CC32) $(C32_CFLAGS) -c -o $(C_TOOLCHAIN_PROBE_OBJ) $(C_TOOLCHAIN_PROBE_SRC)
	@echo "PASS: freestanding 32-bit C toolchain verified"

check-c-t1: $(DISK_IMG)
	sh tests/c-kernel-transition/scripts/check_qemu_c_t1.sh $(DISK_IMG)

check-boot: $(BOOT_BIN)
	sh tests/bootloader/scripts/check_boot_sector.sh $(BOOT_BIN)

check-qemu-m1: $(BOOT_BIN)
	sh tests/bootloader/scripts/check_qemu_m1.sh $(BOOT_BIN)

check-qemu-m2: $(DISK_IMG)
	sh tests/bootloader/scripts/check_qemu_m2.sh $(DISK_IMG)

check-qemu-t5: $(DISK_IMG)
	sh tests/bootloader/scripts/check_qemu_t5.sh $(DISK_IMG)

check-qemu-t3: $(BOOT_BIN) $(KERNEL_BIN)
	sh tests/bootloader/scripts/check_qemu_t3.sh $(BOOT_BIN) $(KERNEL_BIN)

check-qemu-t4: $(BOOT_INVALID_BIN) $(KERNEL_BIN)
	sh tests/bootloader/scripts/check_qemu_t4.sh $(BOOT_INVALID_BIN) $(KERNEL_BIN)

check-pm-t1: $(DISK_IMG)
	sh tests/protected-mode/scripts/check_qemu_pm_t1.sh $(DISK_IMG)

check-pm-t2: $(DISK_PM_T2_IMG)
	sh tests/protected-mode/scripts/check_qemu_pm_t2.sh $(DISK_PM_T2_IMG)

check-pm-t3: $(DISK_PM_T3_IMG)
	sh tests/protected-mode/scripts/check_qemu_pm_t3.sh $(DISK_PM_T3_IMG)

check-pm-all: check-pm-t1 check-pm-t2 check-pm-t3

check-ih-t1: $(DISK_IMG)
	sh tests/interrupt-handling/scripts/check_qemu_ih_t1.sh $(DISK_IMG)

check-ih-t2: $(DISK_IH_T2_IMG)
	sh tests/interrupt-handling/scripts/check_qemu_ih_t2.sh $(DISK_IH_T2_IMG)

check-ih-t3: $(DISK_IH_T3_IMG)
	sh tests/interrupt-handling/scripts/check_qemu_ih_t3.sh $(DISK_IH_T3_IMG)

check-ih-t4: $(DISK_IH_T4_IMG)
	sh tests/interrupt-handling/scripts/check_qemu_ih_t4.sh $(DISK_IH_T4_IMG)

check-ih-all: check-ih-t1 check-ih-t2 check-ih-t3 check-ih-t4

check-hi-t1: $(DISK_IMG)
	sh tests/hardware-interrupts/scripts/check_qemu_hi_t1.sh $(DISK_IMG)

check-hi-t2: $(DISK_HI_T2_IMG)
	sh tests/hardware-interrupts/scripts/check_qemu_hi_t2.sh $(DISK_HI_T2_IMG)

check-hi-t3: $(DISK_HI_T2_IMG)
	sh tests/hardware-interrupts/scripts/check_qemu_hi_t3.sh $(DISK_HI_T2_IMG)

check-hi-t4: $(DISK_HI_T2_IMG)
	sh tests/hardware-interrupts/scripts/check_qemu_hi_t4.sh $(DISK_HI_T2_IMG)

check-hi-all: check-hi-t1 check-hi-t2 check-hi-t3 check-hi-t4

check-vga-t1: $(DISK_IMG)
	sh tests/vga-console/scripts/check_qemu_vga_t1.sh $(DISK_IMG)

check-vga-t2: $(DISK_IMG)
	sh tests/vga-console/scripts/check_qemu_vga_t2.sh $(DISK_IMG)

check-vga-t3: $(DISK_IMG)
	sh tests/vga-console/scripts/check_qemu_vga_t3.sh $(DISK_IMG)

check-vga-t4: $(DISK_IMG)
	sh tests/vga-console/scripts/check_qemu_vga_t4.sh $(DISK_IMG)

check-vga-t5: $(DISK_IMG)
	sh tests/vga-console/scripts/check_qemu_vga_t5.sh $(DISK_IMG)

check-vga-t6: $(DISK_IMG)
	sh tests/vga-console/scripts/check_qemu_vga_t6.sh $(DISK_IMG)

check-vga-all: check-vga-t1 check-vga-t2 check-vga-t3 check-vga-t4 check-vga-t5 check-vga-t6

check-t1: check-boot

check-t2: check-qemu-m2

check-t3: check-qemu-t3

check-t4: check-qemu-t4

check-t5: check-qemu-t5

check-all: check-t1 check-qemu-m1 check-t2 check-t3 check-t4 check-t5 check-pm-all check-ih-all check-hi-all check-vga-all

clean:
	rm -rf build
