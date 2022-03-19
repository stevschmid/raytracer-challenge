const std = @import("std");
const utils = @import("utils.zig");

const Vec4 = @import("vector.zig").Vec4;
const Mat4 = @import("matrix.zig").Mat4;
const Color = @import("color.zig").Color;
const Pattern = @import("pattern.zig").Pattern;

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

const MaxIterations = 5;

pub fn lighting(
    object: Shape,
    light: PointLight,
    position: Vec4,
    eyev: Vec4,
    normalv: Vec4,
    in_shadow: bool,
) Color {
    const material = object.material;

    const color = if (material.pattern) |pattern| pattern.patternAt(object, position) else material.color;

    // combine surface color with light color/intensity
    const effective_color = color.mult(light.intensity);

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
    const obj = Shape{ .material = mat };

    const eyev = initVector(0, 0, -1);
    const normalv = initVector(0, 0, -1);
    const light = PointLight{
        .position = initPoint(0, 0, -10),
        .intensity = Color.init(1, 1, 1),
    };

    const res = lighting(obj, light, position, eyev, normalv, false);
    try utils.expectColorApproxEq(Color.init(1.9, 1.9, 1.9), res);
}

test "Lighting with the eye between light and surface, eye offset 45°" {
    const position = initPoint(0, 0, 0);
    const mat = Material{};
    const obj = Shape{ .material = mat };

    const eyev = initVector(0, 1, -1).normalize();
    const normalv = initVector(0, 0, -1);
    const light = PointLight{
        .position = initPoint(0, 0, -10),
        .intensity = Color.init(1, 1, 1),
    };

    const res = lighting(obj, light, position, eyev, normalv, false);
    try utils.expectColorApproxEq(Color.init(1.0, 1.0, 1.0), res);
}

test "Lighting with the eye opposite surface, light offset 45°" {
    const position = initPoint(0, 0, 0);
    const mat = Material{};
    const obj = Shape{ .material = mat };

    const eyev = initVector(0, 0, -1);
    const normalv = initVector(0, 0, -1);
    const light = PointLight{
        .position = initPoint(0, 10, -10),
        .intensity = Color.init(1, 1, 1),
    };

    const res = lighting(obj, light, position, eyev, normalv, false);
    try utils.expectColorApproxEq(Color.init(0.7364, 0.7364, 0.7364), res);
}

test "Lighting with the eye in the path of the reflection vector" {
    const position = initPoint(0, 0, 0);
    const mat = Material{};
    const obj = Shape{ .material = mat };

    const eyev = initVector(0, -std.math.sqrt(2.0) / 2.0, -std.math.sqrt(2.0) / 2.0);
    const normalv = initVector(0, 0, -1);
    const light = PointLight{
        .position = initPoint(0, 10, -10),
        .intensity = Color.init(1, 1, 1),
    };

    const res = lighting(obj, light, position, eyev, normalv, false);
    try utils.expectColorApproxEq(Color.init(1.6364, 1.6364, 1.6364), res);
}

test "Lighting with the light behind the surface" {
    const position = initPoint(0, 0, 0);
    const mat = Material{};
    const obj = Shape{ .material = mat };

    const eyev = initVector(0, 0, -1);
    const normalv = initVector(0, 0, -1);
    const light = PointLight{
        .position = initPoint(0, 0, 10),
        .intensity = Color.init(1, 1, 1),
    };

    const res = lighting(obj, light, position, eyev, normalv, false);
    try utils.expectColorApproxEq(Color.init(0.1, 0.1, 0.1), res); // only ambient
}

test "Lighting with the surface in shadow" {
    const position = initPoint(0, 0, 0);
    const mat = Material{};
    const obj = Shape{ .material = mat };

    const eyev = initVector(0, 0, -1);
    const normalv = initVector(0, 0, -1);
    const light = PointLight{
        .position = initPoint(0, 0, -10),
        .intensity = Color.init(1, 1, 1),
    };
    const in_shadow = true;

    const res = lighting(obj, light, position, eyev, normalv, in_shadow);
    try utils.expectColorApproxEq(Color.init(0.1, 0.1, 0.1), res);
}

