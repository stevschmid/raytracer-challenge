const std = @import("std");

fn epsilon_eq(a: anytype, b: @TypeOf(a)) bool {
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
        return epsilon_eq(self.w, 1.0);
    }

    fn isVector(self: Self) bool {
        return epsilon_eq(self.w, 0.0);
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
    try std.testing.expect(epsilon_eq(p.w, 1.0));

    const v = Tuple.initVector(4, -4, 3);
    try std.testing.expect(epsilon_eq(v.w, 0.0));
}
