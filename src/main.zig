const std = @import("std");

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

fn GridState(comptime size: u16) type {
    return struct {
        value_grid: [size * size]Cell_state = undefined,
        grid_size: u16 = size,

        pub fn init() GridState(size) {
            var grid = GridState(size){
                .value_grid = [_]Cell_state{Cell_state.empty} ** (size * size),
            };

            grid.set(
                grid.grid_size / 2,
                grid.grid_size / 2,
                Cell_state{ .snake = 0 },
            );

            return grid;
        }

        pub fn set(this: *@This(), x: u16, y: u16, value: Cell_state) void {
            this.*.value_grid[x + y * this.grid_size] = value;
        }

        pub fn get(this: @This(), x: u16, y: u16) Cell_state {
            return this.value_grid[x + y * this.grid_size];
        }

        pub fn show_grid(this: @This()) void {
            var i: u16 = 0;
            while (i < this.grid_size - 1) : (i += 1) {
                var j: u16 = 0;
                while (j < this.grid_size - 1) : (j += 1) {
                    switch (this.get(i, j)) {
                        .empty => std.debug.print(" ", .{}),
                        .fruit => std.debug.print("f", .{}),
                        .snake => std.debug.print("*", .{}),
                    }
                    std.debug.print(" ", .{});
                }
                std.debug.print("\n", .{});
            }
        }
    };
}

fn Range(comptime size: u16) type {
    return struct {
        value: u16 = size,
        value2: u16 = 5,

        pub fn contains(this: @This()) void {
            std.debug.print("{}", .{this.value});
        }
        pub fn contains2(this: @This()) void {
            this.contains();
        }
    };
}

pub fn main() !void {
    var grid = GridState(16).init();
    grid.show_grid();
}
