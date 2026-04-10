BOOT_SRC := src/bootloader/stage1/boot.asm
BOOT_BIN := build/boot.bin
BOOT_INVALID_BIN := build/boot.invalid.bin
KERNEL_SRC := src/kernel/stage0/kernel.asm
KERNEL_BIN := build/kernel.bin
DISK_IMG := build/disk.img

.PHONY: all clean check-boot check-qemu-m1 disk-image check-qemu-m2 check-qemu-t5 check-qemu-t3 check-qemu-t4 check-t1 check-t2 check-t3 check-t4 check-t5 check-all

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

$(DISK_IMG): $(BOOT_BIN) $(KERNEL_BIN)
	mkdir -p build
	dd if=/dev/zero of=$(DISK_IMG) bs=512 count=2880 status=none
	dd if=$(BOOT_BIN) of=$(DISK_IMG) conv=notrunc status=none
	dd if=$(KERNEL_BIN) of=$(DISK_IMG) bs=512 seek=1 conv=notrunc status=none

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

check-t1: check-boot

check-t2: check-qemu-m2

check-t3: check-qemu-t3

check-t4: check-qemu-t4

check-t5: check-qemu-t5

check-all: check-t1 check-qemu-m1 check-t2 check-t3 check-t4 check-t5

clean:
	rm -rf build
