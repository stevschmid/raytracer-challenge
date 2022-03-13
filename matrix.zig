const std = @import("std");
const utils = @import("utils.zig");
const epsilonEq = @import("utils.zig").epsilonEq;
const Vec4 = @import("vector.zig").Vec4;

pub const Mat2 = struct {
    const Self = @This();

    mat: [2][2]f32 = undefined,

    pub fn eql(self: Self, other: Self) bool {
        const a = self.mat;
        const b = other.mat;

        return epsilonEq(a[0][0], b[0][0]) and
            epsilonEq(a[0][1], b[0][1]) and
            epsilonEq(a[1][0], b[1][0]) and
            epsilonEq(a[1][1], b[1][1]);
    }

    pub fn determinant(self: Self) f32 {
        const m = self.mat;
        return m[0][0] * m[1][1] - m[0][1] * m[1][0];
    }

    pub fn at(self: Self, row: usize, col: usize) f32 {
        return self.mat[row][col];
    }
};

pub const Mat3 = struct {
    const Self = @This();

    mat: [3][3]f32 = undefined,

    pub fn at(self: Self, row: usize, col: usize) f32 {
        return self.mat[row][col];
    }

    pub fn eql(self: Self, other: Self) bool {
        for (self.mat) |row_values, row| {
            for (row_values) |val, col| {
                if (!epsilonEq(val, other.mat[row][col]))
                    return false;
            }
        }

        return true;
    }

    pub fn submatrix(self: Self, row: usize, col: usize) Mat2 {
        var res = Mat2{};

        var src_y: usize = 0;
        var dst_y: usize = 0;
        while (src_y < 3) : (src_y += 1) {
            if (src_y == row) continue;

            var src_x: usize = 0;
            var dst_x: usize = 0;
            while (src_x < 3) : (src_x += 1) {
                if (src_x == col) continue;

                res.mat[dst_y][dst_x] = self.mat[src_y][src_x];
                dst_x += 1;
            }

            dst_y += 1;
        }

        return res;
    }
};

pub const Mat4 = struct {
    const Self = @This();

    mat: [4][4]f32 = undefined,

    pub fn identity() Self {
        return .{
            .mat = .{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 0, 0, 0, 1 },
            },
        };
    }

    pub fn at(self: Self, row: usize, col: usize) f32 {
        return self.mat[row][col];
    }

    pub fn eql(self: Self, other: Self) bool {
        for (self.mat) |row_values, row| {
            for (row_values) |val, col| {
                if (!epsilonEq(val, other.mat[row][col]))
                    return false;
            }
        }

        return true;
    }

    pub fn mult(self: Self, other: Self) Self {
        const a = self.mat;
        const b = other.mat;

        var res = Self{};

        for (res.mat) |*row_values, row| {
            for (row_values) |*val, col| {
                val.* = a[row][0] * b[0][col] +
                    a[row][1] * b[1][col] +
                    a[row][2] * b[2][col] +
                    a[row][3] * b[3][col];
            }
        }

        return res;
    }

    pub fn multVec(self: Self, vec: Vec4) Vec4 {
        const m = self.mat;

        return Vec4.init(
            m[0][0] * vec.x + m[0][1] * vec.y + m[0][2] * vec.z + m[0][3] * vec.w,
            m[1][0] * vec.x + m[1][1] * vec.y + m[1][2] * vec.z + m[1][3] * vec.w,
            m[2][0] * vec.x + m[2][1] * vec.y + m[2][2] * vec.z + m[2][3] * vec.w,
            m[3][0] * vec.x + m[3][1] * vec.y + m[3][2] * vec.z + m[3][3] * vec.w,
        );
    }

    pub fn transpose(self: Self) Self {
        var res = Self{};

        for (res.mat) |*row_values, row| {
            for (row_values) |*val, col| {
                val.* = self.mat[col][row];
            }
        }

        return res;
    }

    pub fn submatrix(self: Self, row: usize, col: usize) Mat3 {
        var res = Mat3{};

        var src_y: usize = 0;
        var dst_y: usize = 0;
        while (src_y < 4) : (src_y += 1) {
            if (src_y == row) continue;

            var src_x: usize = 0;
            var dst_x: usize = 0;
            while (src_x < 4) : (src_x += 1) {
                if (src_x == col) continue;

                res.mat[dst_y][dst_x] = self.mat[src_y][src_x];
                dst_x += 1;
            }

            dst_y += 1;
        }

        return res;
    }
};

