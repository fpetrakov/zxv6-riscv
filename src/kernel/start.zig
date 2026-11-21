const main = @import("main.zig").main;
const r = @import("riscv.zig");
const ncpu = @import("param.zig").ncpu;

export var stack0: [4096 * ncpu]u8 align(16) = undefined;

export fn start() void {
    // set M Previous Privilege mode to Supervisor, for mret.
    var x = r.mstatus.read();
    x &= ~@backingInt(r.mstatus.mpp_mask);
    x |= @backingInt(r.mstatus.mpp_s);
    r.mstatus.write(x);

    // set M Exception Program Counter to main, for mret.
    r.mepc.write(@intFromPtr(&main));

    // disable paging for now.
    r.satp.write(0);

    // delegate all interrupts and exceptions to supervisor mode.
    r.medeleg.write(0xffff);
    r.medeleg.write(0xffff);
    r.sie.write(r.sie.read() | @backingInt(r.sie.seie) | @backingInt(r.sie.stie));

    // configure Physical Memory Protection to give supervisor mode
    // access to all of physical memory.
    r.pmpaddr0.write(0x3fffffffffffff);
    r.pmpcfg0.write(0xf);

    // enable hardware updates of page table A and D bits
    r.menvcfg.write(r.menvcfg.read() | @backingInt(r.menvcfg.adue));

    // ask for clock interrupts.
    timerInit();

    // keep each CPU's hartid in its tp register, for cpuId().
    const id = r.mhartid.read();
    r.tp.write(id);

    // switch to supervisor mode and jump to main().
    asm volatile ("mret");
}

// ask each hart to generate timer interrupts.
fn timerInit() void {
    // enable the sstc extension (i.e. stimecmp).
    r.menvcfg.write(r.menvcfg.read() | @backingInt(r.menvcfg.stce));

    // allow supervisor to use stimecmp and time.
    r.mcounteren.write(r.mcounteren.read() | 2);

    // ask for the very first timer interrupt.
    r.stimecmp.write(r.time.read() + 1000000);
}
