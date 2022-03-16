const std = @import("std");
const vector = @import("vector.zig");
const Vec4 = vector.Vec4;
const Mat4 = @import("matrix.zig").Mat4;
const Canvas = @import("canvas.zig").Canvas;
const Color = @import("color.zig").Color;
const canvasToPPM = @import("ppm.zig").canvasToPPM;

fn addPointToCanvas(canvas: *Canvas, point: Vec4) void {
    const w = @intToFloat(f64, canvas.width);
    const h = @intToFloat(f64, canvas.height);

    // 0, 0 is middle, 0.5, 0.5 is edge
    const x = 0.5 + point.x;
    const y = 0.5 + point.y;

    canvas.set(@floatToInt(usize, x * w), @floatToInt(usize, (1.0 - y) * h), Color.init(1, 1, 1));
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var canvas = try Canvas.init(allocator, 100, 100);
    defer canvas.deinit();

    var cursor = vector.initVector(0, 0.3, 0);

    var rot = Mat4.identity().rotateZ(-2.0 * std.math.pi / 12.0);

    var i: usize = 0;
    while (i < 12) : (i += 1) {
        addPointToCanvas(&canvas, cursor);
        cursor = rot.multVec(cursor);
    }

    const dir: std.fs.Dir = std.fs.cwd();
    const file: std.fs.File = try dir.createFile("/tmp/result.ppm", .{});
    defer file.close();

    try canvasToPPM(canvas, file.writer());
}
