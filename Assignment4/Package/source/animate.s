.globl  animate_coin
animate_coin:
    push {r4-r10,lr}
    //check if there is a coin on screen
    ldr r4, =coin_shown
    ldr r5, [r4]
    //if no coin, we are done
    cmp r5, #1
    bne animate_done
    //set to no coin, we will be erasing it
    mov r5, #0
    //get coordinates of coin
    str r5, [r4]
    ldr r4, =coin_coord
    ldrb    r5, [r4]
    ldrb    r6, [r4,#1]
    //find out what the orginal block offset
    mov     r7,     r5
    add     r7,     r6, lsl #5
    lsl     r7,     #1
    //find out what the original block was
    ldr     r4, =map_current
    ldrh    r8, [r4,r7]
    //restore the original block ontop of coin
    mov     r0, r8
    mov     r1, r5
    mov     r2, r6
    bl      draw        //draw the original block
//done coin animation
animate_done:
    pop {r4-r10,lr}
    mov pc, lr

.globl  animate_spike
animate_spike:
    push {r4-r10,lr}
    range_f .req    r4
    range_l .req    r5
    ldr r7, =animate_on             //animates every 2 loops
    ldrb r8, [r7]
    cmp r8, #2
    movge   r8, #0
    add     r8, #1
    strb r8, [r7]
    cmp r8, #1
    bne spike_done
    ldr r6, =map_range
    ldrb    range_f,    [r6]
    ldrb    range_l,    [r6, #1]
    cmp range_f,    #51
    blt   spike_done
    ldr r6, =spike_show
    ldr r7, [r6]
    cmp r7, #0
    beq spike_done
    shape   .req    r6
    xb  .req    r7
    yb  .req    r8
    sprite  .req    r9
    addr    .req    r10
    ldr addr,   =spike_sprite
    ldr sprite, [addr]
spike_check:
    mov     xb, #51
    mov     r1, #31
    cmp range_f, xb
    ble spike_update
    sub xb, range_f, xb
    cmp xb, #25
    bgt spike_check2
spike_loop:
    mov r2, #20
    ldr addr,   =map_current
    lsl     shape,  r2,  #5
    add     shape,  r1
    lsl     shape,  #1
    ldrh    shape,  [addr,shape]
    mov r0, shape
    bl  draw
    add     sprite, #1
    cmp     sprite, #5
    moveq   sprite, #1
    cmp     sprite, #1
    ldreq   shape,  =0x9
    cmp     sprite, #2
    ldreq   shape,  =0x1109
    cmp     sprite, #3
    ldreq   shape,  =0x109
    cmp     sprite, #4
    ldreq   shape,  =0x1009
    mov r2, #20
    mov r0, shape
    bl  draw_outline
    cmp xb, #0
    ble spike_update
    sub xb, #1
    sub r1, #1
    b   spike_loop
spike_check2:
    sub xb, #25
    mov r1, #31
    sub r1, xb
    cmp range_f,    #82
    movge   r3, #0
    bge spike_loop2
    mov r3, #31
    sub r3, r1
    cmp r3, #1
    addeq   r3, #4
    beq spike_loop2
    cmp r3, #2
    addeq   r3, #2
    beq spike_loop2
    cmp r3, #4
    subeq   r3, #2
    beq spike_loop2
    cmp r3, #5
    subeq   r3, #4
    beq spike_loop2
spike_loop2:
    mov r2, #20
    ldr addr,   =map_current
    lsl     shape,  r2,  #5
    add     shape,  r1
    lsl     shape,  #1
    ldrh    shape,  [addr,shape]
    mov r0, shape
    bl  draw
    add     sprite, #1
    cmp     sprite, #5
    moveq   sprite, #1
    cmp     sprite, #1
    ldreq   shape,  =0x9
    cmp     sprite, #2
    ldreq   shape,  =0x1109
    cmp     sprite, #3
    ldreq   shape,  =0x109
    cmp     sprite, #4
    ldreq   shape,  =0x1009
    mov r2, #20
    mov r0, shape
    bl  draw_outline
    sub r2, r3, r2
    cmp r1, r3
    ble spike_update
    sub r1, #1
    b   spike_loop2
spike_update:
    ldr addr,   =spike_sprite
    add sprite, #1
    cmp     sprite, #5
    moveq   sprite, #1
    strb    sprite, [addr]
    mov r1, xb
    mov r2, yb
    mov r3, shape
    bl  col_animate
spike_done:
    .unreq  shape
    .unreq  xb
    .unreq  yb
    .unreq  addr
    .unreq  range_f
    .unreq  range_l
    pop     {r4-r10,lr}
    mov     pc, lr

//
//.globl  animate_enemy
//animate_enemy:
//    push {r4-r10,lr}
//    range_f .req    r4
//    range_l .req    r5
//    ldr r7, =animate_on             //only animates every 4 loops
//    ldrb r8, [r7]
//    cmp r8, #4
//    movge   r8, #0
//    add     r8, #1
//    strb r8, [r7]
//    bne animate_finish
//    ldr r6, =map_range
//    ldrb    range_f,    [r6]
//    ldrb    range_l,    [r6, #1]
//    cmp range_f,    #23
//    bllt    animate_lakitu
//    cmp range_f,    #63
//    bllt    animate_goomba
//    cmp range_f,    #95
//    bllt    animate_spike
//    b   animate_finish
//
//animate_lakitu:
//    push    {r6-r10,lr}
//    shape   .req    r6
//    xb  .req    r7
//    yb  .req    r8
//    sprite  .req    r9
//    addr    .req    r10
//    cmp range_f,    #22
//    bgt     lakitu_done
//lakitu_check:
//    ldr addr,   =lakitu_sprite
//    ldrb    sprite, [addr]
//    ldr addr,   =animate_on
//    ldr shape,  [addr]
//    cmp shape,  #3
//    addeq   sprite, #1
//    cmp     sprite, #5
//    moveq   sprite, #1
//    cmp     sprite, #1
//    ldreq   shape,  =0x5
//    cmp     sprite, #2
//    ldreq   shape,  =0x1005
//    cmp     sprite, #3
//    ldreq   shape,  =0x2005
//    cmp     sprite, #4
//    ldreq   shape,  =0x3005
//    cmp range_f,    #21
//    ble lakitu_left
//lakitu_right:
//    mov xb, #22
//    sub r1, xb, range_f
//    mov yb, #9
//    mov r2, yb
//    add r0, shape,  #0x100
//    bl  draw
//    add r2, #1
//    add r0, shape,  #0x300
//    bl  draw
//    b   lakitu_update
//lakitu_left:
//    mov xb, #21
//    sub r1, xb, range_f
//    mov yb, #9
//    mov r2, yb
//    mov r0, shape
//    bl  draw
//    add r2, yb, #1
//    add r0, shape,  #0x200
//    bl  draw
//    b   lakitu_right
//lakitu_update:
//    ldr addr,   =lakitu_sprite
//    strb    sprite, [addr]
//lakitu_done:
//    .unreq  shape
//    .unreq  xb
//    .unreq  yb
//    .unreq  addr
//    pop     {r6-r10,lr}
//    mov     pc, lr
//
//animate_goomba:
//    push    {r6-r10,lr}
//    shape   .req    r6
//    xb  .req    r7
//    yb  .req    r8
//    sprite  .req    r9
//    addr    .req    r10
//    cmp range_l,    #35
//    blt goomba_done
//    cmp range_f,    #58
//    bgt goomba_done
//goomba_check:
//    ldr addr,   =goomba_sprite
//    ldrb    sprite, [addr]
//    ldr addr,   =animate_on
//    ldr shape,  [addr]
//    cmp shape,  #2
//    addeq   sprite, #1
//    cmp     sprite, #3
//    moveq   sprite, #1
//    cmp     sprite, #1
//    ldreq   shape,  =0x4
//    cmp     sprite, #2
//    ldreq   shape,  =0x104
//    cmp range_f,    #35
//    ble goomba_first
//    cmp range_f,    #41
//    ble goomba_second
//    cmp range_f,    #58
//    ble goomba_third
//    b   goomba_done
//goomba_first:
//    ldr addr,   =map_current
//    mov xb, #35
//    sub r1, xb, range_f
//    add sprite, xb, yb, lsl #5
//    lsl sprite, #1
//    ldr yb,     [addr,sprite]
//    ldr addr,   =0x7300
//    cmp yb,     addr
//    beq goomba_second
//    mov yb, #20
//    mov r2, yb
//    mov r0, shape
//    bl  draw
//goomba_second:
//    ldr addr,   =map_current
//    mov xb, #41
//    sub r1, xb, range_f
//    mov yb, #16
//    mov r2, yb
//    add sprite, xb, yb, lsl #5
//    lsl sprite, #1
//    ldr sprite, [addr,sprite]
//    ldr addr,   =0x7300
//    cmp sprite, addr
//    beq goomba_third
//    cmp shape,  #0x4
//    movne r0, shape
//    moveq   r0, #0x4
//    bl  draw
//goomba_third:
//    ldr addr,   =map_current
//    mov xb, #58
//    sub r1, xb, range_f
//    mov yb, #17
//    mov r2, yb
//    add sprite, xb, yb, lsl #5
//    lsl sprite, #1
//    ldr sprite, [addr,sprite]
//    ldr addr,   =0x7300
//    cmp sprite, addr
//    beq goomba_update
//    mov r0, shape
//    bl  draw
//goomba_update:
//    ldr addr,   =goomba_sprite
//    ldrb    sprite, [addr]
//    add     sprite, #1
//    cmp     sprite, #3
//    moveq   sprite, #1
//    strb    sprite, [addr]
//    mov r1, xb
//    mov r2, yb
//    mov r3, shape
//    bl  col_animate
//goomba_done:
//    .unreq  shape
//    .unreq  xb
//    .unreq  yb
//    .unreq  addr
//    pop     {r6-r10,lr}
//    mov     pc, lr
//
//animate_finish:
//    .unreq  range_f
//    .unreq  range_l
//    pop {r4-r10,lr}
//    mov pc, lr
