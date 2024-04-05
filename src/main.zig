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

fn GameState(comptime grid_size: usize) type {
    return struct {
        const Self = @This();
        const _grid_size = grid_size;

        value_grid: [grid_size][grid_size]CellState = undefined,

        snake_len: u32 = undefined,
        default_snake_len: u32 = undefined,

        head_pos: @Vector(2, usize) = undefined,
        head_rot: GridDirection = undefined,

        fruit_pos: @Vector(2, usize) = undefined,

        rng_gen: std.Random = undefined,

        pub fn init(snake_len: u32, rng_gen: std.Random) Self {
            var grid = Self{
                .default_snake_len = snake_len,
                .rng_gen = rng_gen,
            };
            grid.reset();
            return grid;
        }

        pub fn set(this: *@This(), pos: @Vector(2, usize), value: CellState) void {
            this.*.value_grid[pos[0]][pos[0]] = value;
        }

        pub fn get(this: @This(), pos: @Vector(2, usize)) CellState {
            return this.value_grid[pos[0]][pos[1]];
        }

        pub fn new_fruit_at_random_pos(self: *@This()) void {
            self.*.fruit_pos = .{
                self.rng_gen.intRangeAtMost(usize, 0, _grid_size - 1),
                self.rng_gen.intRangeAtMost(usize, 0, _grid_size - 1),
            };
        }

        pub fn reset(self: *Self) void {
            var game_state = Self{
                .value_grid = .{[_]CellState{CellState.empty} ** _grid_size} ** _grid_size,
                .head_pos = .{ @divTrunc(_grid_size, 2), @divTrunc(_grid_size, 2) },
                .fruit_pos = undefined,
                .head_rot = GridDirection.up,
                .snake_len = self.default_snake_len,
                .default_snake_len = self.default_snake_len,
                .rng_gen = self.rng_gen,
            };
            game_state.new_fruit_at_random_pos();
            game_state.value_grid[@intCast(game_state.head_pos[0])][@intCast(game_state.head_pos[1])] = CellState{ .snake = self.snake_len };
            self.* = game_state;
        }

        pub fn showGrid(self: @This()) void {
            for (0..(_grid_size + 2) * 2) |_| std.debug.print("=", .{});
            std.debug.print("\n", .{});

            for (0.._grid_size) |y| {
                std.debug.print("= ", .{});
                for (0.._grid_size) |x| {
                    std.debug.print(" ", .{});
                    if (x == self.fruit_pos[0] and y == self.fruit_pos[1]) {
                        std.debug.print("f", .{});
                        continue;
                    }
                    switch (self.value_grid[x][_grid_size - y - 1]) {
                        .empty => std.debug.print(" ", .{}),
                        .snake => std.debug.print("*", .{}),
                    }
                }
                std.debug.print(" =\n", .{});
            }

            for (0..(_grid_size + 2) * 2) |_| std.debug.print("=", .{});
            std.debug.print("\n", .{});
        }
    };
}

fn intCastArray(comptime T: type, array: anytype) [array.len]T {
    var result: [array.len]T = undefined;
    for (&result, 0..) |*value, i| {
        value.* = @intCast(array[i]);
    }
    return result;
}

test "test" {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.debug.print("Allocator leaked!\n", .{});
    // const alocator = gpa.allocator();

    const grid = GameState(16).init(3, random);
    // std.debug.print("{any}\n", .{grid});

    grid.showGrid();
}

pub fn main() !void {
    std.debug.print("hellow world", .{});
}