test "Lighting with a pattern applied" {
    const a = Color.init(0.5, 0.2, 0.9);
    const b = Color.init(0.2, 0.8, 1.0);

    const pattern = Pattern{ .pattern = .{ .stripe = .{ .a = a, .b = b } } };
    const mat = Material{
        .pattern = pattern,
        .ambient = 1,
        .diffuse = 0,
        .specular = 0,
    };
    const obj = Shape{ .material = mat };

    const eyev = initVector(0, 0, -1);
    const normalv = initVector(0, 0, -1);
    const light = PointLight{
        .position = initPoint(0, 0, -10),
        .intensity = Color.init(1, 1, 1),
    };
    const in_shadow = false;

    const c1 = lighting(obj, light, initPoint(0.9, 0, 0), eyev, normalv, in_shadow);
    const c2 = lighting(obj, light, initPoint(1.1, 0, 0), eyev, normalv, in_shadow);

    try utils.expectColorApproxEq(a, c1);
    try utils.expectColorApproxEq(b, c2);
}

pub fn intersectWorld(world: World, world_ray: Ray) !Intersections {
    var total_intersections = Intersections.init(world.allocator);
    errdefer total_intersections.deinit();

    for (world.objects.items) |object| {
        var object_intersections = try object.intersect(world.allocator, world_ray);
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

    var xs = try intersectWorld(w, r);
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
    under_point: Vec4,
    eyev: Vec4,
    normalv: Vec4,
    reflectv: Vec4,
    n1: f64,
    n2: f64,
    inside: bool,
};

pub fn prepareComputations(intersection: Intersection, ray: Ray, xs: ?Intersections) Computations {
    _ = xs;
    const point = ray.position(intersection.t);
    const eyev = ray.direction.negate();

    var inside = false;
    var normalv = intersection.object.normalAt(point);

    if (normalv.dot(eyev) < 0) {
        inside = true;
        normalv = normalv.negate();
    }

    const reflectv = ray.direction.reflect(normalv);

    const epsilon = 0.0001;
    const over_point = point.add(normalv.scale(epsilon));
    const under_point = point.sub(normalv.scale(epsilon));

    var n1: f64 = 1.0;
    var n2: f64 = 1.0;

    if (xs != null) {
        var containers = std.ArrayList(Shape).init(xs.?.allocator);
        defer containers.deinit();

        for (xs.?.list.items) |i| {
            const is_hit = std.meta.eql(i, intersection);
            if (is_hit) {
                n1 = if (containers.items.len == 0) 1.0 else containers.items[containers.items.len - 1].material.refractive_index;
            }

            for (containers.items) |c, idx| {
                if (std.meta.eql(c, i.object)) {
                    _ = containers.orderedRemove(idx);
                    break;
                }
            } else containers.append(i.object) catch unreachable;

            if (is_hit) {
                n2 = if (containers.items.len == 0) 1.0 else containers.items[containers.items.len - 1].material.refractive_index;
                break;
            }
        }
    }

    return Computations{
        .t = intersection.t,
        .object = intersection.object,
        .point = point,
        .over_point = over_point,
        .under_point = under_point,
        .eyev = eyev,
        .normalv = normalv,
        .reflectv = reflectv,
        .inside = inside,
        .n1 = n1,
        .n2 = n2,
    };
}

test "Precomputing the state of an intersection" {
    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));
    const shape = Shape{ .geo = .{ .sphere = .{} } };
    const i = Intersection{
        .t = 4,
        .object = shape,
    };

    const comps = prepareComputations(i, r, null);

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

    const comps = prepareComputations(i, r, null);
    try std.testing.expectEqual(false, comps.inside);
}

test "The hit, when an intersection occurs on the inside" {
    const r = Ray.init(initPoint(0, 0, 0), initVector(0, 0, 1));
    const shape = Shape{ .geo = .{ .sphere = .{} } };
    const i = Intersection{
        .t = 1,
        .object = shape,
    };

    const comps = prepareComputations(i, r, null);
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

    const comps = prepareComputations(i, r, null);
    try std.testing.expectEqual(@as(f64, -0.0001), comps.over_point.z);
    try std.testing.expect(comps.point.z > comps.over_point.z);
}

test "Precomputing the reflection vector" {
    const shape = Shape{ .geo = .{ .plane = .{} } };
    const r = Ray.init(initPoint(0, 0, -1), initVector(-0, -std.math.sqrt(2.0) / 2.0, std.math.sqrt(2.0) / 2.0));
    const i = Intersection{
        .t = std.math.sqrt(2.0),
        .object = shape,
    };
    const comps = prepareComputations(i, r, null);
    try utils.expectVec4ApproxEq(initVector(0, std.math.sqrt(2.0) / 2.0, std.math.sqrt(2.0) / 2.0), comps.reflectv);
}

