const std = @import("std");

const Color = @import("color.zig").Color;

const Canvas = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    width: usize,
    height: usize,
    pixels: []Color,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Self {
        const pixels = try allocator.alloc(Color, width * height);
        for (pixels) |*p| p.* = std.mem.zeroes(Color);

        return Self{
            .allocator = allocator,
            .width = width,
            .height = height,
            .pixels = pixels,
        };
    }

    pub fn set(self: *Self, x: usize, y: usize, color: Color) void {
        const idx = y * self.width + x;
        std.debug.assert(idx < self.pixels.len);
        self.pixels[idx] = color;
    }

    pub fn at(self: Self, x: usize, y: usize) Color {
        const idx = y * self.width + x;
        std.debug.assert(idx < self.pixels.len);
        return self.pixels[idx];
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.pixels);
    }
};

const alloc = std.testing.allocator;

test "creating a canvas" {
    var c = try Canvas.init(alloc, 10, 20);
    defer c.deinit();

    try std.testing.expectEqual(@as(usize, 10), c.width);
}

test "writing pixels to canvas" {
    var c = try Canvas.init(alloc, 10, 20);
    defer c.deinit();

    const red = Color.init(1, 0, 0);

    c.set(2, 3, red);
    try std.testing.expect(c.at(2, 3).eql(red));
}
