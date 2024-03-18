const std = @import("std");

const GRID_SIZE: u16 = 17;

const CellStateType = enum {
    snake,
    fruit,
    empty,
};

const CellState = union(CellStateType) {
    snake: u8,
    fruit: void,
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
    value_grid: [GRID_SIZE * GRID_SIZE]CellState = undefined,
    grid_size: u16 = GRID_SIZE,
    snake_head: [2]u16 = undefined,
    snake_head_rotation: SnakeDirection = undefined,

    pub fn init() GameState {
        const grid = GameState{
            .value_grid = [_]CellState{CellState.empty} ** (GRID_SIZE * GRID_SIZE),
            .snake_head = .{ GRID_SIZE / 2, GRID_SIZE / 2 },
            .snake_head_rotation = SnakeDirection.up,
        };
        return grid;
    }

    pub fn set(this: *@This(), x: u16, y: u16, value: CellState) void {
        this.*.value_grid[x + y * this.grid_size] = value;
    }

    pub fn get(this: @This(), x: u16, y: u16) CellState {
        return this.value_grid[x + y * this.grid_size];
    }

    pub fn showGrid(this: @This()) void {
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
    grid.showGrid();
    const controller = AIcontroller.init(&grid);
    std.debug.print("{}", .{controller.grid_state.grid_size});
}
