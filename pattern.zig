const std = @import("std");

const utils = @import("utils.zig");

const vector = @import("vector.zig");
const Vec4 = vector.Vec4;
const initPoint = vector.initPoint;
const initVector = vector.initVector;

const Mat4 = @import("matrix.zig").Mat4;

const Color = @import("color.zig").Color;
const Shape = @import("shape.zig").Shape;

const Stripe = struct {
    const Self = @This();

    a: Color,
    b: Color,

    pub fn patternAt(self: Self, point: Vec4) Color {
        return if (@mod(@floor(point.x), 2.0) == 0.0) self.a else self.b;
    }
};

pub const Pattern = struct {
    const Self = @This();

    pattern: union(enum) {
        point: void,
        stripe: Stripe,
    } = .{ .point = {} },

    transform: Mat4 = Mat4.identity(),

    pub fn patternAt(self: Self, object: Shape, world_point: Vec4) Color {
        const object_space = object.transform.inverse();
        const pattern_space = self.transform.inverse();

        const object_point = object_space.multVec(world_point);
        const pattern_point = pattern_space.multVec(object_point);

        return switch (self.pattern) {
            .point => Color.init(pattern_point.x, pattern_point.y, pattern_point.z),
            .stripe => |p| p.patternAt(pattern_point),
        };
    }
};

test "The default pattern transformation" {
    const p = Pattern{};
    try std.testing.expect(p.transform.eql(Mat4.identity()));
}

test "Changing a shape's transformation" {
    const p = Pattern{ .transform = Mat4.identity().translate(1, 2, 3) };
    try std.testing.expect(p.transform.eql(Mat4.identity().translate(1, 2, 3)));
}

test "A pattern with an object and pattern transformation" {
    const p = Pattern{ .transform = Mat4.identity().translate(0.5, 1, 1.5) };
    const s = Shape{
        .geo = .{ .sphere = .{} },
        .transform = Mat4.identity().scale(2, 2, 2),
    };

    try utils.expectColorApproxEq(Color.init(0.75, 0.5, 0.25), p.patternAt(s, initPoint(2.5, 3, 3.5)));
}

test "Stripe pattern is constant in y" {
    const p = Stripe{ .a = Color.White, .b = Color.Black };
    try utils.expectColorApproxEq(Color.White, p.patternAt(initPoint(0, 0, 0)));
    try utils.expectColorApproxEq(Color.White, p.patternAt(initPoint(0, 1, 0)));
    try utils.expectColorApproxEq(Color.White, p.patternAt(initPoint(0, 2, 0)));
}

test "Stripe pattern is constant in z" {
    const p = Stripe{ .a = Color.White, .b = Color.Black };
    try utils.expectColorApproxEq(Color.White, p.patternAt(initPoint(0, 0, 0)));
    try utils.expectColorApproxEq(Color.White, p.patternAt(initPoint(0, 0, 1)));
    try utils.expectColorApproxEq(Color.White, p.patternAt(initPoint(0, 0, 2)));
}

test "Stripe pattern alternates in x" {
    const p = Stripe{ .a = Color.White, .b = Color.Black };
    try utils.expectColorApproxEq(Color.White, p.patternAt(initPoint(0, 0, 0)));
    try utils.expectColorApproxEq(Color.White, p.patternAt(initPoint(0.9, 0, 0)));
    try utils.expectColorApproxEq(Color.Black, p.patternAt(initPoint(1, 0, 0)));
    try utils.expectColorApproxEq(Color.Black, p.patternAt(initPoint(-0.1, 0, 0)));
    try utils.expectColorApproxEq(Color.Black, p.patternAt(initPoint(-1, 0, 0)));
    try utils.expectColorApproxEq(Color.White, p.patternAt(initPoint(-1.1, 0, 0)));
}

test "Stripes with both an object and a pattern transformation" {
    const p = Pattern{
        .pattern = .{ .stripe = .{ .a = Color.White, .b = Color.Black } },
        .transform = Mat4.identity().translate(0.5, 0, 0),
    };
    const s = Shape{
        .geo = .{ .sphere = .{} },
        .transform = Mat4.identity().scale(2, 2, 2),
    };

    try utils.expectColorApproxEq(Color.White, p.patternAt(s, initPoint(2.5, 0, 0)));
}
