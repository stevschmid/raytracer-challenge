const std = @import("std");

const vector = @import("vector.zig");
const Vec4 = Vec4;
const initPoint = vector.initPoint;
const initVector = vector.initVector;

const Mat4 = @import("matrix.zig").Mat4;
const Canvas = @import("canvas.zig").Canvas;
const Color = @import("color.zig").Color;
const canvasToPPM = @import("ppm.zig").canvasToPPM;

const Sphere = @import("sphere.zig").Sphere;
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

    const floor = Sphere{
        .transform = Mat4.identity().scale(10, 0.01, 10),
        .material = Material{
            .color = Color.init(1, 0.9, 0.9),
            .specular = 0,
        },
    };
    try world.objects.append(floor);

    const left_wall = Sphere{
        .transform = Mat4.identity()
            .scale(10, 0.01, 10)
            .rotateX(std.math.pi / 2.0)
            .rotateY(-std.math.pi / 4.0)
            .translate(0, 0, 5),
        .material = floor.material,
    };
    try world.objects.append(left_wall);

    const right_wall = Sphere{
        .transform = Mat4.identity()
            .scale(10, 0.01, 10)
            .rotateX(std.math.pi / 2.0)
            .rotateY(std.math.pi / 4.0)
            .translate(0, 0, 5),
        .material = floor.material,
    };
    try world.objects.append(right_wall);

    const middle = Sphere{
        .transform = Mat4.identity().translate(-0.5, 1, 0.5),
        .material = Material{
            .color = Color.init(0.1, 1, 0.5),
            .diffuse = 0.7,
            .specular = 0.3,
        },
    };
    try world.objects.append(middle);

    const right = Sphere{
        .transform = Mat4.identity()
            .scale(0.5, 0.5, 0.5)
            .translate(1.5, 0.5, -0.5),
        .material = Material{
            .color = Color.init(0.5, 1, 0.1),
            .diffuse = 0.7,
            .specular = 0.3,
        },
    };
    try world.objects.append(right);

    const left = Sphere{
        .transform = Mat4.identity()
            .scale(0.33, 0.33, 0.33)
            .translate(-1.5, 0.33, -0.75),
        .material = Material{
            .color = Color.init(1, 0.8, 0.1),
            .diffuse = 0.7,
            .specular = 0.3,
        },
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