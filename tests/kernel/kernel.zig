const BootParams = @import("common.zig").BootParams;

// this is a very minimal dummy kernel, just to check if the bootloader works.
export fn kernel_main(params: *const BootParams) callconv(.C) noreturn {
    const color: u32 = 0xFFFF0000; // bright red
    const total_pixels = params.width * params.height;

    var i: usize = 0;
    while (i < total_pixels) : (i += 1) {
        params.fb_ptr[i] = color;
    }

    while (true) { asm volatile("hlt"); }
}
