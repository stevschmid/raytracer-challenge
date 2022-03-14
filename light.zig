const std = @import("std");

const Vec4 = @import("vector.zig").Vec4;
const initPoint = @import("vector.zig").initPoint;
const initVector = @import("vector.zig").initVector;

const Color = @import("color.zig").Color;

pub const PointLight = struct {
    const Self = @This();

    position: Vec4,
    intensity: Color,
};

test "A point has light as a position and intensity" {
    const intensity = Color.init(1, 1, 0);
    const position = initPoint(0, 0, 0);

    const light = PointLight{
        .intensity = intensity,
        .position = position,
    };

    try std.testing.expect(light.intensity.eql(intensity));
    try std.testing.expect(light.position.eql(position));
}
