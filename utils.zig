const std = @import("std");

pub inline fn epsilonEq(a: anytype, b: @TypeOf(a)) bool {
    return std.math.approxEqAbs(@TypeOf(a), a, b, std.math.epsilon(@TypeOf(a)));
}

pub fn expectEpsilonEq(expected: anytype, actual: @TypeOf(expected)) !void {
    try std.testing.expectApproxEqAbs(expected, actual, std.math.epsilon(@TypeOf(expected)));
}

pub fn expectMatrixApproxEq(expected: anytype, actual: @TypeOf(expected)) !void {
    for (expected.mat) |row_values, row| {
        for (row_values) |_, col| {
            // tolerance of 0.00001 since the book shows max 5 digits
            try std.testing.expectApproxEqAbs(expected.mat[row][col], actual.mat[row][col], 0.00001);
        }
    }
}

pub fn expectVec4ApproxEq(expected: anytype, actual: @TypeOf(expected)) !void {
    try std.testing.expectApproxEqAbs(expected.x, actual.x, 0.00001);
    try std.testing.expectApproxEqAbs(expected.y, actual.y, 0.00001);
    try std.testing.expectApproxEqAbs(expected.z, actual.z, 0.00001);
    try std.testing.expectApproxEqAbs(expected.w, actual.w, 0.00001);
}

pub fn expectColorApproxEq(expected: anytype, actual: @TypeOf(expected)) !void {
    try std.testing.expectApproxEqAbs(expected.red, actual.red, 0.0001);
    try std.testing.expectApproxEqAbs(expected.green, actual.green, 0.0001);
    try std.testing.expectApproxEqAbs(expected.blue, actual.blue, 0.0001);
}
