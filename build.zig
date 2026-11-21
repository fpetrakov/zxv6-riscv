const std = @import("std");

const uprogs = [_][]const u8{
    "cat",   "echo", "forktest", "grep",     "init",      "kill",  "ln", "ls",
    "mkdir", "rm",   "sh",       "stressfs", "usertests", "grind", "wc", "zombie",
};

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const cpus = b.option(u8, "cpus", "QEMU -smp (default 3)") orelse 3;

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .riscv64,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_features_sub = std.Target.riscv.featureSet(&.{.relax}),
    });

    const common = b.createModule(.{ .root_source_file = b.path("src/common.zig") });

    const kernel = b.addExecutable(.{
        .name = "kernel",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/kernel/main.zig"),
            .target = target,
            .optimize = optimize,
            .strip = false,
            .code_model = .medium,
            .pic = false,
            .red_zone = false,
            .omit_frame_pointer = false,
            .stack_protector = false,
            .single_threaded = true,
            .unwind_tables = .none,
            .error_tracing = false,
            .imports = &.{.{ .name = "common", .module = common }},
        }),
    });

    kernel.setLinkerScript(b.path("src/kernel/kernel.ld"));
    kernel.link_z_max_page_size = 4096;
    kernel.link_gc_sections = false;
    kernel.entry = .disabled;
    b.installArtifact(kernel);

    const mkfs = b.addExecutable(.{
        .name = "mkfs",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/mkfs.zig"),
            .target = b.graph.host,
            .optimize = .safe,
            .imports = &.{.{ .name = "common", .module = common }},
        }),
    });

    const ulib = b.createModule(.{
        .root_source_file = b.path("src/user/ulib.zig"),
        .target = target,
        .optimize = optimize,
        .code_model = .medium,
        .pic = false,
        .red_zone = false,
        .omit_frame_pointer = false,
        .stack_protector = false,
        .single_threaded = true,
        .strip = false,
        .imports = &.{.{ .name = "common", .module = common }},
    });

    const mk = b.addRunArtifact(mkfs);
    const fs_img = mk.addOutputFileArg("fs.img");
    mk.addFileArg(b.path("README"));

    for (uprogs) |name| {
        const exe = b.addExecutable(.{
            .name = b.fmt("_{s}", .{name}), // mkfs strips the leading '_'
            .root_module = b.createModule(.{
                .root_source_file = b.path(b.fmt("src/user/{s}.zig", .{name})),
                .target = target,
                .optimize = optimize,
                .code_model = .medium,
                .pic = false,
                .red_zone = false,
                .omit_frame_pointer = false,
                .stack_protector = false,
                .single_threaded = true,
                .strip = false,
                .imports = &.{.{ .name = "ulib", .module = ulib }},
            }),
        });
        exe.setLinkerScript(b.path("src/user/user.ld"));
        exe.link_z_max_page_size = 4096;
        exe.link_gc_sections = false;
        exe.entry = .{ .symbol_name = "start" };
        mk.addFileArg(exe.getEmittedBin());
    }
    b.getInstallStep().dependOn(&b.addInstallFile(fs_img, "fs.img").step);

    const qemu = qemuRun(b, kernel, fs_img, cpus);
    b.step("qemu", "Run xv6 in QEMU").dependOn(&qemu.step);

    const gdb = qemuRun(b, kernel, fs_img, cpus);
    gdb.addArgs(&.{ "-S", "-gdb", "tcp::26000" });
    b.step("qemu-gdb", "Run in QEMU, wait for gdb on :26000").dependOn(&gdb.step);
}

fn qemuRun(b: *std.Build, kernel: *std.Build.Step.Compile, fs_img: std.Build.LazyPath, cpus: u8) *std.Build.Step.Run {
    const q = b.addSystemCommand(&.{ "qemu-system-riscv64", "-machine", "virt", "-bios", "none", "-kernel" });
    q.addArtifactArg(kernel);
    q.addArgs(&.{ "-m", "128M", "-smp" });
    q.addArg(b.fmt("{d}", .{cpus}));
    q.addArgs(&.{ "-nographic", "-global", "virtio-mmio.force-legacy=false", "-drive" });
    q.addPrefixedFileArg("if=none,format=raw,id=x0,file=", fs_img);
    q.addArgs(&.{ "-device", "virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0" });
    q.stdio = .inherit;
    return q;
}
