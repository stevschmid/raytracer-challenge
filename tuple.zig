const std = @import("std");
const epsilonEq = @import("utils.zig").epsilonEq;

pub fn Vector(comptime Size: usize) type {
    return struct {
        const Self = @This();

        data: [Size]f32 = undefined,

        pub fn init(tuple: anytype) Self {
            var new = Self{};

            if (tuple.len != Size) @compileError("Incorrect number of inputs supplied");

            inline for (tuple) |val, idx| {
                new.data[idx] = val;
            }

            return new;
        }

        pub fn eql(self: Self, other: Self) bool {
            for (self.data) |_, idx| {
                if (!epsilonEq(self.data[idx], other.data[idx]))
                    return false;
            }

            return true;
        }

        pub fn add(self: Self, other: Self) Self {
            var new = Self{};

            for (new.data) |*val, idx| {
                val.* = self.data[idx] + other.data[idx];
            }

            return new;
        }

        pub fn sub(self: Self, other: Self) Self {
            var new = Self{};

            for (new.data) |*val, idx| {
                val.* = self.data[idx] - other.data[idx];
            }

            return new;
        }

        pub fn negate(self: Self) Self {
            return self.scale(-1.0);
        }

        pub fn scale(self: Self, scalar: f32) Self {
            var new = Self{};

            for (new.data) |*val, idx| {
                val.* = scalar * self.data[idx];
            }

            return new;
        }

        pub fn div(self: Self, scalar: f32) Self {
            var new = Self{};

            for (new.data) |*val, idx| {
                val.* = self.data[idx] / scalar;
            }

            return new;
        }

        pub fn length(self: Self) f32 {
            var sum: f32 = 0.0;

            for (self.data) |val| {
                sum += val * val;
            }

            return std.math.sqrt(sum);
        }

        pub fn normalize(self: Self) Self {
            const len = self.length();

            var new = Self{};

            for (new.data) |*val, idx| {
                val.* = self.data[idx] / len;
            }

            return new;
        }

        pub fn dot(self: Self, other: Self) f32 {
            var res: f32 = 0.0;

            for (self.data) |_, idx| {
                res += self.data[idx] * other.data[idx];
            }

            return res;
        }

        pub fn cross(self: Self, other: Self) Vector(3) {
            if (Size < 3) @compileError("Expected dimension of vector >= 3");

            var res = Vector(3){};

            const a = self.data;
            const b = other.data;

            res.data[0] = a[1] * b[2] - a[2] * b[1];
            res.data[1] = a[2] * b[0] - a[0] * b[2];
            res.data[2] = a[0] * b[1] - a[1] * b[0];

            return res;
        }
    };
}

pub const Vec2 = Vector(2);
pub const Vec3 = Vector(3);
pub const Vec4 = Vector(4);

// test "point / vector" {
//     const a = Tuple.init(4.3, -4.2, 3.1, 1.0);

//     try std.testing.expect(a.isPoint() == true);
//     try std.testing.expect(a.isVector() == false);

//     const b = Tuple.init(4.3, -4.2, 3.1, 0.0);

//     try std.testing.expect(b.isPoint() == false);
//     try std.testing.expect(b.isVector() == true);
// }

test "equality" {
    const p = Vec4.init(.{ 4, -4, 3, 1 });
    const v = Vec4.init(.{ 4, -4, 3, 0 });

    try std.testing.expect(p.eql(Vec4.init(.{ 4, -4, 3, 1 })) == true);

    try std.testing.expect(p.eql(Vec4.init(.{ 4, -4, 3.01, 1 })) == false);
    try std.testing.expect(p.eql(Vec4.init(.{ 4, -4.01, 3, 1 })) == false);
    try std.testing.expect(p.eql(Vec4.init(.{ 4.01, -4, 3, 1 })) == false);

    try std.testing.expect(p.eql(p) == true);
    try std.testing.expect(p.eql(v) == false);

    try std.testing.expect(v.eql(Vec4.init(.{ 4, -4, 3, 0 })) == true);
}

