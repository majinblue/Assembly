.globl  offset_pixel
offset_pixel:
//r1 = x block
//r2 = y block
//r0 = returning offset

.globl  offset_block
offset_block:
    push {r4-r10,lr}
//input
    //r0 = address
    //r1 = x block
    //r2 = y block
//output
    //r3 = returning block data
    //map offset = [old_x + (old_y * 32)] * 2 (because 2 bytes represents each map coordinate)
    lsl     r4,     r2,  #5
    add     r4,     r1
    lsl     r4,     #1
    ldrh    r3,     [r0,r4]
    pop {r4-r10,lr}
    mov     pc, lr
