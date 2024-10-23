const std = @import("std");

pub fn concatenate(comptime fmt: []const u8, float: f32) [*:0]const u8 {
    const len = comptime std.fmt.count(fmt, .{std.math.maxInt(i32)});
    var buf: [len:0]u8 = undefined;
    return std.fmt.bufPrintZ(&buf, fmt, .{@as(i32, @intFromFloat(float))}) catch "Error";
}
