const std = @import("std");

fn epsilonEq(a: anytype, b: @TypeOf(a)) bool {
    return std.math.approxEqAbs(@TypeOf(a), a, b, std.math.epsilon(@TypeOf(a)));
}

const Tuple = struct {
    const Self = @This();

    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub fn init(x: f32, y: f32, z: f32, w: f32) Self {
        return .{
            .x = x,
            .y = y,
            .z = z,
            .w = w,
        };
    }

    pub fn initPoint(x: f32, y: f32, z: f32) Self {
        return init(x, y, z, 1.0);
    }

    pub fn initVector(x: f32, y: f32, z: f32) Self {
        return init(x, y, z, 0.0);
    }

    pub fn isPoint(self: Self) bool {
        return epsilonEq(self.w, 1.0);
    }

    pub fn isVector(self: Self) bool {
        return epsilonEq(self.w, 0.0);
    }

    pub fn eql(self: Self, other: Self) bool {
        return epsilonEq(self.x, other.x) and
            epsilonEq(self.y, other.y) and
            epsilonEq(self.z, other.z) and
            epsilonEq(self.w, other.w);
    }

    pub fn add(self: Self, other: Self) Self {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
            .w = self.w + other.w,
        };
    }

    pub fn sub(self: Self, other: Self) Self {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
            .w = self.w - other.w,
        };
    }

    pub fn negate(self: Self) Self {
        return .{
            .x = -self.x,
            .y = -self.y,
            .z = -self.z,
            .w = -self.w,
        };
    }

    pub fn scale(self: Self, scalar: f32) Self {
        return .{
            .x = scalar * self.x,
            .y = scalar * self.y,
            .z = scalar * self.z,
            .w = scalar * self.w,
        };
    }

    pub fn div(self: Self, scalar: f32) Self {
        return self.scale(1.0 / scalar);
    }

    pub fn length(self: Self) f32 {
        return std.math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w);
    }
};

test "point / vector" {
    const a = Tuple.init(4.3, -4.2, 3.1, 1.0);

    try std.testing.expect(a.isPoint() == true);
    try std.testing.expect(a.isVector() == false);

    const b = Tuple.init(4.3, -4.2, 3.1, 0.0);

    try std.testing.expect(b.isPoint() == false);
    try std.testing.expect(b.isVector() == true);
}

test "init" {
    const p = Tuple.initPoint(4, -4, 3);
    try std.testing.expect(epsilonEq(p.w, 1.0));

    const v = Tuple.initVector(4, -4, 3);
    try std.testing.expect(epsilonEq(v.w, 0.0));
}

test "equality" {
    const p = Tuple.initPoint(4, -4, 3);
    const v = Tuple.initVector(4, -4, 3);

    try std.testing.expect(p.eql(Tuple.initPoint(4, -4, 3)) == true);

    try std.testing.expect(p.eql(Tuple.initPoint(4, -4, 3.01)) == false);
    try std.testing.expect(p.eql(Tuple.initPoint(4, -4.01, 3)) == false);
    try std.testing.expect(p.eql(Tuple.initPoint(4.01, -4, 3)) == false);

    try std.testing.expect(p.eql(p) == true);
    try std.testing.expect(p.eql(v) == false);

    try std.testing.expect(v.eql(Tuple.initVector(4, -4, 3)) == true);
}

test "adding two tuples" {
    const a1 = Tuple.init(3, -2, 5, 1);
    const a2 = Tuple.init(-2, 3, 1, 0);

    const result = a1.add(a2);
    try std.testing.expect(result.eql(Tuple.init(1, 1, 6, 1)) == true);
}

test "subtracting a vector from a point" {
    const p = Tuple.initPoint(3, 2, 1);
    const v = Tuple.initVector(5, 6, 7);

    const result = p.sub(v);
    try std.testing.expect(result.eql(Tuple.initPoint(-2, -4, -6)));
}

test "subtracting two vectors" {
    const v1 = Tuple.initVector(3, 2, 1);
    const v2 = Tuple.initVector(5, 6, 7);

    const result = v1.sub(v2);
    try std.testing.expect(result.eql(Tuple.initVector(-2, -4, -6)));
}

test "subtracting a vector from the zeor vector" {
    const zero = Tuple.initVector(0, 0, 0);
    const v = Tuple.initVector(1, -2, 3);

    const result = zero.sub(v);
    try std.testing.expect(result.eql(Tuple.initVector(-1, 2, -3)));
}

test "negating a tuple" {
    const a = Tuple.init(1, -2, 3, -4);
    const result = a.negate();
    try std.testing.expect(result.eql(Tuple.init(-1, 2, -3, 4)));
}

test "multiplying a tuple by a scalar" {
    const a = Tuple.init(1, -2, 3, -4);
    const result = a.scale(0.5);
    try std.testing.expect(result.eql(Tuple.init(0.5, -1, 1.5, -2)));
}

test "dividing a tuple by a scalar" {
    const a = Tuple.init(1, -2, 3, -4);
    const result = a.div(2);
    try std.testing.expect(result.eql(Tuple.init(0.5, -1, 1.5, -2)));
}

test "length of vectors" {
    const v1 = Tuple.initVector(1, 0, 0);
    try std.testing.expect(epsilonEq(v1.length(), 1.0));

    const v2 = Tuple.initVector(0, 0, 1);
    try std.testing.expect(epsilonEq(v2.length(), 1.0));

    const v3 = Tuple.initVector(1, 2, 3);
    try std.testing.expect(epsilonEq(v3.length(), std.math.sqrt(14.0)));

    const v4 = Tuple.initVector(-1, -2, -3);
    try std.testing.expect(epsilonEq(v4.length(), std.math.sqrt(14.0)));
}
