const std = @import("std");
const vector = @import("vector.zig");
const Vec4 = vector.Vec4;
const Canvas = @import("canvas.zig").Canvas;
const Color = @import("color.zig").Color;
const canvasToPPM = @import("ppm.zig").canvasToPPM;

const Projectile = struct {
    pos: Vec4,
    velocity: Vec4,
};

const Environment = struct {
    gravity: Vec4,
    wind: Vec4,
};

fn tick(proj: Projectile, env: Environment) Projectile {
    return .{
        .pos = proj.pos.add(proj.velocity),
        .velocity = proj.velocity.add(env.gravity).add(env.wind),
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const e = Environment{
        .gravity = vector.initVector(0, -0.1, 0),
        .wind = vector.initVector(-0.01, 0, 0),
    };

    var p = Projectile{
        .pos = vector.initPoint(0, 1, 0),
        .velocity = vector.initVector(1, 1.8, 0).normalize().scale(11.25),
    };

    var canvas = try Canvas.init(allocator, 900, 550);
    defer canvas.deinit();

    var num_ticks: usize = 0;
    while (p.pos.y > 0.0) {
        std.debug.print("Tick {d:.2} {d:.2} {d:.2}\n", .{ p.pos.x, p.pos.y, p.pos.z });
        p = tick(p, e);

        const x = @floatToInt(usize, std.math.max(p.pos.x, 0.0));
        const y = @floatToInt(usize, std.math.max(@intToFloat(f64, canvas.height) - p.pos.y, 0.0));

        // // const y = @floatToInt(usize, @intToFloat(f64, canvas.height * std.math.clamp(p.pos.y / 5.0, 0.0, 5.0));

        if (x < canvas.width and y < canvas.height) {
            canvas.set(x, y, Color.init(1, 0, 0));
        }

        num_ticks += 1;
    }

    const dir: std.fs.Dir = std.fs.cwd();
    const file: std.fs.File = try dir.createFile("/tmp/result.ppm", .{});
    defer file.close();

    try canvasToPPM(canvas, file.writer());

    std.debug.print("Ticks required to hit ground: {}\n", .{num_ticks});
}
