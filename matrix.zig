const std = @import("std");
const utils = @import("utils.zig");
const epsilonEq = @import("utils.zig").epsilonEq;
const Tuple = @import("tuple.zig").Tuple;

pub fn Matrix(comptime Size: usize) type {
    return struct {
        const Self = @This();

        pub const num_rows = Size;
        pub const num_cols = Size;

        data: [num_rows][num_cols]f32 = undefined,

        pub fn eql(self: Self, other: Self) bool {
            for (self.data) |row, row_idx| {
                for (row) |val, col_idx| {
                    if (!epsilonEq(val, other.data[row_idx][col_idx]))
                        return false;
                }
            }

            return true;
        }

        pub fn mult(self: Self, other: Self) Self {
            const a = self.data;
            const b = other.data;

            var res = Self{};

            for (res.data) |*row, row_idx| {
                for (row) |*val, col_idx| {
                    val.* = 0.0;

                    var i: usize = 0;
                    while (i < Size) : (i += 1) {
                        val.* += a[row_idx][i] * b[i][col_idx];
                    }
                }
            }

            return res;
        }

        pub fn at(self: Self, row: usize, col: usize) f32 {
            return self.data[row][col];
        }
    };
}

pub const Mat2 = Matrix(2);
pub const Mat3 = Matrix(3);
pub const Mat4 = Matrix(4);

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

test "multiplying two matrices" {
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
            .{ -2, 1, 2, 3 },
            .{ 3, 2, 1, -1 },
            .{ 4, 3, 6, 5 },
            .{ 1, 2, 7, 8 },
        },
    };

    const result = a.mult(b);

    const expected = Mat4{
        .data = .{
            .{ 20, 22, 50, 48 },
            .{ 44, 54, 114, 108 },
            .{ 40, 58, 110, 102 },
            .{ 16, 26, 46, 42 },
        },
    };

    try std.testing.expect(result.eql(expected));
}
