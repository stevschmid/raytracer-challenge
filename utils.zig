const std = @import("std");

pub inline fn epsilonEq(a: anytype, b: @TypeOf(a)) bool {
    return std.math.approxEqAbs(@TypeOf(a), a, b, std.math.epsilon(@TypeOf(a)));
}

pub fn expectEpsilonEq(expected: anytype, actual: @TypeOf(expected)) !void {
    try std.testing.expectApproxEqAbs(expected, actual, std.math.epsilon(@TypeOf(expected)));
}