test "a 2x2 matrix ought to be representable" {
    const m = Mat2{
        .mat = .{
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
        .mat = .{
            .{ -3, 5, 0 },
            .{ 1, -2, -7 },
            .{ 0, 1, 1 },
        },
    };

    try utils.expectEpsilonEq(m.at(0, 0), -3);
    try utils.expectEpsilonEq(m.at(1, 1), -2);
    try utils.expectEpsilonEq(m.at(2, 2), 1);
}

test "constructing and inspecting a 4x4 matrix" {
    const m = Mat4{
        .mat = .{
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

test "matrix equality with identical matrices" {
    const a = Mat4{
        .mat = .{
            .{ 1, 2, 3, 4 },
            .{ 5, 6, 7, 8 },
            .{ 9, 8, 7, 6 },
            .{ 5, 4, 3, 2 },
        },
    };

    const b = Mat4{
        .mat = .{
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
        .mat = .{
            .{ 1, 2, 3, 4 },
            .{ 5, 6, 7, 8 },
            .{ 9, 8, 7, 6 },
            .{ 5, 4, 3, 2 },
        },
    };

    const b = Mat4{
        .mat = .{
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
        .mat = .{
            .{ 1, 2, 3, 4 },
            .{ 5, 6, 7, 8 },
            .{ 9, 8, 7, 6 },
            .{ 5, 4, 3, 2 },
        },
    };

    const b = Mat4{
        .mat = .{
            .{ -2, 1, 2, 3 },
            .{ 3, 2, 1, -1 },
            .{ 4, 3, 6, 5 },
            .{ 1, 2, 7, 8 },
        },
    };

    const result = a.mult(b);

    const expected = Mat4{
        .mat = .{
            .{ 20, 22, 50, 48 },
            .{ 44, 54, 114, 108 },
            .{ 40, 58, 110, 102 },
            .{ 16, 26, 46, 42 },
        },
    };

    try std.testing.expect(result.eql(expected));
}

test "a matrix multiplied by a tuple" {
    const a = Mat4{
        .mat = .{
            .{ 1, 2, 3, 4 },
            .{ 2, 4, 4, 2 },
            .{ 8, 6, 4, 1 },
            .{ 0, 0, 0, 1 },
        },
    };

    const b = Vec4.init(1, 2, 3, 1);

    const result = a.multVec(b);

    try std.testing.expect(result.eql(Vec4.init(18, 24, 33, 1)));
}

test "multiplying a matrix by the identity matrix" {
    const a = Mat4{
        .mat = .{
            .{ 0, 1, 2, 4 },
            .{ 1, 2, 4, 8 },
            .{ 2, 4, 8, 16 },
            .{ 4, 8, 16, 32 },
        },
    };

    const identity_matrix = Mat4.identity();

    try std.testing.expect(a.mult(identity_matrix).eql(a));
}

test "transposing a matrix" {
    const a = Mat4{
        .mat = .{
            .{ 0, 9, 3, 0 },
            .{ 9, 8, 0, 8 },
            .{ 1, 8, 5, 3 },
            .{ 0, 0, 5, 8 },
        },
    };

    const expected = Mat4{
        .mat = .{
            .{ 0, 9, 1, 0 },
            .{ 9, 8, 8, 0 },
            .{ 3, 0, 5, 5 },
            .{ 0, 8, 3, 8 },
        },
    };

    try std.testing.expect(a.transpose().eql(expected));
}

test "calculating the determinantof a 2x2 matrix" {
    const m = Mat2{
        .mat = .{
            .{ 1, 5 },
            .{ -3, 2 },
        },
    };

    try utils.expectEpsilonEq(m.determinant(), 17.0);
}

test "a submatrix of a 3x3 matrix is a 2x2 matrix" {
    const a = Mat3{
        .mat = .{
            .{ 1, 5, 0 },
            .{ -3, 2, 7 },
            .{ 0, 6, -3 },
        },
    };

    const expected = Mat2{
        .mat = .{
            .{ -3, 2 },
            .{ 0, 6 },
        },
    };

    try std.testing.expect(a.submatrix(0, 2).eql(expected));
}

test "a submatrix of a 4x4 matrix is a 3x3 matrix" {
    const a = Mat4{
        .mat = .{
            .{ -6, 1, 1, 6 },
            .{ -8, 5, 8, 6 },
            .{ -1, 0, 8, 2 },
            .{ -7, 1, -1, 1 },
        },
    };

    const expected = Mat3{
        .mat = .{
            .{ -6, 1, 6 },
            .{ -8, 8, 6 },
            .{ -7, -1, 1 },
        },
    };

    try std.testing.expect(a.submatrix(2, 1).eql(expected));
}
