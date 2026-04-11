BOOT_SRC := src/bootloader/stage1/boot.asm
BOOT_BIN := build/boot.bin
BOOT_INVALID_BIN := build/boot.invalid.bin
KERNEL_SRC := src/kernel/stage0/kernel.asm
KERNEL_BIN := build/kernel.bin
KERNEL_PM_A20FAIL_BIN := build/kernel.pm.a20fail.bin
KERNEL_PM_BADSEL_BIN := build/kernel.pm.badsel.bin
KERNEL_IH_DIV0_BIN := build/kernel.ih.div0.bin
KERNEL_IH_UD2_BIN := build/kernel.ih.ud2.bin
KERNEL_IH_MULTI_BIN := build/kernel.ih.multi.bin
DISK_IMG := build/disk.img
DISK_PM_T2_IMG := build/disk-pm-t2.img
DISK_PM_T3_IMG := build/disk-pm-t3.img
DISK_IH_T2_IMG := build/disk-ih-t2.img
DISK_IH_T3_IMG := build/disk-ih-t3.img
DISK_IH_T4_IMG := build/disk-ih-t4.img

.PHONY: all clean check-boot check-qemu-m1 disk-image check-qemu-m2 check-qemu-t5 check-qemu-t3 check-qemu-t4 check-pm-t1 check-pm-t2 check-pm-t3 check-pm-all check-ih-t1 check-ih-t2 check-ih-t3 check-ih-t4 check-ih-all check-vga-t1 check-vga-t2 check-vga-t3 check-vga-t4 check-vga-t5 check-vga-all check-t1 check-t2 check-t3 check-t4 check-t5 check-all

all: $(BOOT_BIN) $(KERNEL_BIN)

$(BOOT_BIN): $(BOOT_SRC)
	mkdir -p build
	nasm -f bin -o $(BOOT_BIN) $(BOOT_SRC)

$(BOOT_INVALID_BIN): $(BOOT_SRC)
	mkdir -p build
	nasm -f bin -DKERNEL_SECTOR_COUNT=0 -o $(BOOT_INVALID_BIN) $(BOOT_SRC)

$(KERNEL_BIN): $(KERNEL_SRC)
	mkdir -p build
	nasm -f bin -o $(KERNEL_BIN) $(KERNEL_SRC)

$(KERNEL_PM_A20FAIL_BIN): $(KERNEL_SRC)
	mkdir -p build
	nasm -f bin -DFORCE_A20_FAILURE=1 -o $(KERNEL_PM_A20FAIL_BIN) $(KERNEL_SRC)

$(KERNEL_PM_BADSEL_BIN): $(KERNEL_SRC)
	mkdir -p build
	nasm -f bin -DCODE_SEL=0x18 -o $(KERNEL_PM_BADSEL_BIN) $(KERNEL_SRC)

$(KERNEL_IH_DIV0_BIN): $(KERNEL_SRC)
	mkdir -p build
	nasm -f bin -DEXCEPTION_TEST=1 -o $(KERNEL_IH_DIV0_BIN) $(KERNEL_SRC)

$(KERNEL_IH_UD2_BIN): $(KERNEL_SRC)
	mkdir -p build
	nasm -f bin -DEXCEPTION_TEST=2 -o $(KERNEL_IH_UD2_BIN) $(KERNEL_SRC)

$(KERNEL_IH_MULTI_BIN): $(KERNEL_SRC)
	mkdir -p build
	nasm -f bin -DINTERRUPT_TEST_MODE=1 -o $(KERNEL_IH_MULTI_BIN) $(KERNEL_SRC)

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

disk-image: $(DISK_IMG)

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

check-vga-all: check-vga-t1 check-vga-t2 check-vga-t3 check-vga-t4 check-vga-t5

check-t1: check-boot

check-t2: check-qemu-m2

check-t3: check-qemu-t3

check-t4: check-qemu-t4

check-t5: check-qemu-t5

check-all: check-t1 check-qemu-m1 check-t2 check-t3 check-t4 check-t5 check-pm-all check-ih-all check-vga-all

clean:
	rm -rf build
