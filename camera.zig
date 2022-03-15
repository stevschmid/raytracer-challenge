const std = @import("std");

const Vec4 = @import("vector.zig").Vec4;
const initPoint = @import("vector.zig").initPoint;
const initVector = @import("vector.zig").initVector;

const Mat4 = @import("matrix.zig").Mat4;

const Ray = @import("ray.zig").Ray;
const Color = @import("color.zig").Color;
const World = @import("world.zig").World;
const Canvas = @import("canvas.zig").Canvas;

const calc = @import("calc.zig");
const utils = @import("utils.zig");

pub const Camera = struct {
    const Self = @This();

    hsize: usize,
    vsize: usize,
    field_of_view: f32,
    half_width: f32,
    half_height: f32,
    pixel_size: f32,

    transform: Mat4 = Mat4.identity(),

    pub fn init(hsize: usize, vsize: usize, field_of_view: f32) Self {
        const half_view = std.math.tan(field_of_view * 0.5);
        const aspect = @intToFloat(f32, hsize) / @intToFloat(f32, vsize);

        const half_width = if (aspect >= 1.0) half_view else half_view * aspect;
        const half_height = if (aspect < 1.0) half_view else half_view / aspect;

        const pixel_size = (2.0 * half_width) / @intToFloat(f32, hsize);

        return Self{
            .hsize = hsize,
            .vsize = vsize,
            .field_of_view = field_of_view,
            .half_width = half_width,
            .half_height = half_height,
            .pixel_size = pixel_size,
        };
    }

    pub fn rayForPixel(self: Self, x: usize, y: usize) Ray {
        // the offset from the edge of the canvas to the pixel's center
        const x_offset = (@intToFloat(f32, x) + 0.5) * self.pixel_size;
        const y_offset = (@intToFloat(f32, y) + 0.5) * self.pixel_size;

        // the untransformed coordinates of the pixel in world space
        // (remember that the camera looks toward -z, so +x is to the *left*)
        const world_x = self.half_width - x_offset;
        const world_y = self.half_height - y_offset;

        // using the camera matrix, transform the canvas point and origin
        // and then compute the ray's direction vector
        // (remember that the canvas iat z=-1)

        const inv = self.transform.inverse();
        const pixel = inv.multVec(initPoint(world_x, world_y, -1));
        const origin = inv.multVec(initPoint(0, 0, 0));

        const direction = pixel.sub(origin).normalize();

        return Ray{
            .origin = origin,
            .direction = direction,
        };
    }

    pub fn render(self: Self, allocator: std.mem.Allocator, world: World) !Canvas {
        var canvas = try Canvas.init(allocator, self.hsize, self.vsize);

        var y: usize = 0;
        while (y < self.vsize) : (y += 1) {
            // const world_y = half - @intToFloat(f32, y) * pixel_size;
            var x: usize = 0;
            while (x < self.hsize) : (x += 1) {
                const ray = self.rayForPixel(x, y);
                const color = try calc.worldColorAt(allocator, world, ray);
                canvas.set(x, y, color);
            }
        }

        return canvas;
    }
};

test "Constructing a camera" {
    const c = Camera.init(160, 120, 0.5 * std.math.pi);
    try std.testing.expectEqual(@as(usize, 160), c.hsize);
    try std.testing.expectEqual(@as(usize, 120), c.vsize);
    try std.testing.expectEqual(@as(f32, 0.5 * std.math.pi), c.field_of_view);
}

test "The pixel size for a horizontal canvas" {
    const c = Camera.init(200, 125, 0.5 * std.math.pi);
    try std.testing.expectEqual(@as(f32, 0.01), c.pixel_size);
}

test "The pixel size for a vertical canvas" {
    const c = Camera.init(125, 200, 0.5 * std.math.pi);
    try std.testing.expectEqual(@as(f32, 0.01), c.pixel_size);
}

test "Constructing a ray through the center of the canvas" {
    const c = Camera.init(201, 101, std.math.pi * 0.5);
    const r = c.rayForPixel(100, 50);

    try utils.expectVec4ApproxEq(initPoint(0, 0, 0), r.origin);
    try utils.expectVec4ApproxEq(initVector(0, 0, -1), r.direction);
}

test "Constructing a ray through a corner of the canvas" {
    const c = Camera.init(201, 101, std.math.pi * 0.5);
    const r = c.rayForPixel(0, 0);

    try utils.expectVec4ApproxEq(initPoint(0, 0, 0), r.origin);
    try utils.expectVec4ApproxEq(initVector(0.66519, 0.33259, -0.66851), r.direction);
}

test "Constructing a ray when the camera is transformed" {
    var c = Camera.init(201, 101, std.math.pi * 0.5);
    c.transform = Mat4.identity().translate(0, -2, 5).rotateY(std.math.pi / 4.0);

    const r = c.rayForPixel(100, 50);

    try utils.expectVec4ApproxEq(initPoint(0, 2, -5), r.origin);
    try utils.expectVec4ApproxEq(initVector(std.math.sqrt(2.0) / 2.0, 0, -std.math.sqrt(2.0) / 2.0), r.direction);
}

const alloc = std.testing.allocator;

test "Rendering a world with a camera" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    const from = initPoint(0, 0, -5);
    const to = initPoint(0, 0, 0);
    const up = initVector(0, 1, 0);

    var c = Camera.init(11, 11, std.math.pi * 0.5);
    c.transform = calc.viewTransform(from, to, up);

    var image = try c.render(alloc, w);
    defer image.deinit();

    try utils.expectColorApproxEq(Color.init(0.38066, 0.47583, 0.2855), image.at(5, 5));
}
