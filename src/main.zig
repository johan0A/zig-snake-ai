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

        pub fn init(this: @This()) void {
            std.debug.print("{}", .{this.grid_size});
            // set(this.grid_size / 2, this.grid_size / 2, Cell_state{ .snake = 0 });
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

const ResponseType = enum {
    okay,
    not_okay,
};

const Response = union(ResponseType) {
    okay: void,
    not_okay: usize,
};

test "AAA" {
    // This will fail to compile - error: no member named 'not_okay' in enum 'ResponseType'
    const resp = Response.okay;
    // resp = Response{ .not_okay = 1 };

    switch (resp) {
        .okay => std.debug.print("okay", .{}),
        .not_okay => std.debug.print("no okay", .{}),
    }

    // // This variant will succeed
    // var resp = Response{ .not_okay = 1 };
    // resp = Response.okay;
}

pub fn main() !void {
    var grid = GridState(16){};
    grid.init();
    std.debug.print("\n", .{});
    // const unionex = Cell_state{ .snake = 10 };
    // std.debug.print("{}", .{unionex});
    grid.set(5, 5, Cell_state.empty);
    // grid.value_grid[1] = Cell_state.empty;
    grid.show_grid();
}
