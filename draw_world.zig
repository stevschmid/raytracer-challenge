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

const CanvasSize = 400;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var world = World.init(allocator);
    defer world.deinit();

    const gradient_pattern = Pattern{
        .pattern = .{ .gradient = .{ .a = Color.init(1, 1, 0.9), .b = Color.init(0.5, 0.7, 1) } },
    };
    // const ring_pattern = Pattern{
    //     .pattern = .{ .ring = .{ .a = Color.init(0, 1, 0), .b = Color.init(1, 0, 1) } },
    // };
    const checkers_pattern = Pattern{
        .pattern = .{ .checkers = .{ .a = Color.init(0, 1, 0), .b = Color.init(0, 0.8, 0) } },
    };
    const stripe_pattern = Pattern{
        .pattern = .{ .stripe = .{ .a = Color.init(0.5, 1, 0.1), .b = Color.init(1, 0.5, 0.1) } },
        .transform = Mat4.identity().scale(0.2, 0.2, 0.2)
            .rotateY(std.math.pi * 0.25)
            .rotateZ(std.math.pi * 0.25),
    };

    const floor = Shape{
        .material = Material{
            .pattern = checkers_pattern,
            .color = Color.init(1, 0.9, 0.9),
            .specular = 0,
        },
        .geo = .{ .plane = .{} },
    };
    try world.objects.append(floor);

    const middle = Shape{
        .transform = Mat4.identity().translate(-0.5, 1, 0.5),
        .material = Material{
            .pattern = gradient_pattern,
            .color = Color.init(0.1, 1, 0.5),
            .diffuse = 0.7,
            .specular = 0.3,
        },
        .geo = .{ .sphere = .{} },
    };
    try world.objects.append(middle);

    const right = Shape{
        .transform = Mat4.identity()
            .scale(0.5, 0.5, 0.5)
            .translate(1.5, 0.5, -0.5),
        .material = Material{
            .color = Color.init(0.5, 1, 0.1),
            .diffuse = 0.7,
            .pattern = stripe_pattern,
            .specular = 0.3,
        },
        .geo = .{ .sphere = .{} },
    };
    try world.objects.append(right);

    const left = Shape{
        .transform = Mat4.identity()
            .scale(0.33, 0.33, 0.33)
            .translate(-1.5, 0.33, -0.75),
        .material = Material{
            .color = Color.init(1, 0.8, 0.1),
            .diffuse = 0.7,
            .specular = 0.3,
        },
        .geo = .{ .sphere = .{} },
    };
    try world.objects.append(left);

    world.light = PointLight{
        .position = initPoint(-10, 10, -10),
        .intensity = Color.White,
    };

    const from = initPoint(0, 1.5, -5);
    const to = initPoint(0, 1, 0);
    const up = initVector(0, 1, 0);

    var camera = Camera.init(400, 200, std.math.pi / 3.0);
    camera.transform = calc.viewTransform(from, to, up);

    var canvas = try camera.render(allocator, world);
    defer canvas.deinit();

    const dir: std.fs.Dir = std.fs.cwd();
    const file: std.fs.File = try dir.createFile("/tmp/result.ppm", .{});
    defer file.close();

    try canvasToPPM(canvas, file.writer());
}
