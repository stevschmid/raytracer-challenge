const std = @import("std");

const Mat4 = @import("matrix.zig").Mat4;
const Vec4 = @import("vector.zig").Vec4;
const initPoint = @import("vector.zig").initPoint;
const initVector = @import("vector.zig").initVector;

const Color = @import("color.zig").Color;
const Sphere = @import("sphere.zig").Sphere;

const Ray = @import("ray.zig").Ray;
const Material = @import("material.zig").Material;
const PointLight = @import("light.zig").PointLight;

pub const World = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    objects: std.ArrayList(Sphere),
    light: PointLight,

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .objects = std.ArrayList(Sphere).init(allocator),
            .light = .{},
        };
    }

    pub fn initDefault(allocator: std.mem.Allocator) !Self {
        var world = init(allocator);
        world.light = PointLight{
            .position = initPoint(-10, 10, -10),
            .intensity = Color.White,
        };

        const s1 = Sphere{
            .material = .{
                .color = Color.init(0.8, 1.0, 0.6),
                .diffuse = 0.7,
                .specular = 0.2,
            },
        };
        try world.objects.append(s1);

        const s2 = Sphere{
            .transform = Mat4.identity().scale(0.5, 0.5, 0.5),
        };
        try world.objects.append(s2);

        return world;
    }

    pub fn deinit(self: *Self) void {
        self.objects.deinit();
    }
};

const alloc = std.testing.allocator;

test "The default world" {
    var w = try World.initDefault(alloc);
    defer w.deinit();

    try std.testing.expectEqual(w.objects.items[0].material.color, Color.init(0.8, 1.0, 0.6));
    try std.testing.expectEqual(w.objects.items[1].transform, Mat4.identity().scale(0.5, 0.5, 0.5));
    try std.testing.expectEqual(w.light.position, initPoint(-10, 10, -10));
    try std.testing.expectEqual(w.light.intensity, Color.White);
}
