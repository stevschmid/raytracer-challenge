const std = @import("std");
const vector = @import("vector.zig");
const Vec4 = vector.Vec4;
const Mat4 = @import("matrix.zig").Mat4;
const Canvas = @import("canvas.zig").Canvas;
const Color = @import("color.zig").Color;
const canvasToPPM = @import("ppm.zig").canvasToPPM;

const Sphere = @import("sphere.zig").Sphere;
const Ray = @import("ray.zig").Ray;
const intersect = @import("ray.zig").intersect;

const CanvasSize = 400;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var canvas = try Canvas.init(allocator, CanvasSize, CanvasSize);
    defer canvas.deinit();

    const color = Color.init(1, 0, 0);
    const shape = Sphere{
        .transform = Mat4.identity(),
    };
    const origin = vector.initPoint(0, 0, -5);

    const wall_z = 10.0;
    const wall_size: f32 = 7.0;
    const pixel_size = wall_size / @intToFloat(f32, CanvasSize);
    const half = 0.5 * wall_size;

    var y: usize = 0;
    while (y < canvas.height) : (y += 1) {
        const world_y = half - @intToFloat(f32, y) * pixel_size;

        var x: usize = 0;
        while (x < canvas.height) : (x += 1) {
            _ = 1;

            const world_x = -half + @intToFloat(f32, x) * pixel_size;
            const wall_pos = vector.initPoint(world_x, world_y, wall_z);
            const ray = Ray.init(origin, wall_pos.sub(origin).normalize());

            var xs = try intersect(allocator, shape, ray);
            defer xs.deinit();

            const hit = xs.hit();
            if (hit != null) {
                canvas.set(x, y, color);
            }
        }
    }

    const dir: std.fs.Dir = std.fs.cwd();
    const file: std.fs.File = try dir.createFile("/tmp/result.ppm", .{});
    defer file.close();

    try canvasToPPM(canvas, file.writer());
}
