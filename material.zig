const std = @import("std");

const Color = @import("color.zig").Color;

pub const Material = struct {
    const Self = @This();

    color: Color = Color.init(1, 1, 1),
    ambient: f32 = 0.1,
    diffuse: f32 = 0.9,
    specular: f32 = 0.9,
    shininess: f32 = 200.0,
};

test "The default material" {
    const m = Material{};

    try std.testing.expect(m.color.eql(Color.init(1, 1, 1)));
    try std.testing.expectEqual(@as(f32, 0.1), m.ambient);
    try std.testing.expectEqual(@as(f32, 0.9), m.diffuse);
    try std.testing.expectEqual(@as(f32, 0.9), m.specular);
    try std.testing.expectEqual(@as(f32, 200.0), m.shininess);
}
