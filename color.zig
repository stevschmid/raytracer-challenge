const std = @import("std");

fn epsilonEq(a: anytype, b: @TypeOf(a)) bool {
    return std.math.approxEqAbs(@TypeOf(a), a, b, std.math.epsilon(@TypeOf(a)));
}

pub const Color = struct {
    const Self = @This();

    red: f32,
    green: f32,
    blue: f32,

    pub fn init(red: f32, green: f32, blue: f32) Self {
        return .{
            .red = red,
            .green = green,
            .blue = blue,
        };
    }

    pub fn eql(self: Self, other: Self) bool {
        return epsilonEq(self.red, other.red) and
            epsilonEq(self.green, other.green) and
            epsilonEq(self.blue, other.blue);
    }

    pub fn add(self: Self, other: Self) Self {
        return .{
            .red = self.red + other.red,
            .green = self.green + other.green,
            .blue = self.blue + other.blue,
        };
    }

    pub fn sub(self: Self, other: Self) Self {
        return .{
            .red = self.red - other.red,
            .green = self.green - other.green,
            .blue = self.blue - other.blue,
        };
    }

    pub fn scale(self: Self, scalar: f32) Self {
        return .{
            .r = scalar * self.red,
            .g = scalar * self.green,
            .b = scalar * self.blue,
        };
    }

    pub fn mult(self: Self, other: Self) Self {
        return .{
            .red = self.red * other.red,
            .green = self.green * other.green,
            .blue = self.blue * other.blue,
        };
    }
};

test "adding colors" {
    const c1 = Color.init(0.9, 0.6, 0.75);
    const c2 = Color.init(0.7, 0.1, 0.25);

    try std.testing.expect(c1.add(c2).eql(Color.init(1.6, 0.7, 1.0)));
}

test "subtracting colors" {
    const c1 = Color.init(0.9, 0.6, 0.75);
    const c2 = Color.init(0.7, 0.1, 0.25);

    try std.testing.expect(c1.sub(c2).eql(Color.init(0.2, 0.5, 0.5)));
}

test "multiplying colors" {
    const c1 = Color.init(1, 0.2, 0.4);
    const c2 = Color.init(0.9, 1, 0.1);

    try std.testing.expect(c1.mult(c2).eql(Color.init(0.9, 0.2, 0.04)));
}