pub fn initGlassSphere() Shape {
    return .{
        .geo = .{ .sphere = .{} },
        .material = .{ .transparency = 1.0, .refractive_index = 1.5 },
    };
}

test "The under point is offset below the surface" {
    var shape = initGlassSphere();
    shape.transform = Mat4.identity().translate(0, 0, 1);

    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));
    const i = Intersection{
        .t = 5.0,
        .object = shape,
    };
    const comps = prepareComputations(i, r, null);
    try std.testing.expectEqual(@as(f64, 0.0001), comps.under_point.z);
    try std.testing.expect(comps.point.z < comps.under_point.z);
}

test "Finding n1 and n2 at various inersections" {
    const Example = struct {
        index: u32,
        n1: f64,
        n2: f64,
    };

    const examples: []const Example = &[_]Example{
        .{ .index = 0, .n1 = 1.0, .n2 = 1.5 },
        .{ .index = 1, .n1 = 1.5, .n2 = 2.0 },
        .{ .index = 2, .n1 = 2.0, .n2 = 2.5 },
        .{ .index = 3, .n1 = 2.5, .n2 = 2.5 },
        .{ .index = 4, .n1 = 2.5, .n2 = 1.5 },
        .{ .index = 5, .n1 = 1.5, .n2 = 1.0 },
    };

    var a = initGlassSphere();
    a.transform = Mat4.identity().scale(2, 2, 2);
    a.material.refractive_index = 1.5;

    var b = initGlassSphere();
    b.transform = Mat4.identity().translate(0, 0, -0.25);
    b.material.refractive_index = 2.0;

    var c = initGlassSphere();
    c.transform = Mat4.identity().translate(0, 0, 0.25);
    c.material.refractive_index = 2.5;

    const r = Ray.init(initPoint(0, 0, -4), initVector(0, 0, 1));

    var xs = Intersections.init(alloc);
    defer xs.deinit();

    try xs.list.append(.{ .t = 2, .object = a });
    try xs.list.append(.{ .t = 2.75, .object = b });
    try xs.list.append(.{ .t = 3.25, .object = c });
    try xs.list.append(.{ .t = 4.75, .object = b });
    try xs.list.append(.{ .t = 5.25, .object = c });
    try xs.list.append(.{ .t = 6, .object = a });

    for (examples) |example| {
        const i = xs.list.items[example.index];
        const comps = prepareComputations(i, r, xs);
        try utils.expectEpsilonEq(example.n1, comps.n1);
        try utils.expectEpsilonEq(example.n2, comps.n2);
    }
}

pub fn shadeHit(world: World, comps: Computations, remaining: i32) Color {
    const in_shadow = isShadowed(world, comps.over_point) catch false;

    const surface = lighting(
        comps.object,
        world.light,
        comps.over_point,
        comps.eyev,
        comps.normalv,
        in_shadow,
    );

    const reflected = reflectedColor(world, comps, remaining);
    const refracted = refractedColor(world, comps, remaining);

    const material = comps.object.material;
    if (material.reflective > 0.0 and material.transparency > 0.0) {
        const reflectance = schlick(comps);
        return surface.add(reflected.scale(reflectance)).add(refracted.scale(1.0 - reflectance));
    } else {
        return surface.add(reflected).add(refracted);
    }
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

    const comps = prepareComputations(i, r, null);
    const c = shadeHit(w, comps, MaxIterations);

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

    const comps = prepareComputations(i, r, null);
    const c = shadeHit(w, comps, MaxIterations);

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

    const comps = prepareComputations(i, r, null);
    const c = shadeHit(w, comps, MaxIterations);

    try utils.expectColorApproxEq(Color.init(0.1, 0.1, 0.1), c);
}

test "shade_hit() with a reflective material" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    var shape = Shape{
        .geo = .{ .plane = .{} },
        .transform = Mat4.identity().translate(0, -1, 0),
        .material = .{ .reflective = 0.5 },
    };
    try w.objects.append(shape);

    const r = Ray.init(initPoint(0, 0, -3), initVector(0, -std.math.sqrt(2.0) / 2.0, std.math.sqrt(2.0) / 2.0));
    const i = Intersection{
        .t = std.math.sqrt(2.0),
        .object = shape,
    };

    const comps = prepareComputations(i, r, null);
    const color = shadeHit(w, comps, MaxIterations);

    try utils.expectColorApproxEq(Color.init(0.87677, 0.92436, 0.82918), color);
}

