#!/bin/bash

mkdir -p img/EFI/BOOT
cp zig-out/bin/BOOTX64.efi img/EFI/BOOT/BOOTX64.EFI

qemu-system-x86_64 \
    -bios /usr/share/ovmf/x64/OVMF.4m.fd \
    -drive format=raw,file=fat:rw:img \
    -m 256M \
    -net none \
    -serial stdio
