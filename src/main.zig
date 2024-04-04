const std = @import("std");

const CellState = union(enum) { snake: u32, empty: void };

const GridDirection = enum {
    up,
    right,
    down,
    left,
    fn toVector(this: GridDirection) @Vector(2, i2) {
        return switch (this) {
            .up => .{ 0, 1 },
            .right => .{ 1, 0 },
            .down => .{ 0, -1 },
            .left => .{ -1, 0 },
        };
    }

    fn fromVector(vector: @Vector(2, i2)) GridDirection {
        if (vector[0] == 0) {
            if (vector[1] == 1) {
                return GridDirection.up;
            } else {
                return GridDirection.down;
            }
        } else {
            if (vector[0] == 1) {
                return GridDirection.right;
            } else {
                return GridDirection.left;
            }
        }
    }
};

fn intCastArray(comptime T: type, array: anytype) [array.len]T {
    var result: [array.len]T = undefined;
    for (&result, 0..) |*value, i| {
        value.* = @intCast(array[i]);
    }
    return result;
}

pub fn main() !void {
    std.debug.print("hellow world", .{});
}
