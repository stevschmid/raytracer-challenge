const std = @import("std");
const utils = @import("utils.zig");

const Vec4 = @import("vector.zig").Vec4;
const Mat4 = @import("matrix.zig").Mat4;
const Color = @import("color.zig").Color;

const initVector = @import("vector.zig").initVector;
const initPoint = @import("vector.zig").initPoint;

const World = @import("world.zig").World;
const Shape = @import("shape.zig").Shape;

const Ray = @import("ray.zig").Ray;
const Intersections = @import("ray.zig").Intersections;
const Intersection = @import("ray.zig").Intersection;

const Material = @import("material.zig").Material;
const PointLight = @import("light.zig").PointLight;

const alloc = std.testing.allocator;

pub fn lighting(material: Material, light: PointLight, position: Vec4, eyev: Vec4, normalv: Vec4, in_shadow: bool) Color {
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

    if (light_dot_normal > 0.0 and !in_shadow) {
        // compute diffuse contribution
        diffuse = effective_color.scale(material.diffuse * light_dot_normal);

        // reflect_dot_eye represents cosine of the angle between
        // reflection the vector and the eye vector.
        // Negative number means the light reflects away from the eye
        const reflectv = lightv.negate().reflect(normalv);
        const reflect_dot_eye = reflectv.dot(eyev);

        if (reflect_dot_eye > 0.0) {
            const factor = std.math.pow(f64, reflect_dot_eye, material.shininess);
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

    const res = lighting(mat, light, position, eyev, normalv, false);
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

    const res = lighting(mat, light, position, eyev, normalv, false);
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

    const res = lighting(mat, light, position, eyev, normalv, false);
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

    const res = lighting(mat, light, position, eyev, normalv, false);
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

    const res = lighting(mat, light, position, eyev, normalv, false);
    try utils.expectColorApproxEq(Color.init(0.1, 0.1, 0.1), res); // only ambient
}

test "Lighting with the surface in shadow" {
    const position = initPoint(0, 0, 0);
    const mat = Material{};

    const eyev = initVector(0, 0, -1);
    const normalv = initVector(0, 0, -1);
    const light = PointLight{
        .position = initPoint(0, 0, -10),
        .intensity = Color.init(1, 1, 1),
    };
    const in_shadow = true;

    const res = lighting(mat, light, position, eyev, normalv, in_shadow);
    try utils.expectColorApproxEq(Color.init(0.1, 0.1, 0.1), res);
}

pub fn intersectWorld(allocator: std.mem.Allocator, world: World, world_ray: Ray) !Intersections {
    var total_intersections = Intersections.init(allocator);
    errdefer total_intersections.deinit();

    for (world.objects.items) |object| {
        var object_intersections = try object.intersect(allocator, world_ray);
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

    try utils.expectEpsilonEq(@as(f64, 4.0), xs.list.items[0].t);
    try utils.expectEpsilonEq(@as(f64, 4.5), xs.list.items[1].t);
    try utils.expectEpsilonEq(@as(f64, 5.5), xs.list.items[2].t);
    try utils.expectEpsilonEq(@as(f64, 6.0), xs.list.items[3].t);
}

const Computations = struct {
    t: f64,
    object: Shape,
    point: Vec4,
    over_point: Vec4,
    eyev: Vec4,
    normalv: Vec4,
    inside: bool,
};

pub fn prepareComputations(intersection: Intersection, ray: Ray) Computations {
    const point = ray.position(intersection.t);
    const eyev = ray.direction.negate();

    var inside = false;
    var normalv = intersection.object.normalAt(point);

    if (normalv.dot(eyev) < 0) {
        inside = true;
        normalv = normalv.negate();
    }

    const epsilon = 0.0001;
    const over_point = point.add(normalv.scale(epsilon));

    return Computations{
        .t = intersection.t,
        .object = intersection.object,
        .point = point,
        .over_point = over_point,
        .eyev = eyev,
        .normalv = normalv,
        .inside = inside,
    };
}

test "Precomputing the state of an intersection" {
    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));
    const shape = Shape{ .geo = .{ .sphere = .{} } };
    const i = Intersection{
        .t = 4,
        .object = shape,
    };

    const comps = prepareComputations(i, r);

    try std.testing.expectEqual(@as(f64, 4.0), comps.t);
    try std.testing.expectEqual(shape, comps.object);
    try std.testing.expectEqual(initPoint(0, 0, -1), comps.point);
    try std.testing.expectEqual(initVector(0, 0, -1), comps.eyev);
    try std.testing.expectEqual(initVector(0, 0, -1), comps.normalv);
}

test "The hit, when an intersection occurs on the outside" {
    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));
    const shape = Shape{ .geo = .{ .sphere = .{} } };
    const i = Intersection{
        .t = 4,
        .object = shape,
    };

    const comps = prepareComputations(i, r);
    try std.testing.expectEqual(false, comps.inside);
}

