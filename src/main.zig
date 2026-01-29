const std = @import("std");
const uefi = std.os.uefi;

const common = @import("kernel_common");

fn printUtf16(con_out: *uefi.protocol.SimpleTextOutput, comptime msg: []const u8) !void {
    _ = try con_out.*.outputString(std.unicode.utf8ToUtf16LeStringLiteral(msg ++ "\r\n"));
}

pub fn main() uefi.Error!void {
    const con_out = uefi.system_table.con_out.?;
    _ = try con_out.reset(false);
    _ = try printUtf16(con_out, "Starting boot...");

    const boot_services = uefi.system_table.boot_services.?;

    const loaded_image = (try boot_services.handleProtocol(
        uefi.protocol.LoadedImage,
        uefi.handle,
    )) orelse return error.NotFound;

    const fs = (try boot_services.handleProtocol(
        uefi.protocol.SimpleFileSystem,
        loaded_image.device_handle.?,
    )) orelse return error.NotFound;

    // get the kernel file
    _ = try printUtf16(con_out, "Get the kernel file");
    var root = try fs.openVolume();

    var kernel_file = try root.open(
        std.unicode.utf8ToUtf16LeStringLiteral("kernel.bin"),
        uefi.protocol.File.OpenMode.read,
        uefi.protocol.File.Attributes{ .read_only = true },
    );

    // determine file size
    _ = try printUtf16(con_out, "Determine kernel file size");
    var file_info_buffer: [128]u8 align(@alignOf(uefi.protocol.File.Info)) = undefined;

    _ = try kernel_file.getInfo(
        .file,
        &file_info_buffer
    );

    const file_info = @as(*uefi.protocol.File.Info, @ptrCast(&file_info_buffer));
    const kernel_size = file_info.file.size;

    // alloc mem for the kernel
    _ = try printUtf16(con_out, "Allocate memory for the kernel");
    const pages = (kernel_size + 0xfff) / 0x1000;
    const kernel_buffer = try boot_services.allocatePages(
        .any,
        .loader_data,
        pages,
    );
    const buffer_as_bytes = std.mem.sliceAsBytes(kernel_buffer);

    // get gop
    _ = try printUtf16(con_out, "Get graphics output protocol");

    const gop_optional = try boot_services.locateProtocol(
        uefi.protocol.GraphicsOutput,
        null,
    );
    if (gop_optional == null) {
        _ = try printUtf16(con_out, "GOP not found in the system");
        return uefi.Error.NotFound;
    }

    const params = common.BootParams{
        .fb_ptr = @ptrFromInt(gop_optional.?.mode.frame_buffer_base),
        .width = gop_optional.?.mode.info.horizontal_resolution,
        .height = gop_optional.?.mode.info.vertical_resolution,
    };

    // load kernel into mem
    // var read_size = kernel_size;
    _ = try printUtf16(con_out, "Load kernel into memory");
    _ = try kernel_file.read(buffer_as_bytes);

    const KernelEntry = *const fn (*const common.BootParams) callconv(.c) noreturn;
    const entry_point: KernelEntry = @ptrCast(kernel_buffer.ptr);

    _ = try printUtf16(con_out, "Jumping to kernel entry point");
    boot_services.exitBootServices(uefi.handle, "a");
    entry_point(&params); // Bye UEFI, I will miss you :(
    return;
}
