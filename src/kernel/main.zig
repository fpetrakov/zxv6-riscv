comptime {
    _ = @import("entry.zig");
    _ = @import("start.zig");
}

const std = @import("std");
const Io = std.Io;
const proc = @import("proc.zig");
const console = @import("console.zig");

const started = 0;

const UART0: *volatile u8 = @ptrFromInt(0x10000000);
pub fn main(_: std.process.Init) !void {
    for ("A") |c| UART0.* = c;
    while (true) {}
}
