const std = @import("std");
const expect = std.testing.expect;

const CellState = union(enum) {
    snake: u32,
    empty: void,
};

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
            if (vector[1] > 0) {
                return GridDirection.up;
            } else if (vector[1] < 0) {
                return GridDirection.down;
            }
        } else if (vector[1] == 0) {
            if (vector[0] > 0) {
                return GridDirection.right;
            } else if (vector[0] < 0) {
                return GridDirection.left;
            }
        }
        unreachable; // to change to an error
    }
};

test "GridDirection" {
    try expect(@reduce(.And, GridDirection.toVector(GridDirection.up) == @Vector(2, i2){ 0, 1 }));
    try expect(@reduce(.And, GridDirection.toVector(GridDirection.right) == @Vector(2, i2){ 1, 0 }));
    try expect(@reduce(.And, GridDirection.toVector(GridDirection.down) == @Vector(2, i2){ 0, -1 }));
    try expect(@reduce(.And, GridDirection.toVector(GridDirection.left) == @Vector(2, i2){ -1, 0 }));

    try expect(GridDirection.fromVector(.{ 0, 1 }) == GridDirection.up);
    try expect(GridDirection.fromVector(.{ 1, 0 }) == GridDirection.right);
    try expect(GridDirection.fromVector(.{ 0, -1 }) == GridDirection.down);
    try expect(GridDirection.fromVector(.{ -1, 0 }) == GridDirection.left);
}

