export fn _entry() linksection(".text.entry") callconv(.naked) noreturn {
    asm volatile (
        \\la sp, stack0
        \\li a0, 1024*4
        \\csrr a1, mhartid
        \\addi a1, a1, 1
        \\mul a0, a0, a1
        \\add sp, sp, a0
        \\call start
    );
}