test "adding two tuples" {
    const a1 = Vec4.init(.{ 3, -2, 5, 1 });
    const a2 = Vec4.init(.{ -2, 3, 1, 0 });

    const result = a1.add(a2);
    try std.testing.expect(result.eql(Vec4.init(.{ 1, 1, 6, 1 })) == true);
}

test "subtracting a vector from a point" {
    const p = Vec4.init(.{ 3, 2, 1, 1 });
    const v = Vec4.init(.{ 5, 6, 7, 0 });

    const result = p.sub(v);
    try std.testing.expect(result.eql(Vec4.init(.{ -2, -4, -6, 1 })));
}

test "subtracting two vectors" {
    const v1 = Vec3.init(.{ 3, 2, 1 });
    const v2 = Vec3.init(.{ 5, 6, 7 });

    const result = v1.sub(v2);
    try std.testing.expect(result.eql(Vec3.init(.{ -2, -4, -6 })));
}

test "subtracting a vector from the zero vector" {
    const zero = Vec3.init(.{ 0, 0, 0 });
    const v = Vec3.init(.{ 1, -2, 3 });

    const result = zero.sub(v);
    try std.testing.expect(result.eql(Vec3.init(.{ -1, 2, -3 })));
}

test "negating a tuple" {
    const a = Vec4.init(.{ 1, -2, 3, -4 });
    const result = a.negate();
    try std.testing.expect(result.eql(Vec4.init(.{ -1, 2, -3, 4 })));
}

test "multiplying a tuple by a scalar" {
    const a = Vec4.init(.{ 1, -2, 3, -4 });
    const result = a.scale(0.5);
    try std.testing.expect(result.eql(Vec4.init(.{ 0.5, -1, 1.5, -2 })));
}

test "dividing a tuple by a scalar" {
    const a = Vec4.init(.{ 1, -2, 3, -4 });
    const result = a.div(2);
    try std.testing.expect(result.eql(Vec4.init(.{ 0.5, -1, 1.5, -2 })));
}

test "length of vectors" {
    const v1 = Vec3.init(.{ 1, 0, 0 });
    try std.testing.expect(epsilonEq(v1.length(), 1.0));

    const v2 = Vec3.init(.{ 0, 0, 1 });
    try std.testing.expect(epsilonEq(v2.length(), 1.0));

    const v3 = Vec3.init(.{ 1, 2, 3 });
    try std.testing.expect(epsilonEq(v3.length(), std.math.sqrt(14.0)));

    const v4 = Vec3.init(.{ -1, -2, -3 });
    try std.testing.expect(epsilonEq(v4.length(), std.math.sqrt(14.0)));
}

test "normalize" {
    const v1 = Vec3.init(.{ 4, 0, 0 });
    try std.testing.expect(v1.normalize().eql(Vec3.init(.{ 1, 0, 0 })));

    const v2 = Vec3.init(.{ 1, 2, 3 });
    const len = std.math.sqrt(14.0);
    try std.testing.expect(v2.normalize().eql(Vec3.init(.{ 1.0 / len, 2.0 / len, 3.0 / len })));
    try std.testing.expect(epsilonEq(v2.normalize().length(), 1.0));
}

test "dot product" {
    const a = Vec3.init(.{ 1, 2, 3 });
    const b = Vec3.init(.{ 2, 3, 4 });

    try std.testing.expect(epsilonEq(a.dot(b), 20.0));
}

test "cross product" {
    const a = Vec3.init(.{ 1, 2, 3 });
    const b = Vec3.init(.{ 2, 3, 4 });

    try std.testing.expect(a.cross(b).eql(Vec3.init(.{ -1, 2, -1 })));
    try std.testing.expect(b.cross(a).eql(Vec3.init(.{ 1, -2, 1 })));
}
