const std = @import("std");
const utils = @import("utils.zig");

const Vec4 = @import("vector.zig").Vec4;
const Mat4 = @import("matrix.zig").Mat4;
const Color = @import("color.zig").Color;

const initVector = @import("vector.zig").initVector;
const initPoint = @import("vector.zig").initPoint;

const World = @import("world.zig").World;
const Sphere = @import("sphere.zig").Sphere;
const Ray = @import("ray.zig").Ray;
const Material = @import("material.zig").Material;
const PointLight = @import("light.zig").PointLight;

pub const Intersection = struct {
    t: f32,
    object: Sphere,
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

    fn lessThanIntersection(context: void, a: Intersection, b: Intersection) bool {
        _ = context;
        return a.t < b.t;
    }
};

pub fn intersectSphere(allocator: std.mem.Allocator, sphere: Sphere, world_ray: Ray) !Intersections {
    var object_space = sphere.transform.inverse();

    var ray = world_ray.transform(object_space);
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

const alloc = std.testing.allocator;

test "a ray intersects sphere at two points" {
    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));
    const s = Sphere{};

    var xs = try intersectSphere(alloc, s, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 2), xs.list.items.len);

    try utils.expectEpsilonEq(@as(f32, 4.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f32, 6.0), xs.list.items[1].t);

    try std.testing.expectEqual(s, xs.list.items[0].object);
    try std.testing.expectEqual(s, xs.list.items[1].object);
}

test "a ray intersects a sphere at a tangent" {
    const r = Ray.init(initPoint(0, 1, -5), initVector(0, 0, 1));
    const s = Sphere{};

    var xs = try intersectSphere(alloc, s, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 2), xs.list.items.len);

    try utils.expectEpsilonEq(@as(f32, 5.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f32, 5.0), xs.list.items[1].t);

    try std.testing.expectEqual(s, xs.list.items[0].object);
    try std.testing.expectEqual(s, xs.list.items[1].object);
}

test "a ray misses a sphere" {
    const r = Ray.init(initPoint(0, 2, -5), initVector(0, 0, 1));
    const s = Sphere{};

    var xs = try intersectSphere(alloc, s, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 0), xs.list.items.len);
}

test "a ray originates inside a sphere" {
    const r = Ray.init(initPoint(0, 0, 0), initVector(0, 0, 1));
    const s = Sphere{};

    var xs = try intersectSphere(alloc, s, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 2), xs.list.items.len);

    try utils.expectEpsilonEq(@as(f32, -1.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f32, 1.0), xs.list.items[1].t);

    try std.testing.expectEqual(s, xs.list.items[0].object);
    try std.testing.expectEqual(s, xs.list.items[1].object);
}

test "a sphere is behind a ray" {
    const r = Ray.init(initPoint(0, 0, 5), initVector(0, 0, 1));
    const s = Sphere{};

    var xs = try intersectSphere(alloc, s, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 2), xs.list.items.len);

    try utils.expectEpsilonEq(@as(f32, -6.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f32, -4.0), xs.list.items[1].t);

    try std.testing.expectEqual(s, xs.list.items[0].object);
    try std.testing.expectEqual(s, xs.list.items[1].object);
}

test "The hit, when all intersections have positive t" {
    const s = Sphere{};

    var xs = Intersections.init(alloc);
    defer xs.deinit();

    const is1 = Intersection{ .t = 1, .object = s };
    try xs.list.append(is1);

    const is2 = Intersection{ .t = 2, .object = s };
    try xs.list.append(is2);

    try std.testing.expectEqual(is1, xs.hit().?);
}

test "The hit, when some intersections have negative t" {
    const s = Sphere{};

    var xs = Intersections.init(alloc);
    defer xs.deinit();

    const is1 = Intersection{ .t = -1, .object = s };
    try xs.list.append(is1);

    const is2 = Intersection{ .t = 1, .object = s };
    try xs.list.append(is2);

    try std.testing.expectEqual(is2, xs.hit().?);
}

test "The hit, when all intersections have negative t" {
    const s = Sphere{};

    var xs = Intersections.init(alloc);
    defer xs.deinit();

    const is1 = Intersection{ .t = -2, .object = s };
    try xs.list.append(is1);

    const is2 = Intersection{ .t = -1, .object = s };
    try xs.list.append(is2);

    try std.testing.expect(xs.hit() == null);
}

test "The hit is always the lowest nonnegative intersection" {
    const s = Sphere{};

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

test "Intersecting a scaled sphere with a ray" {
    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));
    const s = Sphere{ .transform = Mat4.identity().scale(2, 2, 2) };

    var xs = try intersectSphere(alloc, s, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 2), xs.list.items.len);

    try utils.expectEpsilonEq(@as(f32, 3.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f32, 7.0), xs.list.items[1].t);
}

