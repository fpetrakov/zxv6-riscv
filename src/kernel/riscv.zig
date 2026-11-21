pub const PageTable = *[512]u64;

// Machine Status Register, mstatus
pub const mstatus = enum(u64) {
    mpp_mask = 3 << 11,
    mpp_m = 3 << 1,
    mpp_s = 1 << 1,
    mpp_u = 0 << 11,

    pub inline fn read() u64 {
        return asm volatile (
            \\csrr %[ret], mstatus
            : [ret] "=r" (-> u64),
        );
    }
    pub inline fn write(x: u64) void {
        asm volatile (
            \\csrw mstatus, %[x]
            :
            : [x] "r" (x),
        );
    }
};

pub const mepc = enum {
    pub inline fn write(x: u64) void {
        asm volatile (
            \\csrw mepc, %[x]
            :
            : [x] "r" (x),
        );
    }
};

// read and write tp, the thread pointer, which xc6 uses to hold
// this core's hartid (core number), the index into cpus[]
pub inline fn r_tp() u64 {
    return asm volatile (
        \\mv %[ret], tp
        : [ret] "=r" (-> u64),
    );
}

// supervisor address translation and protection;
// holds the address of the page table.
pub const satp = enum {
    pub inline fn read() u64 {
        return asm volatile (
            \\csrr %[ret], satp
            : [ret] "=r" (-> u64),
        );
    }
    pub inline fn write(x: u64) void {
        asm volatile (
            \\csrw satp, %[x]
            :
            : [x] "r" (x),
        );
    }
};

pub const medeleg = enum {
    pub inline fn write(x: u64) void {
        asm volatile (
            \\csrw medeleg, %[x]
            :
            : [x] "r" (x),
        );
    }
};

// Supervisor Interrupt Enable
pub const sie = enum(u64) {
    seie = 1 << 9, // external
    stie = 1 << 5, // timer

    pub inline fn read() u64 {
        return asm volatile (
            \\csrr %[ret], sie
            : [ret] "=r" (-> u64),
        );
    }

    pub inline fn write(x: u64) void {
        asm volatile (
            \\csrw sie, %[x]
            :
            : [x] "r" (x),
        );
    }
};

pub const pmpaddr0 = enum {
    pub inline fn write(x: u64) void {
        asm volatile (
            \\csrw pmpaddr0, %[x]
            :
            : [x] "r" (x),
        );
    }
};

// Physical Memory Protection
pub const pmpcfg0 = enum {
    pub inline fn write(x: u64) void {
        asm volatile (
            \\csrw pmpcfg0, %[x]
            :
            : [x] "r" (x),
        );
    }
};

// Machine Environment Configuration Register
pub const menvcfg = enum(u64) {
    stce = 1 << 63,
    adue = 1 << 61,

    pub inline fn read() u64 {
        return asm volatile (
            \\csrr %[ret], 0x30a
            : [ret] "=r" (-> u64),
        );
    }

    pub inline fn write(x: u64) void {
        asm volatile (
            \\csrw 0x30a, %[x]
            :
            : [x] "r" (x),
        );
    }
};

// Machine-mode Counter-enable
pub const mcounteren = enum {
    pub inline fn write(x: u64) void {
        asm volatile (
            \\csrw mcounteren, %[x]
            :
            : [x] "r" (x),
        );
    }

    pub inline fn read() u64 {
        return asm volatile (
            \\csrr %[ret], mcounteren
            : [ret] "=r" (-> u64),
        );
    }
};

// Supervisor Timer Comparison Register
pub const stimecmp = enum {
    pub inline fn read() u64 {
        return asm volatile (
            \\csrr %[ret], 0x14d
            : [ret] "=r" (-> u64),
        );
    }

    pub inline fn write(x: u64) void {
        asm volatile (
            \\csrw 0x14d, %[x]
            :
            : [x] "r" (x),
        );
    }
};

pub const mhartid = enum {
    pub inline fn read() u64 {
        return asm volatile (
            \\csrr %[ret], mhartid
            : [ret] "=r" (-> u64),
        );
    }
};

// read and write tp, the thread pointer, which xv6 uses to hold
// this core's hartid (core number), the index into cpus[].
pub const tp = enum {
    pub inline fn write(x: u64) void {
        asm volatile (
            \\mv tp, %[x]
            :
            : [x] "r" (x),
        );
    }

    pub inline fn read() u64 {
        return asm volatile (
            \\mv %[ret], tp
            : [ret] "=r" (-> u64),
        );
    }
};

// machine-code cycle counter
pub const time = enum {
    pub inline fn read() u64 {
        return asm volatile (
            \\csrr %[ret], time
            : [ret] "=r" (-> u64),
        );
    }
};
