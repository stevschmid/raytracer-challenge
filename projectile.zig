const std = @import("std");
const Tuple = @import("tuple.zig").Tuple;
const Canvas = @import("canvas.zig").Canvas;
const Color = @import("color.zig").Color;
const canvasToPPM = @import("ppm.zig").canvasToPPM;

const Projectile = struct {
    pos: Tuple,
    velocity: Tuple,
};

const Environment = struct {
    gravity: Tuple,
    wind: Tuple,
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
        .gravity = Tuple.initVector(0, -0.1, 0),
        .wind = Tuple.initVector(-0.01, 0, 0),
    };

    var p = Projectile{
        .pos = Tuple.initPoint(0, 1, 0),
        .velocity = Tuple.initVector(1, 1.8, 0).normalize().scale(11.25),
    };

    var canvas = try Canvas.init(allocator, 900, 550);
    defer canvas.deinit();

    var num_ticks: usize = 0;
    while (p.pos.y > 0.0) {
        std.debug.print("Tick {d:.2} {d:.2} {d:.2}\n", .{ p.pos.x, p.pos.y, p.pos.z });
        p = tick(p, e);

        const x = @floatToInt(usize, std.math.max(p.pos.x, 0.0));
        const y = @floatToInt(usize, std.math.max(@intToFloat(f32, canvas.height) - p.pos.y, 0.0));

        // // const y = @floatToInt(usize, @intToFloat(f32, canvas.height * std.math.clamp(p.pos.y / 5.0, 0.0, 5.0));

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
