const std = @import("std");

const GRID_SIZE: u16 = 17;

const CellStateType = enum { snake, empty };

const CellState = union(CellStateType) { snake: u16, empty: void };

const GridDirection = enum {
    up,
    right,
    down,
    left,
    fn toVector(this: GridDirection) [2]i8 {
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
    head_rot: GridDirection = undefined,
    default_snake_len: u16 = undefined,
    snake_len: u16 = undefined,
    rng_gen: std.Random = undefined,

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
            .head_rot = GridDirection.up,
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

    pub fn get(this: @This(), pos: [2]u16) CellState {
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
    game_state: *GameState = undefined,
    allocator: std.mem.Allocator = undefined,

    fn init(gameState: *GameState, allocator: std.mem.Allocator) AIcontroller {
        return AIcontroller{
            .game_state = gameState,
            .allocator = allocator,
        };
    }

    fn get_neighbors(self: @This(), pos: [2]i32, direction: GridDirection) [2]i32 {
        return @as([2]i32, self.game_state.get(.{ pos[0] + direction.toVector()[0], pos[1] + direction.toVector()[1] }));
    }

    fn distance(pos1: [2]i32, pos2: [2]i32) f32 {
        return @sqrt(@as(f32, @floatFromInt((pos1[0] - pos2[0]) *| (pos1[0] + pos2[0]) + (pos1[1] - pos2[1]) *| (pos1[1] + pos2[1]))));
    }

    fn get_direction(self: @This(), target: [2]i32) !GridDirection {
        const CellWithDistanceToTarget = struct {
            cell: [2]i32,
            distance_to_target: f32,
        };

        const LocalUtils = struct {
            fn orderedInsert(boundary_cells: *std.ArrayList(CellWithDistanceToTarget), item_to_insert: CellWithDistanceToTarget) !void {
                var range_start: usize = 0;
                var range_end: usize = boundary_cells.items.len;
                var sample_index: usize = undefined;

                var result_index = while (range_end > range_start) {
                    sample_index = range_start / 2 + range_end / 2;
                    if (boundary_cells.items[sample_index].distance_to_target == item_to_insert.distance_to_target) {
                        break sample_index;
                    }

                    if (boundary_cells.items[sample_index].distance_to_target > item_to_insert.distance_to_target) {
                        range_start = sample_index + 1;
                    } else {
                        range_end = sample_index - 1;
                    }
                } else range_start;

                while (result_index < boundary_cells.items.len and boundary_cells.items[result_index + 1] > item_to_insert) {
                    result_index += 1;
                }
                try boundary_cells.insert(result_index, item_to_insert);
            }
        };

        var boundary_cells = std.ArrayList(CellWithDistanceToTarget).init(self.allocator);
        defer boundary_cells.deinit();

        try boundary_cells.append(.{
            .cell = [2]i32{
                self.game_state.head_pos[0],
                self.game_state.head_pos[1],
            },
            .distance_to_target = distance(target, .{
                @as(i32, self.game_state.head_pos[0]),
                @as(i32, self.game_state.head_pos[1]),
            }),
        });

        var cell_score_map = std.AutoHashMap([2]i32, i32).init(self.allocator);
        defer cell_score_map.deinit();

        try cell_score_map.put(
            .{
                self.game_state.head_pos[0],
                self.game_state.head_pos[0],
            },
            0,
        );

        var previous_on_path_of_cell = std.AutoHashMap([2]i32, [2]i32).init(self.allocator);
        defer previous_on_path_of_cell.deinit();

        while (boundary_cells.items.len > 0) {
            var current = boundary_cells.pop().cell;

            if (std.mem.eql(i32, &current, &target)) {
                var previous_on_path = previous_on_path_of_cell.get(current).?;
                // while (!std.mem.allEqual(
                //     [2]u16,
                //     self.game_state.get(@truncate(previous_on_path)),
                //     @as(u16[2], target),
                // )) {
                while (!std.mem.eql(
                    u16,
                    self.game_state.get([_]u16{ @intCast(previous_on_path[0]), @intCast(previous_on_path[1]) }),
                    @as(u16[2], target),
                )) {
                    current = previous_on_path;
                    previous_on_path = previous_on_path_of_cell.get(previous_on_path);
                }
                return GridDirection.fromVector(.{
                    @truncate(current[0] - target[0]),
                    @truncate(current[1] - target[1]),
                });
            }

            for (std.enums.values(GridDirection)) |i| {
                const neighbor = self.get_neighbors(target, i);

                const neighbor_possible_new_score = cell_score_map.get(current) + 1;
                const neighbor_cell_score = cell_score_map.get(neighbor);

                if (neighbor_cell_score == null or neighbor_possible_new_score > neighbor_cell_score.?) {
                    switch (self.game_state.get(@truncate(neighbor))) {
                        .snake => |snake| if (snake <= neighbor_possible_new_score) continue,
                        else => {},
                    }
                    if (neighbor_cell_score == null) {
                        try LocalUtils.orderedInsert(boundary_cells, self.distance(neighbor, target));
                    }
                    try previous_on_path_of_cell.put(neighbor, current);
                    try cell_score_map.put(neighbor, neighbor_possible_new_score);
                }
            }
        }
        std.debug.print("failed to find path\n", .{});
        return GridDirection.up;
    }
};

pub fn main() !void {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.debug.print("Allocator leaked!\n", .{});
    const alocator = gpa.allocator();

    var grid = GameState.init(5, prng.random());
    grid.showGrid();

    const controller = AIcontroller.init(&grid, alocator);

    _ = try controller.get_direction(.{ 0, 0 });
    std.debug.print("{}\n", .{controller.game_state.grid_size});
}
