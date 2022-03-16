const std = @import("std");

const Color = @import("color.zig").Color;
const Canvas = @import("canvas.zig").Canvas;

inline fn byteColorValue(val: f64) u8 {
    const v = std.math.clamp(val * 256.0, 0.0, 255.0);
    return @floatToInt(u8, v);
}

pub fn canvasToPPM(canvas: Canvas, anywriter: anytype) !void {
    var buffered_writer = std.io.bufferedWriter(anywriter);
    var writer = buffered_writer.writer();

    try std.fmt.format(writer, "P3\n", .{});
    try std.fmt.format(writer, "{} {}\n", .{ canvas.width, canvas.height });
    try std.fmt.format(writer, "255\n", .{});

    var y: usize = 0;
    while (y < canvas.height) : (y += 1) {
        var x: usize = 0;
        while (x < canvas.width) : (x += 1) {
            if (x > 0) {
                if (x % 5 == 0) { // newline so we don't exceed 70 chars per line
                    try writer.writeByte('\n');
                } else {
                    try writer.writeByte(' ');
                }
            }

            const p = canvas.at(x, y);
            try std.fmt.format(writer, "{} {} {}", .{ byteColorValue(p.red), byteColorValue(p.green), byteColorValue(p.blue) });
        }
        try writer.writeByte('\n');
    }

    try buffered_writer.flush();
}

var buffer: [4096]u8 = undefined;
const allocator = std.testing.allocator;

test "writes ppm" {
    var c = try Canvas.init(allocator, 5, 3);
    defer c.deinit();

    var fbs = std.io.fixedBufferStream(&buffer);
    try canvasToPPM(c, fbs.writer());

    const expected =
        \\P3
        \\5 3
        \\255
        \\0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
        \\0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
        \\0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
        \\
    ;

    try std.testing.expectEqualStrings(expected, fbs.getWritten());
}

test "writes ppm with proper colors" {
    var c = try Canvas.init(allocator, 5, 3);
    defer c.deinit();

    c.set(0, 0, Color.init(1.5, 0, 0));
    c.set(2, 1, Color.init(0, 0.5, 0));
    c.set(4, 2, Color.init(-0.5, 0, 1));

    var fbs = std.io.fixedBufferStream(&buffer);
    try canvasToPPM(c, fbs.writer());

    const expected =
        \\P3
        \\5 3
        \\255
        \\255 0 0 0 0 0 0 0 0 0 0 0 0 0 0
        \\0 0 0 0 0 0 0 128 0 0 0 0 0 0 0
        \\0 0 0 0 0 0 0 0 0 0 0 0 0 0 255
        \\
    ;

    try std.testing.expectEqualStrings(expected, fbs.getWritten());
}

test "splitting long lines in PPM files" {
    var c = try Canvas.init(allocator, 9, 2);
    defer c.deinit();

    for (c.pixels) |*p| {
        p.* = Color.init(1, 0.8, 0.6);
    }

    var fbs = std.io.fixedBufferStream(&buffer);
    try canvasToPPM(c, fbs.writer());

    const expected =
        \\P3
        \\9 2
        \\255
        \\255 204 153 255 204 153 255 204 153 255 204 153 255 204 153
        \\255 204 153 255 204 153 255 204 153 255 204 153
        \\255 204 153 255 204 153 255 204 153 255 204 153 255 204 153
        \\255 204 153 255 204 153 255 204 153 255 204 153
        \\
    ;

    try std.testing.expectEqualStrings(expected, fbs.getWritten());
}
