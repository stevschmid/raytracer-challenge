const std = @import("std");
const utils = @import("utils.zig");
const epsilonEq = @import("utils.zig").epsilonEq;

pub fn Matrix(comptime Rows: usize, comptime Columns: usize) type {
    return struct {
        const Self = @This();

        pub const num_rows = Rows;
        pub const num_cols = Columns;

        data: [num_rows][num_cols]f32 = undefined,

        pub fn eql(self: Self, other: Self) bool {
            var row: usize = 0;

            const is_equal = res: while (row < num_rows) : (row += 1) {
                var col: usize = 0;
                while (col < num_cols) : (col += 1) {
                    if (!epsilonEq(self.data[row][col], other.data[row][col]))
                        break :res false;
                }
            } else true;

            return is_equal;
        }

        pub fn at(self: Self, row: usize, col: usize) f32 {
            return self.data[row][col];
        }
    };
}

pub const Mat2 = Matrix(2, 2);
pub const Mat3 = Matrix(3, 3);
pub const Mat4 = Matrix(4, 4);

test "constructing and inspecting a 4x4 matrix" {
    const m = Mat4{
        .data = .{
            .{ 1, 2, 3, 4 },
            .{ 5.5, 6.5, 7.5, 8.5 },
            .{ 9, 10, 11, 12 },
            .{ 13.5, 14.5, 15.5, 16.5 },
        },
    };

    try utils.expectEpsilonEq(m.at(0, 0), 1);
    try utils.expectEpsilonEq(m.at(0, 3), 4);
    try utils.expectEpsilonEq(m.at(1, 0), 5.5);
    try utils.expectEpsilonEq(m.at(1, 2), 7.5);
    try utils.expectEpsilonEq(m.at(2, 2), 11);
    try utils.expectEpsilonEq(m.at(3, 0), 13.5);
    try utils.expectEpsilonEq(m.at(3, 2), 15.5);
}

test "a 2x2 matrix ought to be representable" {
    const m = Mat2{
        .data = .{
            .{ -3, 5 },
            .{ 1, -2 },
        },
    };

    try utils.expectEpsilonEq(m.at(0, 0), -3);
    try utils.expectEpsilonEq(m.at(0, 1), 5);
    try utils.expectEpsilonEq(m.at(1, 0), 1);
    try utils.expectEpsilonEq(m.at(1, 1), -2);
}

test "a 3x3 matrix ought to be representable" {
    const m = Mat3{
        .data = .{
            .{ -3, 5, 0 },
            .{ 1, -2, -7 },
            .{ 0, 1, 1 },
        },
    };

    try utils.expectEpsilonEq(m.at(0, 0), -3);
    try utils.expectEpsilonEq(m.at(1, 1), -2);
    try utils.expectEpsilonEq(m.at(2, 2), 1);
}

test "matrix equality with identical matrices" {
    const a = Mat4{
        .data = .{
            .{ 1, 2, 3, 4 },
            .{ 5, 6, 7, 8 },
            .{ 9, 8, 7, 6 },
            .{ 5, 4, 3, 2 },
        },
    };

    const b = Mat4{
        .data = .{
            .{ 1, 2, 3, 4 },
            .{ 5, 6, 7, 8 },
            .{ 9, 8, 7, 6 },
            .{ 5, 4, 3, 2 },
        },
    };

    try std.testing.expect(a.eql(b) == true);
}

test "matrix equality with different matrices" {
    const a = Mat4{
        .data = .{
            .{ 1, 2, 3, 4 },
            .{ 5, 6, 7, 8 },
            .{ 9, 8, 7, 6 },
            .{ 5, 4, 3, 2 },
        },
    };

    const b = Mat4{
        .data = .{
            .{ 1, 2, 3, 4 },
            .{ 5, 6, 7, 8 },
            .{ 9, 8, 7, 5 },
            .{ 5, 4, 3, 2 },
        },
    };

    try std.testing.expect(a.eql(b) == false);
}