test "shade_hit() with a transparent material" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    var floor = Shape{
        .geo = .{ .plane = .{} },
        .transform = Mat4.identity().translate(0, -1, 0),
        .material = .{
            .transparency = 0.5,
            .refractive_index = 1.5,
        },
    };
    try w.objects.append(floor);

    var ball = Shape{
        .geo = .{ .sphere = .{} },
        .transform = Mat4.identity().translate(0, -3.5, -0.5),
        .material = .{
            .color = Color.init(1, 0, 0),
            .ambient = 0.5,
        },
    };
    try w.objects.append(ball);

    const r = Ray.init(initPoint(0, 0, -3), initVector(0, -std.math.sqrt(2.0) / 2.0, std.math.sqrt(2.0) / 2.0));
    var xs = Intersections.init(alloc);
    defer xs.deinit();
    try xs.list.append(.{
        .t = std.math.sqrt(2.0),
        .object = floor,
    });

    const comps = prepareComputations(xs.list.items[0], r, xs);
    const color = shadeHit(w, comps, MaxIterations);

    try utils.expectColorApproxEq(Color.init(0.93642, 0.68642, 0.68642), color);
}

test "shade_hit() with a reflective, transparent material" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    var floor = Shape{
        .geo = .{ .plane = .{} },
        .transform = Mat4.identity().translate(0, -1, 0),
        .material = .{
            .reflective = 0.5,
            .transparency = 0.5,
            .refractive_index = 1.5,
        },
    };
    try w.objects.append(floor);

    var ball = Shape{
        .geo = .{ .sphere = .{} },
        .transform = Mat4.identity().translate(0, -3.5, -0.5),
        .material = .{
            .color = Color.init(1, 0, 0),
            .ambient = 0.5,
        },
    };
    try w.objects.append(ball);

    const r = Ray.init(initPoint(0, 0, -3), initVector(0, -std.math.sqrt(2.0) / 2.0, std.math.sqrt(2.0) / 2.0));
    var xs = Intersections.init(alloc);
    defer xs.deinit();
    try xs.list.append(.{
        .t = std.math.sqrt(2.0),
        .object = floor,
    });

    const comps = prepareComputations(xs.list.items[0], r, xs);
    const color = shadeHit(w, comps, MaxIterations);

    try utils.expectColorApproxEq(Color.init(0.93391, 0.69643, 0.69243), color);
}

pub fn worldColorAt(world: World, ray: Ray, remaining: i32) !Color {
    var xs = try intersectWorld(world, ray);
    defer xs.deinit();

    const hit = xs.hit();
    if (hit != null) {
        const comps = prepareComputations(hit.?, ray, xs);
        return shadeHit(world, comps, remaining);
    } else {
        return Color.Black;
    }
}

test "The color when a ray misses" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 1, 0));

    const c = try worldColorAt(w, r, MaxIterations);
    try utils.expectColorApproxEq(Color.init(0, 0, 0), c);
}

test "The color when a ray hits" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));

    const c = try worldColorAt(w, r, MaxIterations);
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

    const c = try worldColorAt(w, r, MaxIterations);
    try utils.expectColorApproxEq(inner.material.color, c);
}

test "worldColorAt() with mutually reflective surfaces" {
    var w = World.init(alloc);
    defer w.deinit();

    w.light = PointLight{
        .position = initPoint(0, 0, 0),
        .intensity = Color.init(1, 1, 1),
    };

    var lower = Shape{
        .geo = .{ .plane = .{} },
        .transform = Mat4.identity().translate(0, -1, 0),
        .material = .{ .reflective = 1 },
    };
    try w.objects.append(lower);

    var upper = Shape{
        .geo = .{ .plane = .{} },
        .transform = Mat4.identity().translate(0, 1, 0),
        .material = .{ .reflective = 1 },
    };
    try w.objects.append(upper);

    const r = Ray.init(initPoint(0, 0, 0), initVector(0, 1, 1));

    // should terminate
    _ = try worldColorAt(w, r, MaxIterations);
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

fn isShadowed(world: World, point: Vec4) !bool {
    const v = world.light.position.sub(point);

    const distance = v.length();
    const direction = v.normalize();

    const ray = Ray.init(point, direction);

    var xs = try intersectWorld(world, ray);
    defer xs.deinit();

    const hit = xs.hit();
    return (hit != null and hit.?.t < distance);
}

test "There is no shadow when nothing is collinear with point and light" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const p = initPoint(0, 10, 0);
    const result = try isShadowed(w, p);
    try std.testing.expect(result == false);
}

