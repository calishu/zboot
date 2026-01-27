const uefi = @import("std").os.uefi;

pub fn main() void {
    const con_out = uefi.system_table.con_out.?;

    _ = con_out.reset(false) catch unreachable;

    _ = con_out.outputString(&[_:0]u16{ 'H', 'e', 'l', 'l', 'o', ',', ' ' }) catch unreachable;
    _ = con_out.outputString(&[_:0]u16{ 'W', 'o', 'r', 'l', 'd', '\r', '\n' }) catch unreachable;

    const boot_services = uefi.system_table.boot_services.?;

    _ = boot_services.stall(15 * 1000 * 1000) catch unreachable;
}