test "Intersecting a translated sphere with a ray" {
    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));
    const s = Sphere{ .transform = Mat4.identity().translate(5, 0, 0) };

    var xs = try intersectSphere(alloc, s, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 0), xs.list.items.len);
}

pub fn sphereNormalAt(sphere: Sphere, world_point: Vec4) Vec4 {
    const object_space = sphere.transform.inverse();
    const object_point = object_space.multVec(world_point);

    const object_normal = object_point.sub(initPoint(0, 0, 0)).normalize();

    var world_normal = object_space.transpose().multVec(object_normal);
    world_normal.w = 0; // or use 3x3 submatrix without translation above

    return world_normal.normalize();
}

test "The normal on a sphere at a point on the x axis" {
    const s = Sphere{};
    const n = sphereNormalAt(s, initPoint(1, 0, 0));
    try std.testing.expect(n.eql(initVector(1, 0, 0)));
}

test "The normal on a sphere at a point on the y axis" {
    const s = Sphere{};
    const n = sphereNormalAt(s, initPoint(0, 1, 0));
    try std.testing.expect(n.eql(initVector(0, 1, 0)));
}

test "The normal on a sphere at a point on the z axis" {
    const s = Sphere{};
    const n = sphereNormalAt(s, initPoint(0, 0, 1));
    try std.testing.expect(n.eql(initVector(0, 0, 1)));
}

test "The normal on a sphere at a point at a nonaxial point" {
    const s = Sphere{};
    const k = std.math.sqrt(3.0) / 3.0;
    const n = sphereNormalAt(s, initPoint(k, k, k));
    try std.testing.expect(n.eql(initVector(k, k, k)));
    try std.testing.expect(n.eql(n.normalize()));
}

test "Computing the normal on a translated sphere" {
    const s = Sphere{
        .transform = Mat4.identity().translate(0, 1, 0),
    };

    const n = sphereNormalAt(s, initPoint(0, 1.70711, -0.70711));
    try utils.expectVec4ApproxEq(n, initVector(0, 0.70711, -0.70711));
}

test "Computing the normal on a translated sphere" {
    const s = Sphere{
        .transform = Mat4.identity()
            .rotateZ(std.math.pi / 5.0)
            .scale(1, 0.5, 1),
    };

    const n = sphereNormalAt(s, initPoint(0, std.math.sqrt(2.0) / 2.0, -std.math.sqrt(2.0) / 2.0));
    try utils.expectVec4ApproxEq(n, initVector(0, 0.97014, -0.24254));
}

pub fn lighting(material: Material, light: PointLight, position: Vec4, eyev: Vec4, normalv: Vec4) Color {
    // combine surface color with light color/intensity
    const effective_color = material.color.mult(light.intensity);

    // find direction of the light source
    const lightv = light.position.sub(position).normalize();

    // ambient
    const ambient = effective_color.scale(material.ambient);

    // light_dot_normal represents cosine of the angle between
    // the light vector and the normal vector.
    // Negative means the light is ont he other side of the surface

    const light_dot_normal = lightv.dot(normalv);

    var diffuse = Color.Black;
    var specular = Color.Black;

    if (light_dot_normal > 0.0) {
        // compute diffuse contribution
        diffuse = effective_color.scale(material.diffuse * light_dot_normal);

        // reflect_dot_eye represents cosine of the angle between
        // reflection the vector and the eye vector.
        // Negative number means the light reflects away from the eye
        const reflectv = lightv.negate().reflect(normalv);
        const reflect_dot_eye = reflectv.dot(eyev);

        if (reflect_dot_eye > 0.0) {
            const factor = std.math.pow(f32, reflect_dot_eye, material.shininess);
            specular = light.intensity.scale(material.specular * factor);
        }
    }

    return ambient.add(diffuse).add(specular);
}

test "Lighting with the eye between the light and the surface" {
    const position = initPoint(0, 0, 0);
    const mat = Material{};

    const eyev = initVector(0, 0, -1);
    const normalv = initVector(0, 0, -1);
    const light = PointLight{
        .position = initPoint(0, 0, -10),
        .intensity = Color.init(1, 1, 1),
    };

    const res = lighting(mat, light, position, eyev, normalv);
    try utils.expectColorApproxEq(Color.init(1.9, 1.9, 1.9), res);
}

test "Lighting with the eye between light and surface, eye offset 45°" {
    const position = initPoint(0, 0, 0);
    const mat = Material{};

    const eyev = initVector(0, 1, -1).normalize();
    const normalv = initVector(0, 0, -1);
    const light = PointLight{
        .position = initPoint(0, 0, -10),
        .intensity = Color.init(1, 1, 1),
    };

    const res = lighting(mat, light, position, eyev, normalv);
    try utils.expectColorApproxEq(Color.init(1.0, 1.0, 1.0), res);
}

