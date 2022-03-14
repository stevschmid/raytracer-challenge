const std = @import("std");

const utils = @import("utils.zig");

const vector = @import("vector.zig");
const Vec4 = vector.Vec4;

const Mat4 = @import("matrix.zig").Mat4;
const Material = @import("material.zig").Material;

const initPoint = vector.initPoint;
const initVector = vector.initVector;

pub const Sphere = struct {
    const Self = @This();

    transform: Mat4 = Mat4.identity(),
    material: Material = .{},
};

test "A sphere's default transformation" {
    const s = Sphere{};
    try std.testing.expect(s.transform.eql(Mat4.identity()));
}

test "Changing a sphere's transformation" {
    var s = Sphere{};
    s.transform = Mat4.identity().translate(2, 3, 4);
    try std.testing.expect(s.transform.eql(Mat4.identity().translate(2, 3, 4)));
}

test "A sphere has a default material" {
    const s = Sphere{};
    try std.testing.expectEqual(Material{}, s.material);
}

test "A sphere may be assigned a material" {
    const m = Material{
        .ambient = 1.0,
    };
    const s = Sphere{ .material = m };
    try std.testing.expectEqual(m, s.material);
}
