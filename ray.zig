const std = @import("std");

const utils = @import("utils.zig");

const vector = @import("vector.zig");
const Vec4 = vector.Vec4;

const initPoint = vector.initPoint;
const initVector = vector.initVector;

const Sphere = struct {};

const Ray = struct {
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
};

const Intersection = struct {
    t: f32,
    object: Sphere,
};

const Intersections = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    list: std.ArrayList(Intersection),

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .list = std.ArrayList(Intersection).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.list.deinit();
    }
};

fn intersect(allocator: std.mem.Allocator, sphere: Sphere, ray: Ray) !Intersections {
    _ = sphere;

    var res = Intersections.init(allocator);
    errdefer res.deinit();

    const sphere_to_ray = ray.origin.sub(initPoint(0, 0, 0));

    const a = ray.direction.dot(ray.direction);
    const b = 2.0 * ray.direction.dot(sphere_to_ray);
    const c = sphere_to_ray.dot(sphere_to_ray) - 1.0;

    const discriminant = b * b - 4 * a * c;

    if (discriminant < 0) // ray misses
        return res;

    const t1 = (-b - std.math.sqrt(discriminant)) / (2 * a);
    const t2 = (-b + std.math.sqrt(discriminant)) / (2 * a);

    try res.list.append(.{ .t = t1, .object = sphere });
    try res.list.append(.{ .t = t2, .object = sphere });

    return res;
}

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

const alloc = std.testing.allocator;

test "a ray intersects sphere at two points" {
    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));
    const s = Sphere{};

    var xs = try intersect(alloc, s, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 2), xs.list.items.len);

    try utils.expectEpsilonEq(@as(f32, 4.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f32, 6.0), xs.list.items[1].t);

    try std.testing.expect(std.meta.eql(s, xs.list.items[0].object));
    try std.testing.expect(std.meta.eql(s, xs.list.items[1].object));
}

test "a ray intersects a sphere at a tangent" {
    const r = Ray.init(initPoint(0, 1, -5), initVector(0, 0, 1));
    const s = Sphere{};

    var xs = try intersect(alloc, s, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 2), xs.list.items.len);

    try utils.expectEpsilonEq(@as(f32, 5.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f32, 5.0), xs.list.items[1].t);

    try std.testing.expect(std.meta.eql(s, xs.list.items[0].object));
    try std.testing.expect(std.meta.eql(s, xs.list.items[1].object));
}

test "a ray misses a sphere" {
    const r = Ray.init(initPoint(0, 2, -5), initVector(0, 0, 1));
    const s = Sphere{};

    var xs = try intersect(alloc, s, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 0), xs.list.items.len);
}

test "a ray originates inside a sphere" {
    const r = Ray.init(initPoint(0, 0, 0), initVector(0, 0, 1));
    const s = Sphere{};

    var xs = try intersect(alloc, s, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 2), xs.list.items.len);

    try utils.expectEpsilonEq(@as(f32, -1.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f32, 1.0), xs.list.items[1].t);

    try std.testing.expect(std.meta.eql(s, xs.list.items[0].object));
    try std.testing.expect(std.meta.eql(s, xs.list.items[1].object));
}

test "a sphere is behind a ray" {
    const r = Ray.init(initPoint(0, 0, 5), initVector(0, 0, 1));
    const s = Sphere{};

    var xs = try intersect(alloc, s, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 2), xs.list.items.len);

    try utils.expectEpsilonEq(@as(f32, -6.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f32, -4.0), xs.list.items[1].t);

    try std.testing.expect(std.meta.eql(s, xs.list.items[0].object));
    try std.testing.expect(std.meta.eql(s, xs.list.items[1].object));
}