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

    pub fn normalAt(self: Self, world_point: Vec4) Vec4 {
        const object_space = self.transform.inverse();
        const object_point = object_space.multVec(world_point);

        const object_normal = object_point.sub(initPoint(0, 0, 0)).normalize();

        var world_normal = object_space.transpose().multVec(object_normal);
        world_normal.w = 0; // or use 3x3 submatrix without translation above

        return world_normal.normalize();
    }
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

test "The normal on a sphere at a point on the x axis" {
    const s = Sphere{};
    const n = s.normalAt(initPoint(1, 0, 0));
    try std.testing.expect(n.eql(initVector(1, 0, 0)));
}

test "The normal on a sphere at a point on the y axis" {
    const s = Sphere{};
    const n = s.normalAt(initPoint(0, 1, 0));
    try std.testing.expect(n.eql(initVector(0, 1, 0)));
}

test "The normal on a sphere at a point on the z axis" {
    const s = Sphere{};
    const n = s.normalAt(initPoint(0, 0, 1));
    try std.testing.expect(n.eql(initVector(0, 0, 1)));
}

test "The normal on a sphere at a point at a nonaxial point" {
    const s = Sphere{};
    const k = std.math.sqrt(3.0) / 3.0;
    const n = s.normalAt(initPoint(k, k, k));
    try std.testing.expect(n.eql(initVector(k, k, k)));
    try std.testing.expect(n.eql(n.normalize()));
}

test "Computing the normal on a translated sphere" {
    const s = Sphere{
        .transform = Mat4.identity().translate(0, 1, 0),
    };

    const n = s.normalAt(initPoint(0, 1.70711, -0.70711));
    try utils.expectVec4ApproxEq(n, initVector(0, 0.70711, -0.70711));
}

test "Computing the normal on a translated sphere" {
    const s = Sphere{
        .transform = Mat4.identity()
            .rotateZ(std.math.pi / 5.0)
            .scale(1, 0.5, 1),
    };

    const n = s.normalAt(initPoint(0, std.math.sqrt(2.0) / 2.0, -std.math.sqrt(2.0) / 2.0));
    try utils.expectVec4ApproxEq(n, initVector(0, 0.97014, -0.24254));
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
