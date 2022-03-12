const std = @import("std");
const Tuple = @import("tuple.zig").Tuple;

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

pub fn main() void {
    const e = Environment{
        .gravity = Tuple.initVector(0, -0.1, 0),
        .wind = Tuple.initVector(-0.01, 0, 0),
    };

    var p = Projectile{
        .pos = Tuple.initPoint(0, 1, 0),
        .velocity = Tuple.initVector(1, 1, 0).normalize(),
    };

    var num_ticks: usize = 0;
    while (p.pos.y > 0.0) {
        std.debug.print("Tick {d:.2} {d:.2} {d:.2}\n", .{ p.pos.x, p.pos.y, p.pos.z });
        p = tick(p, e);
        num_ticks += 1;
    }

    std.debug.print("Ticks required to hit ground: {}\n", .{num_ticks});
}
