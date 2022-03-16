const std = @import("std");

const utils = @import("utils.zig");

const vector = @import("vector.zig");
const Vec4 = vector.Vec4;

const Mat4 = @import("matrix.zig").Mat4;
const Material = @import("material.zig").Material;

const Ray = @import("ray.zig").Ray;
const Intersections = @import("ray.zig").Intersections;

const initPoint = vector.initPoint;
const initVector = vector.initVector;

const Sphere = struct {
    const Self = @This();

    transform: Mat4 = Mat4.identity(),
    material: Material = .{},

    pub fn localNormalAt(self: Self, point: Vec4) Vec4 {
        _ = self;
        return point.sub(initPoint(0, 0, 0)).normalize();
    }

    pub fn localIntersect(self: Self, allocator: std.mem.Allocator, ray: Ray) !Intersections {
        var res = Intersections.init(allocator);
        errdefer res.deinit();

        const shape_to_ray = ray.origin.sub(initPoint(0, 0, 0));

        const a = ray.direction.dot(ray.direction);
        const b = 2.0 * ray.direction.dot(shape_to_ray);
        const c = shape_to_ray.dot(shape_to_ray) - 1.0;

        const discriminant = b * b - 4 * a * c;

        if (discriminant < 0) // ray misses
            return res;

        const t1 = (-b - std.math.sqrt(discriminant)) / (2 * a);
        const t2 = (-b + std.math.sqrt(discriminant)) / (2 * a);

        try res.list.append(.{ .t = t1, .object = .{ .sphere = self } });
        try res.list.append(.{ .t = t2, .object = .{ .sphere = self } });

        return res;
    }
};

pub const Shape = union(enum) {
    const Self = @This();

    sphere: Sphere,

    pub fn material(self: Self) Material {
        return switch (self) {
            .sphere => |s| s.material,
        };
    }

    pub fn normalAt(self: Self, world_point: Vec4) Vec4 {
        const object_space = self.inverseTransform();

        const local_point = object_space.multVec(world_point);
        const local_normal = switch (self) {
            .sphere => |s| s.localNormalAt(local_point),
        };

        var world_normal = object_space.transpose().multVec(local_normal);
        world_normal.w = 0; // or use 3x3 submatrix without translation above

        return world_normal.normalize();
    }

    pub fn intersect(self: Self, allocator: std.mem.Allocator, world_ray: Ray) !Intersections {
        var object_space = self.inverseTransform();
        var local_ray = world_ray.transform(object_space);

        return switch (self) {
            .sphere => |s| try s.localIntersect(allocator, local_ray),
        };
    }

    fn inverseTransform(self: Self) Mat4 {
        const transform = switch (self) {
            .sphere => |s| s.transform,
        };

        return transform.inverse();
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

test "The normal on a sphere at a point on the x axis" {
    const s = Shape{ .sphere = .{} };
    const n = s.normalAt(initPoint(1, 0, 0));
    try std.testing.expect(n.eql(initVector(1, 0, 0)));
}

test "The normal on a sphere at a point on the y axis" {
    const s = Shape{ .sphere = .{} };
    const n = s.normalAt(initPoint(0, 1, 0));
    try std.testing.expect(n.eql(initVector(0, 1, 0)));
}

test "The normal on a sphere at a point on the z axis" {
    const s = Shape{ .sphere = .{} };
    const n = s.normalAt(initPoint(0, 0, 1));
    try std.testing.expect(n.eql(initVector(0, 0, 1)));
}

test "The normal on a sphere at a point at a nonaxial point" {
    const s = Shape{ .sphere = .{} };
    const k = std.math.sqrt(3.0) / 3.0;
    const n = s.normalAt(initPoint(k, k, k));

    try std.testing.expect(n.eql(initVector(k, k, k)));
    try std.testing.expect(n.eql(n.normalize()));
}

const alloc = std.testing.allocator;

test "Computing the normal on a translated sphere" {
    const s = Shape{
        .sphere = .{
            .transform = Mat4.identity().translate(0, 1, 0),
        },
    };

    const n = s.normalAt(initPoint(0, 1.70711, -0.70711));
    try utils.expectVec4ApproxEq(n, initVector(0, 0.70711, -0.70711));
}

test "Computing the normal on a transformed sphere" {
    const s = Shape{
        .sphere = .{
            .transform = Mat4.identity()
                .rotateZ(std.math.pi / 5.0)
                .scale(1, 0.5, 1),
        },
    };

    const n = s.normalAt(initPoint(0, std.math.sqrt(2.0) / 2.0, -std.math.sqrt(2.0) / 2.0));
    try utils.expectVec4ApproxEq(n, initVector(0, 0.97014, -0.24254));
}

test "a ray intersects shape at two points" {
    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));
    const s = Shape{ .sphere = .{} };

    var xs = try s.intersect(alloc, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 2), xs.list.items.len);

    try utils.expectEpsilonEq(@as(f64, 4.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f64, 6.0), xs.list.items[1].t);

    try std.testing.expectEqual(s, xs.list.items[0].object);
    try std.testing.expectEqual(s, xs.list.items[1].object);
}

test "a ray intersects a shape at a tangent" {
    const r = Ray.init(initPoint(0, 1, -5), initVector(0, 0, 1));
    const s = Shape{ .sphere = .{} };

    var xs = try s.intersect(alloc, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 2), xs.list.items.len);

    try utils.expectEpsilonEq(@as(f64, 5.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f64, 5.0), xs.list.items[1].t);

    try std.testing.expectEqual(s, xs.list.items[0].object);
    try std.testing.expectEqual(s, xs.list.items[1].object);
}

test "a ray misses a shape" {
    const r = Ray.init(initPoint(0, 2, -5), initVector(0, 0, 1));
    const s = Shape{ .sphere = .{} };

    var xs = try s.intersect(alloc, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 0), xs.list.items.len);
}

test "a ray originates inside a shape" {
    const r = Ray.init(initPoint(0, 0, 0), initVector(0, 0, 1));
    const s = Shape{ .sphere = .{} };

    var xs = try s.intersect(alloc, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 2), xs.list.items.len);

    try utils.expectEpsilonEq(@as(f64, -1.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f64, 1.0), xs.list.items[1].t);

    try std.testing.expectEqual(s, xs.list.items[0].object);
    try std.testing.expectEqual(s, xs.list.items[1].object);
}

test "a shape is behind a ray" {
    const r = Ray.init(initPoint(0, 0, 5), initVector(0, 0, 1));
    const s = Shape{ .sphere = .{} };

    var xs = try s.intersect(alloc, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 2), xs.list.items.len);

    try utils.expectEpsilonEq(@as(f64, -6.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f64, -4.0), xs.list.items[1].t);

    try std.testing.expectEqual(s, xs.list.items[0].object);
    try std.testing.expectEqual(s, xs.list.items[1].object);
}

test "Intersecting a scaled shape with a ray" {
    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));
    const s = Shape{ .sphere = .{ .transform = Mat4.identity().scale(2, 2, 2) } };

    var xs = try s.intersect(alloc, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 2), xs.list.items.len);

    try utils.expectEpsilonEq(@as(f64, 3.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f64, 7.0), xs.list.items[1].t);
}

test "Intersecting a translated shape with a ray" {
    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));
    const s = Shape{ .sphere = .{ .transform = Mat4.identity().translate(5, 0, 0) } };

    var xs = try s.intersect(alloc, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 0), xs.list.items.len);
}
