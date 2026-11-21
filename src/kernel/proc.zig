const riscv = @import("riscv.zig");
const PageTable = riscv.PageTable;
const SpinLock = @import("spinlock.zig").SpinLock;
const param = @import("param.zig");

// Per-process state
pub const Proc = struct {
    lock: SpinLock,

    // p->lock must be held when using these:
    state: ProcState, // Process state
    chan: *?anyopaque = null, // If non-null, sleeping on chan
    killed: bool, // If true, have been killed
    xstate: u32, // Exit status to be returned to parent's wait
    pid: u32, // Process ID

    // wait_lock must be held when using this:
    parent: *Proc, // Parent process

    // these private to the address, so p->lock need to be held.
    kstack: u64, // Virtual address of kernel stack
    sz: u64, // Size of process memory (bytes)
    pagetable: PageTable,
    trapframe: *TrapFrame,
    context: Context,
};

const ProcState = enum {
    unused,
    used,
    sleeping,
    runnable,
    running,
    zombie,
};

// per-process data fro the trap handling code in trampoline.zig
// sits in a page by itself just under the trampoline page in the
// user page table. not specially mapped in the kernel page table.
// uservec in trampoline.zig saves user registers in the trapframe,
// then initializes registers from the trapframe's
// kernel_sp, kernel_hartid, kernel_satp, and jumps to the kernel_trap.
// prepare return() and userret in trampoline.zig set up
// the trapframe's kernel_*, restore user registers from the
// trapframe, switch to the user page table, and enter user space.
const TrapFrame = struct {
    kernel_satp: u64,
    kernel_sp: u64,
    kernel_trap: u64,
    epc: u64,
    kernel_hartid: u64,
    ra: u64,
    sp: u64,
    gp: u64,
    tp: u64,
    t0: u64,
    t1: u64,
    t2: u64,
    s0: u64,
    s1: u64,
    a0: u64,
    a1: u64,
    a2: u64,
    a3: u64,
    a4: u64,
    a5: u64,
    a6: u64,
    a7: u64,
    s2: u64,
    s3: u64,
    s4: u64,
    s5: u64,
    s6: u64,
    s7: u64,
    s8: u64,
    s9: u64,
    s10: u64,
    s11: u64,
    t3: u64,
    t4: u64,
    t5: u64,
    t6: u64,
};

// Per-CPU state.
pub const Cpu = struct {
    proc: ?*Proc = null, // The process running on this cpu, or null.
    context: Context = .{}, // swtch() here to enter scheduler().
    noff: i32 = 0, // Depth of push_off() nesting.
    intena: i32 = 0, // Were interrupts enabled before push_off()?
};

pub var cpus: [param.ncpu]Cpu = @splat(Cpu{});

const Context = struct {
    ra: u64,
    sp: u64,

    // callee-saved
    s0: u64,
    s1: u64,
    s2: u64,
    s3: u64,
    s4: u64,
    s5: u64,
    s6: u64,
    s7: u64,
    s8: u64,
    s9: u64,
    s10: u64,
    s11: u64,
};

pub fn cpuId() u64 {
    const id = riscv.r_tp();
    return id;
}

// pub fn userInit() void {
//     var p = Proc{};
// }
