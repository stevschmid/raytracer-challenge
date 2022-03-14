const std = @import("std");

const utils = @import("utils.zig");

const vector = @import("vector.zig");
const Vec4 = vector.Vec4;

const Mat4 = @import("matrix.zig").Mat4;
const Sphere = @import("sphere.zig").Sphere;

const initPoint = vector.initPoint;
const initVector = vector.initVector;

pub const Ray = struct {
    const Self = @This();

    origin: Vec4,
    direction: Vec4,

    pub fn init(origin: Vec4, direction: Vec4) Self {
        return Self{
            .origin = origin,
            .direction = direction,
        };
    }

    pub fn position(self: Self, t: f32) Vec4 {
        return self.origin.add(self.direction.scale(t));
    }

    pub fn transform(self: Self, mat: Mat4) Self {
        return Self{
            .origin = mat.multVec(self.origin),
            .direction = mat.multVec(self.direction),
        };
    }
};

test "creating and querying a ray" {
    const origin = initPoint(1, 2, 3);
    const direction = initVector(4, 5, 6);

    const r = Ray.init(origin, direction);
    try std.testing.expect(r.origin.eql(origin));
    try std.testing.expect(r.direction.eql(direction));
}

test "computing a point from a distance" {
    const r = Ray.init(initPoint(2, 3, 4), initVector(1, 0, 0));

    try std.testing.expect(r.position(0).eql(initPoint(2, 3, 4)));
    try std.testing.expect(r.position(1).eql(initPoint(3, 3, 4)));
    try std.testing.expect(r.position(-1).eql(initPoint(1, 3, 4)));
    try std.testing.expect(r.position(2.5).eql(initPoint(4.5, 3, 4)));
}