fn GameState(comptime grid_size: usize) type {
    return struct {
        const Self = @This();
        const _grid_size = grid_size;

        value_grid: [grid_size][grid_size]CellState = undefined,

        snake_len: u32 = undefined,
        default_snake_len: u32 = undefined,

        head_pos: @Vector(2, i32) = undefined,
        head_rot: GridDirection = undefined,

        fruit_pos: @Vector(2, i32) = undefined,

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
            while (true) {
                const pos = .{
                    self.rng_gen.intRangeAtMost(@TypeOf(self.fruit_pos[0]), 0, grid_size - 1),
                    self.rng_gen.intRangeAtMost(@TypeOf(self.fruit_pos[0]), 0, grid_size - 1),
                };
                if (self.get(pos).? == .empty) {
                    self.*.fruit_pos = pos;
                    break;
                }
            }
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

        fn set(self: *Self, pos: @Vector(2, isize), value: CellState) void {
            self.*.value_grid[@intCast(pos[0])][@intCast(pos[1])] = value;
        }

        fn updateGameState(self: *Self) void {
            for (0..grid_size) |y| {
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

            if (@reduce(.And, self.head_pos == self.fruit_pos)) {
                self.snake_len += 1;
                self.moveFruitToRandomPos();
            }

            self.value_grid[@intCast(self.head_pos[0])][@intCast(self.head_pos[1])] = CellState{ .snake = self.snake_len };
        }

        pub fn printGrid(self: Self) void {
            for (0..(grid_size + 2) * 2) |_| std.debug.print("=", .{});
            std.debug.print("\n", .{});
            for (0..grid_size) |y| {
                const reverse_y = grid_size - y - 1;
                std.debug.print("= ", .{});
                for (0..grid_size) |x| {
                    std.debug.print(" ", .{});
                    if (x == self.fruit_pos[0] and reverse_y == self.fruit_pos[1]) {
                        std.debug.print("f", .{});
                        continue;
                    }
                    switch (self.value_grid[x][reverse_y]) {
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

fn AIcontroller(GameStateType: type) type {
    return struct {
        const Self = @This();
        const grid_size = GameStateType._grid_size;

        game_state: *GameState(grid_size) = undefined,
        allocator: std.mem.Allocator = undefined,

        fn init(gameState: *GameState(grid_size), allocator: std.mem.Allocator) Self {
            return Self{
                .game_state = gameState,
                .allocator = allocator,
            };
        }

        fn getCellNeighbors(self: Self, pos: @Vector(2, i32), buf: *[4]@Vector(2, i32)) []@Vector(2, i32) {
            var i: usize = 0;

            for (std.enums.values(GridDirection)) |value| {
                const newPos = pos + value.toVector();
                if (self.game_state.outOfBounds(newPos)) continue;
                buf[i] = newPos;
                i += 1;
            }

            return buf[0..i];
        }

        fn distanceScore(_: Self, pos1: @Vector(2, i32), pos2: @Vector(2, i32)) i32 {
            const dx = pos1[0] - pos2[0];
            const dy = pos1[1] - pos2[1];
            return dx *| dx +| dy *| dy;
        }

        fn getPathToTarget(self: Self, target: @Vector(2, i32)) !?[]GridDirection {
            var arena = std.heap.ArenaAllocator.init(self.allocator);
            defer arena.deinit();
            const allocator = arena.allocator();

            const start_pos = self.game_state.*.head_pos;

            const Context = struct {
                ai: *const Self,
                target: @Vector(2, i32),
            };
            const context = Context{
                .ai = &self,
                .target = target,
            };

            var openset = std.PriorityQueue(@Vector(2, i32), Context, struct {
                fn compare(ctx: Context, a: @Vector(2, i32), b: @Vector(2, i32)) std.math.Order {
                    return std.math.order(ctx.ai.distanceScore(a, ctx.target), ctx.ai.distanceScore(b, ctx.target));
                }
            }.compare).init(allocator, context);
            defer openset.deinit();
            try openset.add(start_pos);

            var cameFrom = std.AutoHashMap(@Vector(2, i32), @Vector(2, i32)).init(allocator);
            defer cameFrom.deinit();

            var gScore = std.AutoHashMap(@Vector(2, i32), i32).init(allocator);
            defer gScore.deinit();
            try gScore.put(start_pos, 0);

            while (openset.count() > 0) {
                // std.debug.print("count = {}\n", .{openset.count()});
                const current = openset.remove();
                // std.debug.print("check if finnished: current: {} == target: {}\n", .{ current, target });
                if (@reduce(.And, current == target)) {
                    var path = std.ArrayList(GridDirection).init(self.allocator);
                    defer path.deinit();
                    var _current = current;
                    // std.debug.print("found path\n", .{});
                    while (cameFrom.get(_current)) |next| {
                        // std.debug.print("next: {}, current = {} , _current - next = {}, \n", .{ next, current, next - current });
                        try path.append(GridDirection.fromVector(@truncate(_current - next)));
                        _current = next;
                    }
                    const path_slice = try path.toOwnedSlice();
                    std.mem.reverse(GridDirection, path_slice);
                    return path_slice;
                }

                var neighbors_buf: [4]@Vector(2, i32) = undefined;
                for (self.getCellNeighbors(current, &neighbors_buf)) |neighbor| {
                    // std.debug.print("count = {}\n", .{openset.count()});
                    // std.debug.print("neighbor: {}\n", .{neighbor});

                    const tentative_gScore = gScore.get(current).? + 1;

                    const neighbor_cell_value = self.game_state.get(neighbor).?;
                    switch (neighbor_cell_value) {
                        .snake => |snake| if (snake > tentative_gScore) continue,
                        // .snake => continue,
                        else => {},
                    }

                    if (gScore.get(neighbor)) |neighbor_gScore| {
                        // std.debug.print("gscore exist for neighbor\n", .{});
                        if (tentative_gScore < neighbor_gScore) {
                            try cameFrom.put(neighbor, current);
                            try gScore.put(neighbor, tentative_gScore);
                            try openset.add(neighbor);
                        }
                    } else {
                        // std.debug.print("gscore doesnt exist for neighbor\n", .{});
                        try cameFrom.put(neighbor, current);
                        try gScore.put(neighbor, tentative_gScore);
                        try openset.add(neighbor);
                    }
                }
            }
            std.debug.print("couldnt find path\n", .{});
            return null;
        }
    };
}

test "AIcontroller.getCellNeighbors" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.debug.print("Allocator leaked!\n", .{});

    const allocator = gpa.allocator();

    var prng = std.rand.DefaultPrng.init(2);
    const random = prng.random();

    var grid = GameState(16).init(5, random);

    const ai = AIcontroller(@TypeOf(grid)).init(&grid, allocator);

    var neighbors_buf: [4]@Vector(2, i32) = undefined;

    const ContainsFunc = struct {
        fn contains(slice: []@Vector(2, i32), value: @Vector(2, i32)) bool {
            for (slice) |v| {
                if (@reduce(.And, v == value)) return true;
            }
            return false;
        }
    };

    const neighbors = ai.getCellNeighbors(@Vector(2, i32){ 0, 0 }, &neighbors_buf);
    try expect(neighbors.len == 2);
    try expect(ContainsFunc.contains(neighbors, @Vector(2, i32){ 0, 1 }));
    try expect(ContainsFunc.contains(neighbors, @Vector(2, i32){ 1, 0 }));

    const _neighbors = ai.getCellNeighbors(@Vector(2, i32){ 1, 1 }, &neighbors_buf);
    try expect(_neighbors.len == 4);
    try expect(ContainsFunc.contains(_neighbors, @Vector(2, i32){ 0, 1 }));
    try expect(ContainsFunc.contains(_neighbors, @Vector(2, i32){ 1, 0 }));
    try expect(ContainsFunc.contains(_neighbors, @Vector(2, i32){ 1, 2 }));
    try expect(ContainsFunc.contains(_neighbors, @Vector(2, i32){ 2, 1 }));

    const __neighbors = ai.getCellNeighbors(@Vector(2, i32){ 15, 15 }, &neighbors_buf);
    try expect(__neighbors.len == 2);
    try expect(ContainsFunc.contains(__neighbors, @Vector(2, i32){ 15, 14 }));
    try expect(ContainsFunc.contains(__neighbors, @Vector(2, i32){ 14, 15 }));
}
    const random = prng.random();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.debug.print("Allocator leaked!\n", .{});

    var grid = GameState(32).init(5, random);
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

    const allocator = gpa.allocator();

    const ai = AIcontroller(GameState(32)).init(&grid, allocator);

    for (ai.getCellNeighbors(.{ 0, 0 })) |value| {
        std.debug.print("{}", .{value});
    }
}

pub fn main() !void {
    std.debug.print("hellow world", .{});
}
