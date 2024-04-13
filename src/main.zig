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

        pub fn new_fruit_at_random_pos(self: *Self) void {
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
            game_state.value_grid[@intCast(game_state.head_pos[0])][@intCast(game_state.head_pos[1])] = CellState{ .snake = game_state.snake_len };
            self.* = game_state;
        }

        fn updateGameState(self: *Self) void {
            var has_died: bool = false;

            if (self.head_pos[0] == 0 and self.head_rot.toVector()[0] == -1) {
                has_died = true;
            } else {
                self.head_pos[0] +%= @bitCast(@as(isize, @intCast(self.head_rot.toVector()[0])));
            }

            if (self.head_pos[1] == 0 and self.head_rot.toVector()[1] == -1) {
                has_died = true;
            } else {
                self.head_pos[1] +%= @bitCast(@as(isize, @intCast(self.head_rot.toVector()[1])));
            }

            if (self.head_pos[0] >= _grid_size or self.head_pos[1] >= _grid_size) has_died = true;

            if (has_died != true) {
            switch (self.get(self.*.head_pos)) {
                .snake => has_died = true,
                else => {},
                }
            }

            if (has_died) {
                std.debug.print("dead\n", .{});
                self.*.reset();
                return;
            }

            self.value_grid[self.head_pos[0]][self.head_pos[1]] = CellState{ .snake = self.snake_len };

            for (0.._grid_size) |y| {
                for (0.._grid_size) |x| {
                    switch (self.value_grid[x][_grid_size - y - 1]) {
                        .snake => |*cell| {
                            if (cell.* > 0) cell.* -= 1 else self.value_grid[x][_grid_size - y - 1] = CellState.empty;
                        },
                        else => {},
                    }
                }
            }
        }

        pub fn printGrid(self: Self) void {
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
                        .snake => |*snake| if (snake.* <= 9) {
                            std.debug.print("{}", .{snake.*});
                        } else {
                            std.debug.print("*", .{});
                        },
                    }
                }
                std.debug.print(" =\n", .{});
            }
            for (0..(_grid_size + 2) * 2) |_| std.debug.print("=", .{});
            std.debug.print("\n", .{});
        }
    };
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

    var grid = GameState(16).init(10, random);
    grid.printGrid();
    grid.head_rot = GridDirection.down;
    grid.updateGameState();
    grid.head_rot = GridDirection.left;
    grid.updateGameState();
    grid.head_rot = GridDirection.left;
    grid.updateGameState();
    grid.head_rot = GridDirection.down;
    grid.updateGameState();
    grid.head_rot = GridDirection.down;
    grid.updateGameState();
    grid.head_rot = GridDirection.left;
    grid.updateGameState();
    grid.head_rot = GridDirection.left;
    grid.updateGameState();
    grid.head_rot = GridDirection.down;
    grid.updateGameState();
    grid.printGrid();
}

pub fn main() !void {
    std.debug.print("hellow world", .{});
}
