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

    fn initPoint(x: f32, y: f32, z: f32) Self {
        return .{
            .x = x,
            .y = y,
            .z = z,
            .w = 1.0,
        };
    }

    fn initVector(x: f32, y: f32, z: f32) Self {
        return .{
            .x = x,
            .y = y,
            .z = z,
            .w = 0.0,
        };
    }

    fn isPoint(self: Self) bool {
        return epsilonEq(self.w, 1.0);
    }

    fn isVector(self: Self) bool {
        return epsilonEq(self.w, 0.0);
    }

    fn eql(self: Self, other: Self) bool {
        return epsilonEq(self.x, other.x) and
            epsilonEq(self.y, other.y) and
            epsilonEq(self.z, other.z) and
            epsilonEq(self.w, other.w);
    }
};

test "point / vector" {
    const a = Tuple{
        .x = 4.3,
        .y = -4.2,
        .z = 3.1,
        .w = 1.0,
    };

    try std.testing.expect(a.isPoint() == true);
    try std.testing.expect(a.isVector() == false);

    const b = Tuple{
        .x = 4.3,
        .y = -4.2,
        .z = 3.1,
        .w = 0.0,
    };

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
