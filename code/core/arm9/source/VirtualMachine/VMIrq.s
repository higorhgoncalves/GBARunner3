.section ".itcm", "ax"
.altmacro

#include "AsmMacros.inc"
#include "VMDtcmDefs.inc"

vm_irq_base:

#define DTCM(x) (vm_irq_base - 0x80 + (x))

arm_func vm_irq
    str r8, DTCM(vm_irqSavedR8)
    // here emulator irq tasks can be performed

    // todo: Don't tigger hblank irq on scanlines beyond the gba screen

    mov r13, #0x04000000
    ldr r8, [r13, #0x214]
    str lr, DTCM(vm_irqSavedLR)
    str r8, [r13, #0x214]
    ldr r13, DTCM(vm_hwIrqMask)
    ldr lr, DTCM(vm_emulatedIfImeIe)
    and r13, r13, r8 // bits to add to the emulated IF
    orr r13, lr, r13
    str r13, DTCM(vm_emulatedIfImeIe)
    
    tst r8, #(1 << 16) // ARM7 IRQ
    tsteq r8, #1 // VBLANK IRQ
    bne vm_emuIrq

vm_emu_irq_continue:
    ldr r8, DTCM(vm_irqSavedR8)
    ldr lr, DTCM(vm_irqSavedLR)
    // 0EEE EEEE EEEE EEE0 M0FF FFFF FFFF FFFF (E = IF, M = IME, F = IE)
    //M0FFF FFFF FFFF FFF0
    tst r13, r13, lsl #17 // IF & IE
    ldr r13, DTCM(vm_cpsr)
    sublss pc, lr, #4 // IME = 0 or (IF & IE == 0)

    teq r13, r13, lsl #24 // C = I flag, N = F flag
    subcss pc, lr, #4 // vm doesn't want irqs; nothing changed; resume where we left off

    str lr, DTCM(vm_regs_irq + 4)

    mrs lr, spsr
    bic lr, lr, #0xCF
    orr lr, lr, r13, lsr #1
    str lr, DTCM(vm_spsr_irq)
    and lr, lr, #(0xF << 1)
    mov r13, #(0x92 << 1)
    orrmi r13, r13, #(0x40 << 1)
    str r13, DTCM(vm_cpsr)

    msr spsr, #0x10 // user mode, irqs stay on, arm mode
    adr lr, DTCM(vm_regs_irq)
    add pc, pc, lr, lsl #4
    nop
old_mode_usr:
    stmdb lr, {r13,lr}^
    nop
    ldmia lr, {r13,lr}^
    ldr pc, DTCM(vm_irqVector)
    nop
    nop
    nop
    nop
old_mode_fiq:
    adr r13, DTCM(vm_regs_sys)
    stmdb r13, {r8,r9,r10,r11,r12,r13,lr}^
    nop
    ldmia r13, {r8,r9,r10,r11,r12}^
    nop
    ldmia lr, {r13,lr}^
    ldr pc, DTCM(vm_irqVector)
    nop
old_mode_irq:
    ldmib r13, {lr}^
    ldr pc, DTCM(vm_irqVector)
    nop
    nop
    nop
    nop
    nop
    nop
old_mode_svc:
    adr lr, DTCM(vm_regs_svc)
    stmia lr, {r13,lr}^
    nop
    ldmdb lr, {r13,lr}^
    ldr pc, DTCM(vm_irqVector)
    nop
    nop
    nop
old_mode_4:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
old_mode_5:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
old_mode_6:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
old_mode_abt:
    adr lr, DTCM(vm_regs_abt)
    stmia lr, {r13,lr}^
    nop
    adr lr, DTCM(vm_regs_irq)
    ldmia lr, {r13,lr}^
    ldr pc, DTCM(vm_irqVector)
    nop
    nop
old_mode_8:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
old_mode_9:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
old_mode_10:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
old_mode_und:
    adr lr, DTCM(vm_regs_und)
    stmia lr, {r13,lr}^
    nop
    adr lr, DTCM(vm_regs_irq)
    ldmia lr, {r13,lr}^
    ldr pc, DTCM(vm_irqVector)
    nop
    nop
old_mode_12:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
old_mode_13:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
old_mode_14:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
old_mode_sys:
    stmdb lr, {r13,lr}^
    nop
    ldmia lr, {r13,lr}^
    ldr pc, DTCM(vm_irqVector)

vm_emuIrq:
    tst r8, #(1 << 16) // ARM7 IRQ
    blne emu_arm7Irq
    tst r8, #1 // VBLANK IRQ
    blne emu_vblankIrq
    b vm_emu_irq_continue