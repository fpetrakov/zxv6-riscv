const Cpu = @import("proc.zig").Cpu;

// Mutual exclusion lock.
pub const SpinLock = struct {
    locked: usize, // Is the lock held?

    // For debugging:
    name: *u8,
    cpu: *Cpu,
};
