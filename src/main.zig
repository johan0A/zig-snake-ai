const std = @import("std");

const Cell_state = union(enum) {
    snake: u8,
    fruit: void,
    empty: void,
};

fn GridState(comptime size: u16) type {
    return struct {
        value_grid: [size * size]Cell_state = undefined,
        grid_size: u16 = size,

        pub fn init(this: @This()) void {
            std.debug.print("{}", .{this.grid_size});
            // set(this.grid_size / 2, this.grid_size / 2, Cell_state{ .snake = 0 });
        }

        pub fn set(this: @This(), x: u16, y: u16, value: Cell_state) void {
            this.value_grid[x + y * this.grid_size] = value;
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

test "range-contains" {
    std.debug.print("A", .{});
}

pub fn main() !void {
    var grid = GridState(16){};
    grid.init();
    const unionex = Cell_state{ .snake = 10 };
    std.debug.print("{}", .{unionex});
    // grid.set(5, 5, Cell_state{ .snake = 0 });
    // grid.value_grid[1] = Cell_state{.empty};
    grid.show_grid();
}