test "The shadow when an object is between the point and the light" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const p = initPoint(10, -10, 10);
    const result = try isShadowed(w, p);
    try std.testing.expect(result == true);
}

test "There is no shadow when an object is behind the light" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const p = initPoint(-20, 20, -20);
    const result = try isShadowed(w, p);
    try std.testing.expect(result == false);
}

test "There is no shadow when an object is behind the point" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const p = initPoint(-2, 2, -2);
    const result = try isShadowed(w, p);
    try std.testing.expect(result == false);
}

pub fn refractedColor(world: World, comps: Computations, remaining: i32) Color {
    if (remaining <= 0) {
        return Color.Black;
    }

    if (std.math.approxEqAbs(f64, comps.object.material.transparency, 0.0, std.math.epsilon(f64))) {
        return Color.Black;
    }

    const n_ratio = comps.n1 / comps.n2;
    const cos_i = comps.eyev.dot(comps.normalv);
    const sin2_t = n_ratio * n_ratio * (1 - cos_i * cos_i);

    if (sin2_t > 1.0) {
        // total internal reflection
        return Color.Black;
    }

    const cos_t = std.math.sqrt(1.0 - sin2_t);
    const direction = comps.normalv.scale(n_ratio * cos_i - cos_t).sub(comps.eyev.scale(n_ratio));

    const refract_ray = Ray.init(comps.under_point, direction);

    const color = worldColorAt(world, refract_ray, remaining - 1) catch Color.Black;
    return color.scale(comps.object.material.transparency);
}

test "The refracted color with an opaque surface" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));

    var shape = &w.objects.items[1];
    shape.material.transparency = 0.0;

    const i = Intersection{
        .t = 4,
        .object = shape.*,
    };

    const comps = prepareComputations(i, r, null);
    const color = refractedColor(w, comps, MaxIterations);

    try utils.expectColorApproxEq(Color.Black, color);
}

test "The refracted color at maximum recursive depth" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    var shape = &w.objects.items[0];
    shape.material.transparency = 1.0;
    shape.material.refractive_index = 1.5;

    const r = Ray.init(initPoint(0, 0, -5), initVector(0, 0, 1));

    const i = Intersection{
        .t = 4,
        .object = shape.*,
    };

    const comps = prepareComputations(i, r, null);
    const color = refractedColor(w, comps, 0);

    try utils.expectColorApproxEq(Color.Black, color);
}

test "The refracted color under total internal reflection" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    var shape = &w.objects.items[0];
    shape.material.transparency = 1.0;
    shape.material.refractive_index = 1.5;

    const r = Ray.init(initPoint(0, 0, std.math.sqrt(2.0) / 2.0), initVector(0, 1, 0));

    var xs = Intersections.init(alloc);
    defer xs.deinit();

    try xs.list.append(.{ .t = -std.math.sqrt(2.0) / 2.0, .object = shape.* });
    try xs.list.append(.{ .t = std.math.sqrt(2.0) / 2.0, .object = shape.* });

    const comps = prepareComputations(xs.list.items[1], r, xs);
    const color = refractedColor(w, comps, MaxIterations);

    try utils.expectColorApproxEq(Color.Black, color);
}

test "The refracted color with a refracted ray" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    var a = &w.objects.items[0];
    a.material.ambient = 1.0;
    a.material.pattern = .{ .pattern = .{ .point = {} } };

    var b = &w.objects.items[1];
    b.material.transparency = 1.0;
    b.material.refractive_index = 1.5;

    const r = Ray.init(initPoint(0, 0, 0.1), initVector(0, 1, 0));
    var xs = Intersections.init(alloc);
    defer xs.deinit();

    try xs.list.append(.{ .t = -0.9899, .object = a.* });
    try xs.list.append(.{ .t = -0.4899, .object = b.* });
    try xs.list.append(.{ .t = 0.4899, .object = b.* });
    try xs.list.append(.{ .t = 0.9899, .object = a.* });

    const comps = prepareComputations(xs.list.items[2], r, xs);
    const color = refractedColor(w, comps, MaxIterations);

    try utils.expectColorApproxEq(Color.init(0, 0.99888, 0.04725), color);
}

