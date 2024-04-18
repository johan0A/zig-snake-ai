const std = @import("std");

pub fn sPrint(args: anytype) void {
    if (@typeInfo(@TypeOf(args)) != .Struct) {
        @compileError("expected tuple or struct argument, found " ++ @typeName(@TypeOf(args)));
    }

    comptime var format_string_length = 0;
    inline for (std.meta.fields(@TypeOf(args))) |field_info| {
        const arg_type = @typeInfo(field_info.type);
        if (arg_type == .Pointer and @typeInfo(arg_type.Pointer.child).Array.child == u8 or arg_type == .Array and arg_type.Array.child == u8) {
            format_string_length += 4;
        } else {
            format_string_length += 6;
        }
    }
    comptime var format_string: [format_string_length]u8 = undefined;

    comptime var format_string_index: usize = 0;
    inline for (std.meta.fields(@TypeOf(args))) |field_info| {
        const arg_type = @typeInfo(field_info.type);
        if (arg_type == .Pointer and @typeInfo(arg_type.Pointer.child).Array.child == u8 or arg_type == .Array and arg_type.Array.child == u8) {
            inline for ("{s} ") |c| {
                format_string[format_string_index] = c;
                format_string_index += 1;
            }
        } else {
            inline for ("{any} ") |c| {
                format_string[format_string_index] = c;
                format_string_index += 1;
            }
        }
    }

    const runtime_format_string = @as([format_string_length]u8, format_string);
    std.debug.print(&runtime_format_string, args);
}
