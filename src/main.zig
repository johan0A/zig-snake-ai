const std = @import("std");

const GRID_SIZE: u16 = 17;

const Cell_state_type = enum {
    snake,
    fruit,
    empty,
};

const Cell_state = union(Cell_state_type) {
    snake: u8,
    fruit: void,
    empty: void,
};

const Snake_direction = enum([2]i8) {
    up = .{ 0, 1 },
    right = .{ 1, 0 },
    down = .{ 0, -1 },
    left = .{ -1, 0 },
};

const GameState = struct {
    value_grid: [GRID_SIZE * GRID_SIZE]Cell_state = undefined,
    grid_size: u16 = GRID_SIZE,
    snake_head: [2]u16 = undefined,
    snake_head_rotation: Snake_direction = undefined,

    pub fn init() GameState {
        const grid = GameState{
            .value_grid = [_]Cell_state{Cell_state.empty} ** (GRID_SIZE * GRID_SIZE),
            .snake_head = .{ GRID_SIZE / 2, GRID_SIZE / 2 },
            .snake_head_rotation = Snake_direction.up,
        };
        return grid;
    }

    pub fn set(this: *@This(), x: u16, y: u16, value: Cell_state) void {
        this.*.value_grid[x + y * this.grid_size] = value;
    }

    pub fn get(this: @This(), x: u16, y: u16) Cell_state {
        return this.value_grid[x + y * this.grid_size];
    }

    pub fn show_grid(this: @This()) void {
        for (0..this.grid_size) |_| {
            std.debug.print("==", .{});
        }
        std.debug.print("\n", .{});
        var i: u16 = 0;
        while (i < this.grid_size - 1) : (i += 1) {
            std.debug.print("=", .{});
            var j: u16 = 0;
            while (j < this.grid_size - 1) : (j += 1) {
                switch (this.get(i, j)) {
                    .empty => std.debug.print(" ", .{}),
                    .fruit => std.debug.print("f", .{}),
                    .snake => std.debug.print("*", .{}),
                }
                std.debug.print(" ", .{});
            }
            std.debug.print("=\n", .{});
        }
        for (0..this.grid_size) |_| {
            std.debug.print("==", .{});
        }
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
    var grid = GameState.init();
    grid.show_grid();
    const controller = AIcontroller.init(&grid);
    std.debug.print("{}", .{controller.grid_state.grid_size});
}
