pub export fn start() callconv(.c) noreturn {
    @import("root").main();
    exit(0);
}

pub fn exit(_: i32) noreturn {
    while (true) {}
}
