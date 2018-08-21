/* INPUT ARGUMENTS (from main.s to draw.s)
 - r0 = category and shape
        eg. 0c (block - cloud)
 - r1 = x-axis location of bottom left block of shape
 - r2 = y-axis location of bottom left block  of shape */
/* OTHER REGISTERS
 - r3 = frame buffer pointer
 - r4 = x-axis block count
 - r5 = y-axis block count
 - r6 = pixel colour from block data
 - r7 = pixel offset */
/* RESET r0 to be bdata:
 - r0 = 32x32 block pixel data */

.globl	draw
draw:
    push    {r3-r10, lr}
    //category and shape
    shape   .req    r0
    //pixel location
    xaxis   .req    r1
    //pixel location
    yaxis   .req    r2
    //framebuffer pointer
    fbp     .req    r3
    //x pixel coordinate = 0
    xcount  .req    r4
    mov     xcount, #0
    //y pixel coordinate = 0
    ycount  .req    r5
    mov     ycount, #0
    //16-bit colour from block data
    colour  .req    r6
    //pixel offset
    offset  .req    r7
    bl      library
    .unreq  shape
    //block data
    bdata   .req    r0
    //update fbp
    ldr     r3,    =FrameBufferPointer
    ldr     r3,    [r3]

draw_loop:
    // offset = [(y * 1024) + (x * 32)] * 32 = [(x << 5) + (y << 10)] * 32
    lsl     offset, xaxis, #5
    add		offset,	xaxis, yaxis, lsl #10
    lsl     offset, #5
    // offset *= 2 (for 16 bits per pixel = 2 bytes per pixel)
    lsl		offset, #1
    ldr     r11,    =0x3e1  //(1024 - 31) * 2 = 990 * 2 = 1986
    lsl     r11,    #1
draw_pixel:
    //pixel 16-bit color (2 bytes)
    ldrh    colour, [bdata],    #2
    strh    colour, [fbp, offset]
draw_check:
    add     xcount, #1
    cmp     xcount, #31
    addle   offset, #2
    movgt   xcount, #0
    addgt   ycount, #1
    addgt   offset, r11
    cmp     ycount, #31
    bgt     draw_done
    cmp     xcount, #0
    b       draw_pixel
draw_done:
    .unreq  xaxis
    .unreq  yaxis
    .unreq  fbp
    .unreq  xcount
    .unreq  ycount
    .unreq  colour
    .unreq  bdata
    .unreq  offset
    pop	{r3-r10, lr}
    mov pc, lr

.globl	draw_outline
draw_outline:
    push    {r3-r10, lr}
    //category and shape
    shape   .req    r0
    //pixel location
    xaxis   .req    r1
    //pixel location
    yaxis   .req    r2
    //framebuffer pointer
    fbp     .req    r3
    //x pixel coordinate = 0
    xcount  .req    r4
    mov     xcount, #0
    //y pixel coordinate = 0
    ycount  .req    r5
    mov     ycount, #0
    //16-bit colour from block data
    colour  .req    r6
    //pixel offset
    offset  .req    r7
    bl      library
    .unreq  shape
    //block data
    bdata   .req    r0
    //update fbp
    ldr     r3,    =FrameBufferPointer
    ldr     r3,    [r3]

draw_outline_loop:
    // offset = [(y * 1024) + (x * 32)] * 32 = [(x << 5) + (y << 10)] * 32
    lsl     offset, xaxis, #5
    add		offset,	xaxis, yaxis, lsl #10
    lsl     offset, #5
    // offset *= 2 (for 16 bits per pixel = 2 bytes per pixel)
    lsl		offset, #1
    ldr     r11,    =0x3e1  //(1024 - 31) * 2 = 990 * 2 = 1986
    lsl     r11,    #1
draw_pixel_outline:
    //pixel 16-bit color (2 bytes)
    ldrh    colour, [bdata],    #2
    ldr     r10,    =#27679                 //don't draw blue pixels
    cmp     colour, r10
    beq     draw_skip_outline
    strh    colour, [fbp, offset]
draw_skip_outline:
    add     xcount, #1
    cmp     xcount, #31
    addle   offset, #2
    movgt   xcount, #0
    addgt   ycount, #1
    addgt   offset, r11
    cmp     ycount, #31
    bgt     draw_done
    cmp     xcount, #0
    b       draw_pixel_outline
draw_done_outline:
    .unreq  xaxis
    .unreq  yaxis
    .unreq  fbp
    .unreq  xcount
    .unreq  ycount
    .unreq  colour
    .unreq  bdata
    .unreq  offset
    pop	{r3-r10, lr}
    mov pc, lr