test "Lighting with the eye opposite surface, light offset 45°" {
    const position = initPoint(0, 0, 0);
    const mat = Material{};

    const eyev = initVector(0, 0, -1);
    const normalv = initVector(0, 0, -1);
    const light = PointLight{
        .position = initPoint(0, 10, -10),
        .intensity = Color.init(1, 1, 1),
    };

    const res = lighting(mat, light, position, eyev, normalv);
    try utils.expectColorApproxEq(Color.init(0.7364, 0.7364, 0.7364), res);
}

test "Lighting with the eye in the path of the reflection vector" {
    const position = initPoint(0, 0, 0);
    const mat = Material{};

    const eyev = initVector(0, -std.math.sqrt(2.0) / 2.0, -std.math.sqrt(2.0) / 2.0);
    const normalv = initVector(0, 0, -1);
    const light = PointLight{
        .position = initPoint(0, 10, -10),
        .intensity = Color.init(1, 1, 1),
    };

    const res = lighting(mat, light, position, eyev, normalv);
    try utils.expectColorApproxEq(Color.init(1.6364, 1.6364, 1.6364), res);
}

test "Lighting with the light behind the surface" {
    const position = initPoint(0, 0, 0);
    const mat = Material{};

    const eyev = initVector(0, 0, -1);
    const normalv = initVector(0, 0, -1);
    const light = PointLight{
        .position = initPoint(0, 0, 10),
        .intensity = Color.init(1, 1, 1),
    };

    const res = lighting(mat, light, position, eyev, normalv);
    try utils.expectColorApproxEq(Color.init(0.1, 0.1, 0.1), res); // only ambient
}

pub fn intersectWorld(allocator: std.mem.Allocator, world: World, world_ray: Ray) !Intersections {
    var total_intersections = Intersections.init(allocator);
    errdefer total_intersections.deinit();

    for (world.objects.items) |object| {
        var object_intersections = try intersectSphere(allocator, object, world_ray);
        defer object_intersections.deinit();

        try total_intersections.list.appendSlice(object_intersections.list.items);
    }

    std.sort.sort(Intersection, total_intersections.list.items, {}, Intersections.lessThanIntersection);

    return total_intersections;
}

test "Intersect a world with a ray" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));

    var xs = try intersectWorld(alloc, w, r);
    defer xs.deinit();

    try std.testing.expectEqual(@as(usize, 4), xs.list.items.len);

    try utils.expectEpsilonEq(@as(f32, 4.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f32, 4.5), xs.list.items[1].t);
    try utils.expectEpsilonEq(@as(f32, 5.5), xs.list.items[2].t);
    try utils.expectEpsilonEq(@as(f32, 6.0), xs.list.items[3].t);
}

const Computations = struct {
    t: f32,
    object: Sphere,
    point: Vec4,
    eyev: Vec4,
    normalv: Vec4,
    inside: bool,
};

pub fn prepareComputations(intersection: Intersection, ray: Ray) Computations {
    const point = ray.position(intersection.t);
    const eyev = ray.direction.negate();

    var inside = false;
    var normalv = sphereNormalAt(intersection.object, point);

    if (normalv.dot(eyev) < 0) {
        inside = true;
        normalv = normalv.negate();
    }

    return Computations{
        .t = intersection.t,
        .object = intersection.object,
        .point = point,
        .eyev = eyev,
        .normalv = normalv,
        .inside = inside,
    };
}

test "Precomputing the state of an intersection" {
    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));
    const shape = Sphere{};
    const i = Intersection{
        .t = 4,
        .object = shape,
    };

    const comps = prepareComputations(i, r);

    try std.testing.expectEqual(@as(f32, 4.0), comps.t);
    try std.testing.expectEqual(shape, comps.object);
    try std.testing.expectEqual(initPoint(0, 0, -1), comps.point);
    try std.testing.expectEqual(initVector(0, 0, -1), comps.eyev);
    try std.testing.expectEqual(initVector(0, 0, -1), comps.normalv);
}

test "The hit, when an intersection occurs on the outside" {
    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));
    const shape = Sphere{};
    const i = Intersection{
        .t = 4,
        .object = shape,
    };

    const comps = prepareComputations(i, r);
    try std.testing.expectEqual(false, comps.inside);
}

