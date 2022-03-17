const std = @import("std");

const utils = @import("utils.zig");

const vector = @import("vector.zig");
const Vec4 = vector.Vec4;

const Mat4 = @import("matrix.zig").Mat4;
const Shape = @import("shape.zig").Shape;

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

    pub fn position(self: Self, t: f64) Vec4 {
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

pub const Intersection = struct {
    t: f64,
    object: Shape,
};

pub const Intersections = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    list: std.ArrayList(Intersection),

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .list = std.ArrayList(Intersection).init(allocator),
        };
    }

    pub fn hit(self: Self) ?Intersection {
        std.sort.sort(Intersection, self.list.items, {}, lessThanIntersection);

        const first_hit = for (self.list.items) |intersection| {
            if (intersection.t >= 0) break intersection;
        } else null;

        return first_hit;
    }

    pub fn deinit(self: *Self) void {
        self.list.deinit();
    }

    pub fn lessThanIntersection(context: void, a: Intersection, b: Intersection) bool {
        _ = context;
        return a.t < b.t;
    }
};

const alloc = std.testing.allocator;

test "The hit, when all intersections have positive t" {
    const s = Shape{ .geo = .{ .sphere = .{} } };

    var xs = Intersections.init(alloc);
    defer xs.deinit();

    const is1 = Intersection{ .t = 1, .object = s };
    try xs.list.append(is1);

    const is2 = Intersection{ .t = 2, .object = s };
    try xs.list.append(is2);

    try std.testing.expectEqual(is1, xs.hit().?);
}

test "The hit, when some intersections have negative t" {
    const s = Shape{ .geo = .{ .sphere = .{} } };

    var xs = Intersections.init(alloc);
    defer xs.deinit();

    const is1 = Intersection{ .t = -1, .object = s };
    try xs.list.append(is1);

    const is2 = Intersection{ .t = 1, .object = s };
    try xs.list.append(is2);

    try std.testing.expectEqual(is2, xs.hit().?);
}

test "The hit, when all intersections have negative t" {
    const s = Shape{ .geo = .{ .sphere = .{} } };

    var xs = Intersections.init(alloc);
    defer xs.deinit();

    const is1 = Intersection{ .t = -2, .object = s };
    try xs.list.append(is1);

    const is2 = Intersection{ .t = -1, .object = s };
    try xs.list.append(is2);

    try std.testing.expect(xs.hit() == null);
}

test "The hit is always the lowest nonnegative intersection" {
    const s = Shape{ .geo = .{ .sphere = .{} } };

    var xs = Intersections.init(alloc);
    defer xs.deinit();

    const is1 = Intersection{ .t = 5, .object = s };
    try xs.list.append(is1);

    const is2 = Intersection{ .t = 7, .object = s };
    try xs.list.append(is2);

    const is3 = Intersection{ .t = -3, .object = s };
    try xs.list.append(is3);

    const is4 = Intersection{ .t = 2, .object = s };
    try xs.list.append(is4);

    try std.testing.expectEqual(is4, xs.hit().?);
}

test "Translating a ray" {
    const r = Ray.init(initPoint(1, 2, 3), initVector(0, 1, 0));
    const m = Mat4.identity().translate(3, 4, 5);

    const r2 = r.transform(m);

    try std.testing.expect(r2.origin.eql(initPoint(4, 6, 8)));
    try std.testing.expect(r2.direction.eql(initVector(0, 1, 0)));
}

test "Scaling a ray" {
    const r = Ray.init(initPoint(1, 2, 3), initVector(0, 1, 0));
    const m = Mat4.identity().scale(2, 3, 4);

    const r2 = r.transform(m);

    try std.testing.expect(r2.origin.eql(initPoint(2, 6, 12)));
    try std.testing.expect(r2.direction.eql(initVector(0, 3, 0)));
}
