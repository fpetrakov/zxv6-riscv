const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    const f = try std.Io.Dir.cwd().createFile(init.io, args[1], .{});
    f.close(init.io);
}
