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

        head_pos: @Vector(2, isize) = undefined,
        head_rot: GridDirection = undefined,

        fruit_pos: @Vector(2, isize) = undefined,

        rng_gen: std.Random = undefined,

        pub fn init(snake_len: u32, rng_gen: std.Random) Self {
            var grid = Self{
                .default_snake_len = snake_len,
                .rng_gen = rng_gen,
            };
            grid.reset();
            return grid;
        }

        pub fn moveFruitToRandomPos(self: *Self) void {
            self.*.fruit_pos = .{
                self.rng_gen.intRangeAtMost(@TypeOf(self.fruit_pos[0]), 0, grid_size - 1),
                self.rng_gen.intRangeAtMost(@TypeOf(self.fruit_pos[0]), 0, grid_size - 1),
            };
        }

        pub fn reset(self: *Self) void {
            var game_state = Self{
                .value_grid = .{[_]CellState{CellState.empty} ** grid_size} ** grid_size,
                .head_pos = .{ @divTrunc(grid_size, 2), @divTrunc(grid_size, 2) },
                .fruit_pos = undefined,
                .head_rot = GridDirection.up,
                .snake_len = self.default_snake_len,
                .default_snake_len = self.default_snake_len,
                .rng_gen = self.rng_gen,
            };
            game_state.moveFruitToRandomPos();
            game_state.value_grid[@intCast(game_state.head_pos[0])][@intCast(game_state.head_pos[1])] = CellState{ .snake = game_state.snake_len };
            self.* = game_state;
        }

        fn outOfBounds(_: Self, pos: @Vector(2, isize)) bool {
            return pos[0] < 0 or pos[1] < 0 or pos[0] >= grid_size or pos[1] >= grid_size;
        }

        fn get(self: Self, pos: @Vector(2, isize)) ?CellState {
            if (self.outOfBounds(pos)) return null;
            return self.value_grid[@intCast(pos[0])][@intCast(pos[1])];
        }

        fn updateGameState(self: *Self) void {
            for (0..grid_size) |reverse_y| {
                const y = grid_size - reverse_y - 1;
                for (0..grid_size) |x| {
                    switch (self.value_grid[x][y]) {
                        .snake => |*cell| {
                            if (cell.* > 0) cell.* -= 1 else self.value_grid[x][y] = CellState.empty;
                        },
                        else => {},
                    }
                }
            }

            self.head_pos += self.head_rot.toVector();

            var has_died: bool = false;

            if (self.outOfBounds(self.head_pos)) {
                has_died = true;
            } else {
                switch (self.get(self.*.head_pos).?) {
                    .snake => has_died = true,
                    else => {},
                }
            }
            if (has_died) {
                std.debug.print("dead\n", .{});
                self.*.reset();
                return;
            }

            self.value_grid[@bitCast(self.head_pos[0])][@bitCast(self.head_pos[1])] = CellState{ .snake = self.snake_len };
        }

        pub fn printGrid(self: Self) void {
            for (0..(grid_size + 2) * 2) |_| std.debug.print("=", .{});
            std.debug.print("\n", .{});
            for (0..grid_size) |y| {
                std.debug.print("= ", .{});
                for (0..grid_size) |x| {
                    std.debug.print(" ", .{});
                    if (x == self.fruit_pos[0] and y == self.fruit_pos[1]) {
                        std.debug.print("f", .{});
                        continue;
                    }
                    switch (self.value_grid[x][grid_size - y - 1]) {
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
            for (0..(grid_size + 2) * 2) |_| std.debug.print("=", .{});
            std.debug.print("\n", .{});
        }
    };
}

const AIcontroller = struct {
    game_state: *GameState = undefined,
    allocator: std.mem.Allocator = undefined,

    fn init(gameState: *GameState, allocator: std.mem.Allocator) AIcontroller {
        return AIcontroller{
            .game_state = gameState,
            .allocator = allocator,
        };
    }

    fn get_neighbors(self: @This(), pos: @Vector(2, usize)) [4]@Vector(2, usize) {
        var result: [4]@Vector(2, usize) = undefined;
        inline for (std.enums.values(GridDirection), 0..) |value, i| {
            result[i] = pos + value.toVector();
        }
    }

    fn distance(pos1: @Vector(2, u32), pos2: @Vector(2, u32)) i32 {
        return (pos1[0] - pos2[0]) *| (pos1[0] + pos2[0]) + (pos1[1] - pos2[1]) *| (pos1[1] + pos2[1]);
    }

    fn get_direction(self: @This(), target: [2]i32) !GridDirection {}
};

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
