pub const BootParams = extern struct {
    fb_ptr: [*]u32,
    width: u32,
    height: u32,
};
