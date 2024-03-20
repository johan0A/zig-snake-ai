const std = @import("std");

const GRID_SIZE: u16 = 17;

const CellStateType = enum {
    snake,
    fruit,
    empty,
};

const CellState = union(CellStateType) {
    snake: u16,
    empty: void,
};

const SnakeDirection = enum {
    up,
    right,
    down,
    left,
    fn direction(this: SnakeDirection) [2]i8 {
        return switch (this) {
            .up => .{ 0, 1 },
            .right => .{ 1, 0 },
            .down => .{ 0, -1 },
            .left => .{ -1, 0 },
        };
    }
};

const GameState = struct {
    value_grid: [GRID_SIZE][GRID_SIZE]CellState = undefined,
    grid_size: u16 = GRID_SIZE,
    head_pos: [2]u16 = undefined,
    fruit_pos: [2]u16 = undefined,
    head_rot: SnakeDirection = undefined,
    base_snake_len: u16 = undefined,
    snake_len: u16 = undefined,
    rng_gen: std.Random,

    fn init(snake_len: u16, rng_gen: std.Random) GameState {
        var grid = GameState{
            .base_snake_len = snake_len,
            .rng_gen = rng_gen,
        };
        grid.reset();
        return grid;
    }

    fn create_new_fruit(this: @This()) void {
        this.fruit_pos = .{
            this.rng_gen.intRangeAtMost(u16, 0, this.grid_size - 1),
            this.rng_gen.intRangeAtMost(u16, 0, this.grid_size - 1),
        };
    }

    fn reset(this: *@This()) void {
        const game_state = GameState{
            .value_grid = .{[_]CellState{CellState.empty} ** GRID_SIZE} ** GRID_SIZE,
            .head_pos = .{ GRID_SIZE / 2, GRID_SIZE / 2 },
            .fruit_pos = .{ undefined, undefined },
            .head_rot = SnakeDirection.up,
            .snake_len = this.base_snake_len,
            .base_snake_len = this.base_snake_len,
            .rng_gen = this.rng_gen,
        };
        this.* = game_state;
    }

    fn updateGameState(this: *@This()) void {
        var has_died: bool = false;

        var ov = @addWithOverflow(this.*.head_pos[0], this.head_pos[0]);
        if (ov[1] == 1) has_died = true;

        ov = @addWithOverflow(this.*.head_pos[1], this.head_pos[1]);
        if (ov[1] == 1) has_died = true;

        if (this.head_pos[0] > this.grid_size or this.head_pos[1] > this.grid_size) has_died = true;

        switch (this.get(this.*.head_pos[0], this.*.head_pos[0])) {
            .snake => has_died = true,
            else => {},
        }

        if (has_died) {
            std.debug.print("dead", .{});
            this.*.reset();
            return;
        }

        this.set(this.head_pos[0], this.head_pos[1], CellState{ .snake = this.snake_len });

        var i: u16 = 0;
        while (i < this.grid_size - 1) : (i += 1) {
            var j: u16 = 0;
            while (j < this.grid_size - 1) : (j += 1) {
                var square = this.get(i, j);
                switch (square) {
                    .snake => |*snake| snake.* -= 1,
                    else => {},
                }
            }
        }
    }

    pub fn set(this: *@This(), x: u16, y: u16, value: CellState) void {
        this.*.value_grid[x][y] = value;
    }

    pub fn get(this: @This(), x: u16, y: u16) CellState {
        return this.value_grid[x][y];
    }

    pub fn showGrid(this: @This()) void {
        for (0..(this.grid_size + 2) * 2) |_| std.debug.print("=", .{});
        std.debug.print("\n", .{});

        var i: u16 = 0;
        while (i < this.grid_size) : (i += 1) {
            std.debug.print("=", .{});
            var j: u16 = 0;
            while (j < this.grid_size) : (j += 1) {
                std.debug.print(" ", .{});
                if (i == this.fruit_pos[0] and j == this.fruit_pos[1]) {
                    std.debug.print("f", .{});
                    continue;
                }
                switch (this.get(i, j)) {
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
