const std = @import("std");
const utils = @import("utils.zig");
const epsilonEq = @import("utils.zig").epsilonEq;
const vector = @import("vector.zig");
const Vec4 = vector.Vec4;

pub const Mat2 = struct {
    const Self = @This();

    pub const Size = 2;
    mat: [Size][Size]f64 = undefined,

    pub fn eql(self: Self, other: Self) bool {
        const a = self.mat;
        const b = other.mat;

        return epsilonEq(a[0][0], b[0][0]) and
            epsilonEq(a[0][1], b[0][1]) and
            epsilonEq(a[1][0], b[1][0]) and
            epsilonEq(a[1][1], b[1][1]);
    }

    pub fn determinant(self: Self) f64 {
        const m = self.mat;
        return m[0][0] * m[1][1] - m[0][1] * m[1][0];
    }

    pub fn at(self: Self, row: usize, col: usize) f64 {
        return self.mat[row][col];
    }
};

pub const Mat3 = struct {
    const Self = @This();

    pub const Size = 3;
    mat: [Size][Size]f64 = undefined,

    pub fn at(self: Self, row: usize, col: usize) f64 {
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

    pub fn minor(self: Self, row: usize, col: usize) f64 {
        const sub = self.submatrix(row, col);
        return sub.determinant();
    }

    pub fn cofactor(self: Self, row: usize, col: usize) f64 {
        const det = self.minor(row, col);
        const is_odd = ((row + col) % 2 != 0);
        return if (is_odd) -det else det;
    }

    pub fn determinant(self: Self) f64 {
        var det: f64 = 0;

        for (self.mat[0]) |val, col| {
            det += val * self.cofactor(0, col);
        }

        return det;
    }
};

pub const Mat4 = struct {
    const Self = @This();

    pub const Size = 4;
    mat: [Size][Size]f64 = undefined,

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

    pub fn translate(self: Self, x: f64, y: f64, z: f64) Self {
        return (Self{
            .mat = .{
                .{ 1, 0, 0, x },
                .{ 0, 1, 0, y },
                .{ 0, 0, 1, z },
                .{ 0, 0, 0, 1 },
            },
        }).mult(self);
    }

    pub fn scale(self: Self, x: f64, y: f64, z: f64) Self {
        return (Self{
            .mat = .{
                .{ x, 0, 0, 0 },
                .{ 0, y, 0, 0 },
                .{ 0, 0, z, 0 },
                .{ 0, 0, 0, 1 },
            },
        }).mult(self);
    }

    pub fn rotateX(self: Self, rad: f64) Self {
        return (Self{
            .mat = .{
                .{ 1, 0, 0, 0 },
                .{ 0, std.math.cos(rad), -std.math.sin(rad), 0 },
                .{ 0, std.math.sin(rad), std.math.cos(rad), 0 },
                .{ 0, 0, 0, 1 },
            },
        }).mult(self);
    }

    pub fn rotateY(self: Self, rad: f64) Self {
        return (Self{
            .mat = .{
                .{ std.math.cos(rad), 0, std.math.sin(rad), 0 },
                .{ 0, 1, 0, 0 },
                .{ -std.math.sin(rad), 0, std.math.cos(rad), 0 },
                .{ 0, 0, 0, 1 },
            },
        }).mult(self);
    }

    pub fn rotateZ(self: Self, rad: f64) Self {
        return (Self{
            .mat = .{
                .{ std.math.cos(rad), -std.math.sin(rad), 0, 0 },
                .{ std.math.sin(rad), std.math.cos(rad), 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 0, 0, 0, 1 },
            },
        }).mult(self);
    }

    pub fn shear(self: Self, xy: f64, xz: f64, yx: f64, yz: f64, zx: f64, zy: f64) Self {
        return (Self{
            .mat = .{
                .{ 1, xy, xz, 0 },
                .{ yx, 1, yz, 0 },
                .{ zx, zy, 1, 0 },
                .{ 0, 0, 0, 1 },
            },
        }).mult(self);
    }

    pub fn at(self: Self, row: usize, col: usize) f64 {
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

    pub fn minor(self: Self, row: usize, col: usize) f64 {
        const sub = self.submatrix(row, col);
        return sub.determinant();
    }

    pub fn cofactor(self: Self, row: usize, col: usize) f64 {
        const det = self.minor(row, col);
        const is_odd = ((row + col) % 2 != 0);
        return if (is_odd) -det else det;
    }

    pub fn determinant(self: Self) f64 {
        var det: f64 = 0;

        for (self.mat[0]) |val, col| {
            det += val * self.cofactor(0, col);
        }

        return det;
    }

    pub fn isInvertible(self: Self) bool {
        return !epsilonEq(self.determinant(), 0);
    }

    pub fn inverse(self: Self) Self {
        const det = self.determinant();
        std.debug.assert(!epsilonEq(det, 0.0));

        var res = Mat4{};

        for (res.mat) |*row_values, row| {
            for (row_values) |*val, col| {
                const c = self.cofactor(col, row); // swapped to transpose end result
                val.* = c / det;
            }
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

test "calculating a minor of a 3x3 matrix" {
    const a = Mat3{
        .mat = .{
            .{ 3, 5, 0 },
            .{ 2, -1, -7 },
            .{ 6, -1, 5 },
        },
    };

    try utils.expectEpsilonEq(a.minor(1, 0), 25.0);
}

test "calculating a cofactor of a 3x3 matrix" {
    const a = Mat3{
        .mat = .{
            .{ 3, 5, 0 },
            .{ 2, -1, -7 },
            .{ 6, -1, 5 },
        },
    };

    try utils.expectEpsilonEq(a.minor(0, 0), -12);
    try utils.expectEpsilonEq(a.cofactor(0, 0), -12);

    try utils.expectEpsilonEq(a.minor(1, 0), 25);
    try utils.expectEpsilonEq(a.cofactor(1, 0), -25);
}

test "calculating the determinant of a 3x3 matrix" {
    const a = Mat3{
        .mat = .{
            .{ 1, 2, 6 },
            .{ -5, 8, -4 },
            .{ 2, 6, 4 },
        },
    };

    try utils.expectEpsilonEq(a.cofactor(0, 0), 56);
    try utils.expectEpsilonEq(a.cofactor(0, 1), 12);
    try utils.expectEpsilonEq(a.cofactor(0, 2), -46);
    try utils.expectEpsilonEq(a.determinant(), -196);
}

test "calculating the determinant of a 4x4 matrix" {
    const a = Mat4{
        .mat = .{
            .{ -2, -8, 3, 5 },
            .{ -3, 1, 7, 3 },
            .{ 1, 2, -9, 6 },
            .{ -6, 7, 7, -9 },
        },
    };

    try utils.expectEpsilonEq(a.cofactor(0, 0), 690);
    try utils.expectEpsilonEq(a.cofactor(0, 1), 447);
    try utils.expectEpsilonEq(a.cofactor(0, 2), 210);
    try utils.expectEpsilonEq(a.cofactor(0, 3), 51);
    try utils.expectEpsilonEq(a.determinant(), -4071);
}

test "testing an invertible matrix for invertibility" {
    const a = Mat4{
        .mat = .{
            .{ 6, 4, 4, 4 },
            .{ 5, 5, 7, 6 },
            .{ 4, -9, 3, -7 },
            .{ 9, 1, 7, -6 },
        },
    };

    try utils.expectEpsilonEq(a.determinant(), -2120);
    try std.testing.expect(a.isInvertible());
}

test "testing an noninvertible matrix for invertibility" {
    const a = Mat4{
        .mat = .{
            .{ -4, 2, -2, -3 },
            .{ 9, 6, 2, 6 },
            .{ 0, -5, 1, -5 },
            .{ 0, 0, 0, 0 },
        },
    };

    try utils.expectEpsilonEq(a.determinant(), 0);
    try std.testing.expect(!a.isInvertible());
}

test "calculating the inverse of a matrix" {
    const a = Mat4{
        .mat = .{
            .{ -5, 2, 6, -8 },
            .{ 1, -5, 1, 8 },
            .{ 7, 7, -6, -7 },
            .{ 1, -3, 7, 4 },
        },
    };

    const b = a.inverse();

    const expected = Mat4{
        .mat = .{
            .{ 0.21805, 0.45113, 0.24060, -0.04511 },
            .{ -0.80827, -1.45677, -0.44361, 0.52068 },
            .{ -0.07895, -0.22368, -0.05263, 0.19737 },
            .{ -0.52256, -0.81391, -0.30075, 0.30639 },
        },
    };

    try utils.expectEpsilonEq(a.determinant(), 532);
    try utils.expectEpsilonEq(a.cofactor(2, 3), -160);
    try utils.expectEpsilonEq(b.at(3, 2), -160.0 / 532.0);
    try utils.expectEpsilonEq(a.cofactor(3, 2), 105);
    try utils.expectEpsilonEq(b.at(2, 3), 105.0 / 532.0);

    try utils.expectMatrixApproxEq(b, expected);
}

test "calculating the inverse of another matrix" {
    const a = Mat4{
        .mat = .{
            .{ 8, -5, 9, 2 },
            .{ 7, 5, 6, 1 },
            .{ -6, 0, 9, 6 },
            .{ -3, 0, -9, -4 },
        },
    };

    const expected = Mat4{
        .mat = .{
            .{ -0.15385, -0.15385, -0.28205, -0.53846 },
            .{ -0.07692, 0.12308, 0.02564, 0.03077 },
            .{ 0.35897, 0.35897, 0.43590, 0.92308 },
            .{ -0.69231, -0.69231, -0.76923, -1.92308 },
        },
    };

    try utils.expectMatrixApproxEq(a.inverse(), expected);
}

test "calculating the inverse of a third matrix" {
    const a = Mat4{
        .mat = .{
            .{ 9, 3, 0, 9 },
            .{ -5, -2, -6, -3 },
            .{ -4, 9, 6, 4 },
            .{ -7, 6, 6, 2 },
        },
    };

    const expected = Mat4{
        .mat = .{
            .{ -0.04074, -0.07778, 0.14444, -0.22222 },
            .{ -0.07778, 0.03333, 0.36667, -0.33333 },
            .{ -0.02901, -0.14630, -0.10926, 0.12963 },
            .{ 0.17778, 0.06667, -0.26667, 0.33333 },
        },
    };

    try utils.expectMatrixApproxEq(a.inverse(), expected);
}

test "multiplying a product by its inverse" {
    const a = Mat4{
        .mat = .{
            .{ 3, -9, 7, 3 },
            .{ 3, -8, 2, -9 },
            .{ -4, 4, 4, 1 },
            .{ -6, 5, -1, 1 },
        },
    };

    const b = Mat4{
        .mat = .{
            .{ 8, 2, 2, 2 },
            .{ 3, -1, 7, 0 },
            .{ 7, 0, 5, 4 },
            .{ 6, -2, 0, 5 },
        },
    };

    const c = a.mult(b);

    const result = c.mult(b.inverse());
    try utils.expectMatrixApproxEq(a, result);
}

test "multiplying by a translation matrix" {
    const transform = Mat4.identity().translate(5, -3, 2);
    const p = vector.initPoint(-3, 4, 5);

    try std.testing.expect(transform.multVec(p).eql(vector.initPoint(2, 1, 7)));
}

test "multiplying by the inverse of a translation matrix" {
    const transform = Mat4.identity().translate(5, -3, 2);
    const inv = transform.inverse();
    const p = vector.initPoint(-3, 4, 5);

    try std.testing.expect(inv.multVec(p).eql(vector.initPoint(-8, 7, 3)));
}

test "translation does not affect vectors" {
    const transform = Mat4.identity().translate(5, -3, 2);
    const v = vector.initVector(-3, 4, 5);

    try std.testing.expect(transform.multVec(v).eql(v));
}

test "a scaling matrix applied to a point" {
    const transform = Mat4.identity().scale(2, 3, 4);
    const p = vector.initPoint(-4, 6, 8);

    try std.testing.expect(transform.multVec(p).eql(vector.initPoint(-8, 18, 32)));
}

test "a scaling matrix applied to a vector" {
    const transform = Mat4.identity().scale(2, 3, 4);
    const v = vector.initVector(-4, 6, 8);

    try std.testing.expect(transform.multVec(v).eql(vector.initVector(-8, 18, 32)));
}

test "multiplying by the inverse of a scaling matrix" {
    const transform = Mat4.identity().scale(2, 3, 4);
    const inv = transform.inverse();
    const v = vector.initVector(-4, 6, 8);

    try std.testing.expect(inv.multVec(v).eql(vector.initVector(-2, 2, 2)));
}

test "reflection is scaling by a negative value" {
    const transform = Mat4.identity().scale(-1, 1, 1);
    const p = vector.initPoint(2, 3, 4);

    try std.testing.expect(transform.multVec(p).eql(vector.initPoint(-2, 3, 4)));
}

test "rotating a point around the x axis" {
    const p = vector.initPoint(0, 1, 0);

    const half_quarter = Mat4.identity().rotateX(std.math.pi / 4.0);
    const full_quarter = Mat4.identity().rotateX(std.math.pi / 2.0);

    try std.testing.expect(half_quarter.multVec(p).eql(vector.initPoint(0, std.math.sqrt(2.0) / 2.0, std.math.sqrt(2.0) / 2.0)));
    try std.testing.expect(full_quarter.multVec(p).eql(vector.initPoint(0, 0, 1)));
}

test "the inverse of an x-rotation rotates in the opposite direction" {
    const p = vector.initPoint(0, 1, 0);
    const half_quarter = Mat4.identity().rotateX(std.math.pi / 4.0);
    const inv = half_quarter.inverse();

    try std.testing.expect(inv.multVec(p).eql(vector.initPoint(0, std.math.sqrt(2.0) / 2.0, -std.math.sqrt(2.0) / 2.0)));
}

test "rotating a point around the y axis" {
    const p = vector.initPoint(0, 0, 1);

    const half_quarter = Mat4.identity().rotateY(std.math.pi / 4.0);
    const full_quarter = Mat4.identity().rotateY(std.math.pi / 2.0);

    try std.testing.expect(half_quarter.multVec(p).eql(vector.initPoint(std.math.sqrt(2.0) / 2.0, 0, std.math.sqrt(2.0) / 2.0)));
    try std.testing.expect(full_quarter.multVec(p).eql(vector.initPoint(1, 0, 0)));
}

test "rotating a point around the z axis" {
    const p = vector.initPoint(0, 1, 0);

    const half_quarter = Mat4.identity().rotateZ(std.math.pi / 4.0);
    const full_quarter = Mat4.identity().rotateZ(std.math.pi / 2.0);

    try std.testing.expect(half_quarter.multVec(p).eql(vector.initPoint(-std.math.sqrt(2.0) / 2.0, std.math.sqrt(2.0) / 2.0, 0)));
    try std.testing.expect(full_quarter.multVec(p).eql(vector.initPoint(-1, 0, 0)));
}

test "shearing" {
    const p = vector.initPoint(2, 3, 4);

    {
        // x moves in proportion to y
        const transform = Mat4.identity().shear(1, 0, 0, 0, 0, 0);
        try std.testing.expect(transform.multVec(p).eql(vector.initPoint(5, 3, 4)));
    }

    {
        // x moves in proportion to z
        const transform = Mat4.identity().shear(0, 1, 0, 0, 0, 0);
        try std.testing.expect(transform.multVec(p).eql(vector.initPoint(6, 3, 4)));
    }

    {
        // y moves in proportion to x
        const transform = Mat4.identity().shear(0, 0, 1, 0, 0, 0);
        try std.testing.expect(transform.multVec(p).eql(vector.initPoint(2, 5, 4)));
    }

    {
        // y moves in proportion to z
        const transform = Mat4.identity().shear(0, 0, 0, 1, 0, 0);
        try std.testing.expect(transform.multVec(p).eql(vector.initPoint(2, 7, 4)));
    }

    {
        // z moves in proportion to x
        const transform = Mat4.identity().shear(0, 0, 0, 0, 1, 0);
        try std.testing.expect(transform.multVec(p).eql(vector.initPoint(2, 3, 6)));
    }

    {
        // z moves in proportion to y
        const transform = Mat4.identity().shear(0, 0, 0, 0, 0, 1);
        try std.testing.expect(transform.multVec(p).eql(vector.initPoint(2, 3, 7)));
    }
}

test "individual transformations are applied in sequence" {
    const p = vector.initPoint(1, 0, 1);

    const a = Mat4.identity().rotateX(std.math.pi / 2.0);
    const b = Mat4.identity().scale(5, 5, 5);
    const c = Mat4.identity().translate(10, 5, 7);

    const p2 = a.multVec(p);
    const p3 = b.multVec(p2);
    const p4 = c.multVec(p3);

    try std.testing.expect(p4.eql(vector.initPoint(15, 0, 7)));
}

test "chained transformations must be applied in reverse order" {
    const p = vector.initPoint(1, 0, 1);

    {
        const a = Mat4.identity().rotateX(std.math.pi / 2.0);
        const b = Mat4.identity().scale(5, 5, 5);
        const c = Mat4.identity().translate(10, 5, 7);

        const t = c.mult(b).mult(a);
        try std.testing.expect(t.multVec(p).eql(vector.initPoint(15, 0, 7)));
    }

    {
        // fllent API
        const t = Mat4.identity()
            .rotateX(std.math.pi / 2.0)
            .scale(5, 5, 5)
            .translate(10, 5, 7);
        try std.testing.expect(t.multVec(p).eql(vector.initPoint(15, 0, 7)));
    }
}