test "The hit, when an intersection occurs on the inside" {
    const r = Ray.init(initPoint(0, 0, 0), initVector(0, 0, 1));
    const shape = Sphere{};
    const i = Intersection{
        .t = 1,
        .object = shape,
    };

    const comps = prepareComputations(i, r);
    try std.testing.expectEqual(initPoint(0, 0, 1), comps.point);
    try std.testing.expectEqual(initVector(0, 0, -1), comps.eyev);
    try std.testing.expectEqual(true, comps.inside);
    try std.testing.expectEqual(initVector(0, 0, -1), comps.normalv);
}

pub fn shadeHit(world: World, comps: Computations) Color {
    return lighting(
        comps.object.material,
        world.light,
        comps.point,
        comps.eyev,
        comps.normalv,
    );
}

test "Shading an intersection" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));
    const shape = w.objects.items[0];
    const i = Intersection{
        .t = 4,
        .object = shape,
    };

    const comps = prepareComputations(i, r);
    const c = shadeHit(w, comps);

    try utils.expectColorApproxEq(Color.init(0.38066, 0.47583, 0.2855), c);
}

test "Shading an intersection from the inside" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    w.light = PointLight{
        .position = initPoint(0, 0.25, 0),
        .intensity = Color.White,
    };

    const r = Ray.init(initPoint(0, 0, 0), initVector(0, 0, 1));
    const shape = w.objects.items[1];
    const i = Intersection{
        .t = 0.5,
        .object = shape,
    };

    const comps = prepareComputations(i, r);
    const c = shadeHit(w, comps);

    try utils.expectColorApproxEq(Color.init(0.90498, 0.90498, 0.90498), c);
}

pub fn worldColorAt(allocator: std.mem.Allocator, world: World, ray: Ray) !Color {
    var xs = try intersectWorld(allocator, world, ray);
    defer xs.deinit();

    const hit = xs.hit();
    if (hit != null) {
        const comps = prepareComputations(hit.?, ray);
        return shadeHit(world, comps);
    } else {
        return Color.Black;
    }
}

test "The color when a ray misses" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 1, 0));

    const c = try worldColorAt(alloc, w, r);
    try utils.expectColorApproxEq(Color.init(0, 0, 0), c);
}

test "The color when a ray hits" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));

    const c = try worldColorAt(alloc, w, r);
    try utils.expectColorApproxEq(Color.init(0.38066, 0.47583, 0.2855), c);
}

test "The color with an intersection behind the ray" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    var outer = &w.objects.items[0];
    outer.material.color = Color.init(0.3, 0.3, 1.0);
    outer.material.ambient = 1.0;

    var inner = &w.objects.items[1];
    inner.material.color = Color.init(0.5, 1.0, 0.2);
    inner.material.ambient = 1.0;

    const r = Ray.init(initPoint(0, 0, 0.75), initVector(0, 0, -1));

    const c = try worldColorAt(alloc, w, r);
    try utils.expectColorApproxEq(inner.material.color, c);
}

pub fn viewTransform(from: Vec4, to: Vec4, up: Vec4) Mat4 {
    const forward = to.sub(from).normalize();
    const left = forward.cross(up.normalize());
    const true_up = left.cross(forward);

    const orientation = Mat4{
        .mat = .{
            .{ left.x, left.y, left.z, 0 },
            .{ true_up.x, true_up.y, true_up.z, 0 },
            .{ -forward.x, -forward.y, -forward.z, 0 },
            .{ 0, 0, 0, 1 },
        },
    };

    const translation = Mat4.identity().translate(-from.x, -from.y, -from.z);

    return orientation.mult(translation);
}

test "The transformation matrix for the default orientiation" {
    const from = initPoint(0, 0, 0);
    const to = initPoint(0, 0, -1);
    const up = initVector(0, 1, 0);

    const t = viewTransform(from, to, up);

    try utils.expectMatrixApproxEq(t, Mat4.identity());
}

test "The view transformation moves the world" {
    const from = initPoint(0, 0, 8);
    const to = initPoint(0, 0, 0);
    const up = initVector(0, 1, 0);

    const t = viewTransform(from, to, up);

    try utils.expectMatrixApproxEq(t, Mat4.identity().translate(0, 0, -8));
}

test "An arbitrary view transformation" {
    const from = initPoint(1, 3, 2);
    const to = initPoint(4, -2, 8);
    const up = initVector(1, 1, 0);

    const t = viewTransform(from, to, up);

    try utils.expectMatrixApproxEq(t, Mat4{
        .mat = .{
            .{ -0.50709, 0.50709, 0.67612, -2.36643 },
            .{ 0.76772, 0.60609, 0.12122, -2.82843 },
            .{ -0.35857, 0.59761, -0.71714, 0.00000 },
            .{ 0.00000, 0.00000, 0.00000, 1.00000 },
        },
    });
}