pub fn reflectedColor(world: World, comps: Computations, remaining: i32) Color {
    if (remaining <= 0) {
        return Color.Black;
    }

    const reflective = comps.object.material.reflective;
    if (std.math.approxEqAbs(f64, reflective, 0.0, std.math.epsilon(f64))) {
        return Color.Black;
    }

    const reflect_ray = Ray.init(comps.over_point, comps.reflectv);
    const color = worldColorAt(world, reflect_ray, remaining - 1) catch Color.Black;

    return color.scale(reflective);
}

test "The reflected color for a nonreflective material" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const r = Ray.init(initPoint(0, 0, 0), initVector(0, 0, 1));

    var shape = &w.objects.items[1];
    shape.material.ambient = 1.0;

    const i = Intersection{
        .t = 1,
        .object = shape.*,
    };

    const comps = prepareComputations(i, r, null);
    const color = reflectedColor(w, comps, MaxIterations);

    try utils.expectColorApproxEq(Color.Black, color);
}

test "The reflected color for a nonreflective material" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    var shape = Shape{
        .geo = .{ .plane = .{} },
        .transform = Mat4.identity().translate(0, -1, 0),
        .material = .{ .reflective = 0.5 },
    };
    try w.objects.append(shape);

    const r = Ray.init(initPoint(0, 0, -3), initVector(0, -std.math.sqrt(2.0) / 2.0, std.math.sqrt(2.0) / 2.0));
    const i = Intersection{
        .t = std.math.sqrt(2.0),
        .object = shape,
    };

    const comps = prepareComputations(i, r, null);
    const color = reflectedColor(w, comps, MaxIterations);

    try utils.expectColorApproxEq(Color.init(0.19032, 0.2379, 0.14274), color);
}

fn schlick(comps: Computations) f64 {
    // find cosine of the angle between eye and normal vector
    var cos = comps.eyev.dot(comps.normalv);

    // total internal reflection can only occur if n1>n2
    if (comps.n1 > comps.n2) {
        const n = comps.n1 / comps.n2;
        const sin2_t = n * n * (1.0 - cos * cos);

        if (sin2_t > 1.0) {
            return 1.0;
        }

        // compute cosine of theta_t using trig identity
        const cos_t = std.math.sqrt(1.0 - sin2_t);

        // when n1 > n2, use cos(theta_t) instead
        cos = cos_t;
    }

    const r0 = std.math.pow(f64, (comps.n1 - comps.n2) / (comps.n1 + comps.n2), 2.0);
    return r0 + (1 - r0) * std.math.pow(f64, 1 - cos, 5.0);
}

test "The schlick approximation under total internal reflection" {
    const shape = initGlassSphere();
    const r = Ray.init(initPoint(0, 0, std.math.sqrt(2.0) / 2.0), initVector(0, 1, 0));

    var xs = Intersections.init(alloc);
    defer xs.deinit();
    try xs.list.append(.{ .t = -std.math.sqrt(2.0) / 2.0, .object = shape });
    try xs.list.append(.{ .t = std.math.sqrt(2.0) / 2.0, .object = shape });

    const comps = prepareComputations(xs.list.items[1], r, xs);
    const reflectance = schlick(comps);
    try std.testing.expectApproxEqAbs(@as(f64, 1.0), reflectance, 0.00001);
}

test "The Schlick approximation with a perpendicular viewing angle" {
    const shape = initGlassSphere();
    const r = Ray.init(initPoint(0, 0, 0), initVector(0, 1, 0));

    var xs = Intersections.init(alloc);
    defer xs.deinit();
    try xs.list.append(.{ .t = -1, .object = shape });
    try xs.list.append(.{ .t = 1, .object = shape });

    const comps = prepareComputations(xs.list.items[1], r, xs);
    const reflectance = schlick(comps);
    try std.testing.expectApproxEqAbs(@as(f64, 0.04), reflectance, 0.00001);
}

test "The Schlick approximation with small angle and n2 > n1" {
    const shape = initGlassSphere();
    const r = Ray.init(initPoint(0, 0.99, -2), initVector(0, 0, 1));

    var xs = Intersections.init(alloc);
    defer xs.deinit();
    try xs.list.append(.{ .t = 1.8589, .object = shape });

    const comps = prepareComputations(xs.list.items[0], r, xs);
    const reflectance = schlick(comps);
    try std.testing.expectApproxEqAbs(@as(f64, 0.48873), reflectance, 0.00001);
}