test "The hit, when an intersection occurs on the inside" {
    const r = Ray.init(initPoint(0, 0, 0), initVector(0, 0, 1));
    const shape = Shape{ .geo = .{ .sphere = .{} } };
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

test "The hit should offset the point" {
    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));
    const shape = Shape{
        .transform = Mat4.identity().translate(0, 0, 1),
        .geo = .{ .sphere = .{} },
    };
    const i = Intersection{
        .t = 5,
        .object = shape,
    };

    const comps = prepareComputations(i, r);
    try std.testing.expectEqual(@as(f64, -0.0001), comps.over_point.z);
    try std.testing.expect(comps.point.z > comps.over_point.z);
}

pub fn shadeHit(world: World, comps: Computations) Color {
    const in_shadow = isShadowed(world.allocator, world, comps.over_point) catch false;

    return lighting(
        comps.object.material,
        world.light,
        comps.point,
        comps.eyev,
        comps.normalv,
        in_shadow,
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

test "shade_hit() is given an intersection in shadow" {
    var w = World.init(alloc);
    defer w.deinit();

    w.light = PointLight{
        .position = initPoint(0, 0, -10),
        .intensity = Color.White,
    };

    const s1 = Shape{ .geo = .{ .sphere = .{} } };
    try w.objects.append(s1);

    const s2 = Shape{
        .transform = Mat4.identity().translate(0, 0, 10),
        .geo = .{ .sphere = .{} },
    };
    try w.objects.append(s2);

    const r = Ray.init(initPoint(0, 0, 5), initVector(0, 0, 1));
    const i = Intersection{
        .t = 4,
        .object = s2,
    };

    const comps = prepareComputations(i, r);
    const c = shadeHit(w, comps);

    try utils.expectColorApproxEq(Color.init(0.1, 0.1, 0.1), c);
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

fn isShadowed(allocator: std.mem.Allocator, world: World, point: Vec4) !bool {
    const v = world.light.position.sub(point);

    const distance = v.length();
    const direction = v.normalize();

    const ray = Ray.init(point, direction);

    var xs = try intersectWorld(allocator, world, ray);
    defer xs.deinit();

    const hit = xs.hit();
    return (hit != null and hit.?.t < distance);
}

test "There is no shadow when nothing is collinear with point and light" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const p = initPoint(0, 10, 0);
    const result = try isShadowed(alloc, w, p);
    try std.testing.expect(result == false);
}

test "The shadow when an object is between the point and the light" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const p = initPoint(10, -10, 10);
    const result = try isShadowed(alloc, w, p);
    try std.testing.expect(result == true);
}

test "There is no shadow when an object is behind the light" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const p = initPoint(-20, 20, -20);
    const result = try isShadowed(alloc, w, p);
    try std.testing.expect(result == false);
}

test "There is no shadow when an object is behind the point" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const p = initPoint(-2, 2, -2);
    const result = try isShadowed(alloc, w, p);
    try std.testing.expect(result == false);
}
