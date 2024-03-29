const std = @import("std");

const GRID_SIZE: u16 = 17;

const CellStateType = enum { snake, empty };

const CellState = union(CellStateType) { snake: u16, empty: void };

const SnakeDirection = enum {
    up,
    right,
    down,
    left,
    fn toVector(this: SnakeDirection) [2]i8 {
        return switch (this) {
            .up => .{ 0, 1 },
            .right => .{ 1, 0 },
            .down => .{ 0, -1 },
            .left => .{ -1, 0 },
        };
    }

    fn fromVector(array: i2[2]) GridDirection {
        if (array[0] == 0) {
            if (array[1] == 1) {
                return GridDirection.up;
            } else {
                return GridDirection.down;
            }
        } else {
            if (array[0] == 1) {
                return GridDirection.right;
            } else {
                return GridDirection.left;
            }
        }
    }
};

const GameState = struct {
    value_grid: [GRID_SIZE][GRID_SIZE]CellState = undefined,
    grid_size: u16 = GRID_SIZE,
    head_pos: [2]u16 = undefined,
    fruit_pos: [2]u16 = undefined,
    head_rot: SnakeDirection = undefined,
    default_snake_len: u16 = undefined,
    snake_len: u16 = undefined,
    rng_gen: std.Random,

    fn init(snake_len: u16, rng_gen: std.Random) GameState {
        var grid = GameState{
            .default_snake_len = snake_len,
            .rng_gen = rng_gen,
        };
        grid.reset();
        return grid;
    }

    fn new_fruit_at_random_pos(this: *@This()) void {
        this.*.fruit_pos = .{
            this.rng_gen.intRangeAtMost(u16, 0, this.grid_size - 1),
            this.rng_gen.intRangeAtMost(u16, 0, this.grid_size - 1),
        };
    }

    fn reset(this: *@This()) void {
        var game_state = GameState{
            .value_grid = .{[_]CellState{CellState.empty} ** GRID_SIZE} ** GRID_SIZE,
            .head_pos = .{ GRID_SIZE / 2, GRID_SIZE / 2 },
            .fruit_pos = .{ undefined, undefined },
            .head_rot = SnakeDirection.up,
            .snake_len = this.default_snake_len,
            .default_snake_len = this.default_snake_len,
            .rng_gen = this.rng_gen,
        };
        game_state.new_fruit_at_random_pos();
        this.* = game_state;
    }

    fn updateGameState(this: *@This()) void {
        var has_died: bool = false;

        var result = @as(i32, this.head_pos[0]) + this.head_rot.toVector()[0];
        if (result < 0) has_died = true;
        this.*.head_pos[0] = @intCast(result);

        result = @as(i32, this.head_pos[1]) + this.head_rot.toVector()[1];
        if (result < 0) has_died = true;
        this.*.head_pos[1] = @intCast(result);

        if (this.head_pos[0] > this.grid_size or this.head_pos[1] > this.grid_size) has_died = true;

        switch (this.get(this.*.head_pos)) {
            .snake => has_died = true,
            else => {},
        }

        if (has_died) {
            std.debug.print("dead", .{});
            this.*.reset();
            return;
        }

        this.set(this.head_pos, CellState{ .snake = this.snake_len });

        var i: u16 = 0;
        while (i < this.grid_size - 1) : (i += 1) {
            var j: u16 = 0;
            while (j < this.grid_size - 1) : (j += 1) {
                var square = this.get(.{ i, j });
                switch (square) {
                    .snake => |*snake| snake.* -= 1,
                    else => {},
                }
            }
        }
    }

    pub fn set(this: *@This(), pos: u16[2], value: CellState) void {
        this.*.value_grid[pos[0]][pos[0]] = value;
    }

    pub fn get(this: @This(), pos: u16[2]) CellState {
        return this.value_grid[pos[0]][pos[0]];
    }

    pub fn showGrid(this: @This()) void {
        for (0..(this.grid_size + 2) * 2) |_| std.debug.print("=", .{});
        std.debug.print("\n", .{});

        var i: i32 = this.grid_size - 1;
        while (i >= 0) : (i -= 1) {
            const i_u8: u8 = @intCast(i);
            std.debug.print("=", .{});
            var j: u16 = 0;
            while (j < this.grid_size) : (j += 1) {
                std.debug.print(" ", .{});
                if (i == this.fruit_pos[0] and j == this.fruit_pos[1]) {
                    std.debug.print("f", .{});
                    continue;
                }
                switch (this.get(.{ j, i_u8 })) {
                    .empty => std.debug.print(" ", .{}),
                    .snake => std.debug.print("*", .{}),
                }
            }
            std.debug.print("  =\n", .{});
        }

        for (0..(this.grid_size + 2) * 2) |_| std.debug.print("=", .{});
        std.debug.print("\n", .{});
    }
};

const AIcontroller = struct {
    grid_state: *GameState,

    fn init(gameState: *GameState) AIcontroller {
        return AIcontroller{
            .grid_state = gameState,
        };
    }
};

pub fn main() !void {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rng_gen = prng.random();
    std.debug.print("{}\n", .{rng_gen.intRangeAtMost(u16, 10, 20)});

    var grid = GameState.init(5, prng.random());
    grid.showGrid();
    const controller = AIcontroller.init(&grid);
    std.debug.print("{}", .{controller.grid_state.grid_size});
}
