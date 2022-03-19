const std = @import("std");

const vector = @import("vector.zig");
const Vec4 = Vec4;
const initPoint = vector.initPoint;
const initVector = vector.initVector;

const Mat4 = @import("matrix.zig").Mat4;
const Canvas = @import("canvas.zig").Canvas;
const Color = @import("color.zig").Color;
const Pattern = @import("pattern.zig").Pattern;
const canvasToPPM = @import("ppm.zig").canvasToPPM;

const Shape = @import("shape.zig").Shape;
const Ray = @import("ray.zig").Ray;
const Material = @import("material.zig").Material;
const PointLight = @import("light.zig").PointLight;
const World = @import("world.zig").World;
const Camera = @import("camera.zig").Camera;

const calc = @import("calc.zig");

pub fn main() !void {
    // https://forum.raytracerchallenge.com/thread/4/reflection-refraction-scene-description
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var world = World.init(allocator);
    defer world.deinit();

    var camera = Camera.init(900, 450, 1.152);
    const from = initVector(-2.6, 1.5, -3.9);
    const to = initVector(-0.6, 1, -0.8);
    const up = initVector(0, 1, 0);
    camera.transform = calc.viewTransform(from, to, up);

    world.light = PointLight{
        .position = initPoint(-4.9, 4.9, -1),
        .intensity = Color.White,
    };

    const wall_pattern = Pattern{
        .pattern = .{ .stripe = .{ .a = Color.init(0.45, 0.45, 0.45), .b = Color.init(0.55, 0.55, 0.55) } },
        .transform = Mat4.identity().scale(0.25, 0.25, 0.25).rotateY(1.5708),
    };
    const wall_material = Material{
        .pattern = wall_pattern,
        .ambient = 0,
        .diffuse = 0.4,
        .specular = 0,
        .reflective = 0.3,
    };

    const floor_pattern = Pattern{
        .pattern = .{ .checkers = .{ .a = Color.init(0.35, 0.35, 0.35), .b = Color.init(0.65, 0.65, 0.65) } },
        .transform = Mat4.identity().rotateY(0.31415),
    };
    const floor = Shape{
        .material = .{
            .pattern = floor_pattern,
            .specular = 0,
            .reflective = 0.4,
        },
        .geo = .{ .plane = .{} },
    };
    try world.objects.append(floor);

    const ceiling = Shape{
        .material = .{
            .color = Color.init(0.8, 0.8, 0.8),
            .ambient = 0.3,
            .specular = 0,
        },
        .transform = Mat4.identity().translate(0, 5, 0),
        .geo = .{ .plane = .{} },
    };
    try world.objects.append(ceiling);

    // west wall
    const west_wall = Shape{
        .material = wall_material,
        .transform = Mat4.identity().rotateY(1.5708).rotateZ(1.5708).translate(-5, 0, 0),
        .geo = .{ .plane = .{} },
    };
    try world.objects.append(west_wall);

    // east wall
    const east_wall = Shape{
        .material = wall_material,
        .transform = Mat4.identity().rotateY(1.5708).rotateZ(1.5708).translate(5, 0, 0),
        .geo = .{ .plane = .{} },
    };
    try world.objects.append(east_wall);

    // north wall
    const north_wall = Shape{
        .material = wall_material,
        .transform = Mat4.identity().rotateX(1.5708).translate(0, 0, 5),
        .geo = .{ .plane = .{} },
    };
    try world.objects.append(north_wall);

    // south wall
    const south_wall = Shape{
        .material = wall_material,
        .transform = Mat4.identity().rotateX(1.5708).translate(0, 0, -5),
        .geo = .{ .plane = .{} },
    };
    try world.objects.append(south_wall);

    // background balls
    try world.objects.append(Shape{
        .geo = .{ .sphere = .{} },
        .transform = Mat4.identity().scale(0.4, 0.4, 0.4).translate(4.6, 0.4, 1.0),
        .material = Material{
            .color = Color.init(0.8, 0.5, 0.3),
            .shininess = 50,
        },
    });

    try world.objects.append(Shape{
        .geo = .{ .sphere = .{} },
        .transform = Mat4.identity().scale(0.3, 0.3, 0.3).translate(4.7, 0.3, 0.4),
        .material = Material{
            .color = Color.init(0.9, 0.4, 0.5),
            .shininess = 50,
        },
    });

    try world.objects.append(Shape{
        .geo = .{ .sphere = .{} },
        .transform = Mat4.identity().scale(0.5, 0.5, 0.5).translate(-1, 0.5, 4.5),
        .material = Material{
            .color = Color.init(0.4, 0.9, 0.6),
            .shininess = 50,
        },
    });

    try world.objects.append(Shape{
        .geo = .{ .sphere = .{} },
        .transform = Mat4.identity().scale(0.3, 0.3, 0.3).translate(-1.7, 0.3, 4.7),
        .material = Material{
            .color = Color.init(0.4, 0.6, 0.9),
            .shininess = 50,
        },
    });

    // foreground balls

    // red sphere
    try world.objects.append(Shape{
        .geo = .{ .sphere = .{} },
        .transform = Mat4.identity().translate(-0.6, 1, 0.6),
        .material = Material{
            .color = Color.init(1.0, 0.3, 0.2),
            .specular = 0.4,
            .shininess = 5,
        },
    });

    // blue glass sphere
    try world.objects.append(Shape{
        .geo = .{ .sphere = .{} },
        .transform = Mat4.identity().scale(0.7, 0.7, 0.7).translate(0.6, 0.7, -0.6),
        .material = Material{
            .color = Color.init(0, 0, 0.2),
            .ambient = 0,
            .diffuse = 0.4,
            .specular = 0.9,
            .shininess = 300,
            .reflective = 0.9,
            .transparency = 0.9,
            .refractive_index = 1.5,
        },
    });

    // green glass sphere
    try world.objects.append(Shape{
        .geo = .{ .sphere = .{} },
        .transform = Mat4.identity().scale(0.5, 0.5, 0.5).translate(-0.7, 0.5, -0.8),
        .material = Material{
            .color = Color.init(0, 0.2, 0),
            .ambient = 0,
            .diffuse = 0.4,
            .specular = 0.9,
            .shininess = 300,
            .reflective = 0.9,
            .transparency = 0.9,
            .refractive_index = 1.5,
        },
    });

    var canvas = try camera.render(allocator, world);
    defer canvas.deinit();

    const dir: std.fs.Dir = std.fs.cwd();
    const file: std.fs.File = try dir.createFile("result.ppm", .{});
    defer file.close();

    try canvasToPPM(canvas, file.writer());
}
