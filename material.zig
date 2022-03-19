const std = @import("std");

const Color = @import("color.zig").Color;
const Pattern = @import("pattern.zig").Pattern;

pub const Material = struct {
    const Self = @This();

    color: Color = Color.init(1, 1, 1),
    ambient: f64 = 0.1,
    diffuse: f64 = 0.9,
    specular: f64 = 0.9,
    shininess: f64 = 200.0,
    reflective: f64 = 0.0,
    transparency: f64 = 0.0,
    refractive_index: f64 = 1.0,
    pattern: ?Pattern = null,
};

test "The default material" {
    const m = Material{};

    try std.testing.expect(m.color.eql(Color.init(1, 1, 1)));
    try std.testing.expectEqual(@as(f64, 0.1), m.ambient);
    try std.testing.expectEqual(@as(f64, 0.9), m.diffuse);
    try std.testing.expectEqual(@as(f64, 0.9), m.specular);
    try std.testing.expectEqual(@as(f64, 200.0), m.shininess);
    try std.testing.expectEqual(@as(f64, 0.0), m.reflective);
    try std.testing.expectEqual(@as(f64, 0.0), m.transparency);
    try std.testing.expectEqual(@as(f64, 1.0), m.refractive_index);
}

test "Can have a pattern" {
    const p = Pattern{ .pattern = .{ .stripe = .{ .a = Color.White, .b = Color.Black } } };
    const m = Material{ .pattern = p };

    try std.testing.expectEqual(p, m.pattern.?);
}
