.globl mario_animate
mario_animate:
    push    {r4-r10, lr}
    addr .req    r10
    //check if mario dying animation is taking place
    ldr addr,   =mario_sprite
    ldr r0, [addr]
    ldr r1, =0x2006
    cmp r0, r1
    beq mario_dies_cont
    //sprite
    sprite  .req    r0
    ldr     addr,   =mario_sprite
    ldrh    sprite, [addr]
    //mario's location (x-axis)
    xloc    .req    r1
    ldr     addr,   =mario_coord
    ldrb    xloc,   [addr]
    //mario's location (y-axis)
    yloc    .req    r2
    ldrb    yloc,   [addr, #1]
    //frame buffer pointer
    fbp     .req    r3
    ldr     fbp,    =FrameBufferPointer
    ldr     fbp,    [fbp]
    //game pause status
    mpause  .req    r4
    ldr     mpause, =pause
    ldrb    mpause, [mpause]
    //mario direction
    direct  .req    r5
    //pixel offset
    offset  .req    r7
    mov     offset, #0
    //pixel colour
    colour  .req    r8
    //collision information
    collide .req    r9
    //check jumping
mario_jump:
    ldr     addr,   =mario_jump_count
    ldrb    direct, [addr]
    cmp     direct, #0              //no jump input
    beq     mario_fall
    cmp     direct, #4              //jumped maximum height
    bgt     mario_fall
    //check if there is anything above mario prevent jump
    ldr     addr,   =collide_data
    ldrb    collide,    [addr,#7]   //#7 is block above mario
    cmp     collide,    #1          //can't jump
    beq     mario_fall
    cmp     collide,    #3          //can't jump
    beq     mario_break
    cmp     collide,    #2          //can't jump
    beq     mario_coin
    sub     yloc,       #1          //can jump
    cmp     collide,    #4          //jump into enemy
    bge     mario_dies
    b       mario_move              //jump normally
mario_fall:
    //cancel any remaining jump
    ldr r6, =mario_jump_count
    ldr direct, =0x99
    str direct, [r6]
    //reset jump if mario is standing on solid ground
    ldr addr,   =collide_data
    ldrb    collide,    [addr,#1]   //#1 is block below mario
    cmp     collide,    #0          //fall through sky and others
    addeq   yloc,   #1              //fall
    cmp     collide,    #5          //fall through death (black)
    addeq   yloc,   #1              //fall
    cmp     collide,    #4          //fall through death (black)
    beq     mario_kill
mario_move:
    //branching for next sprite and coordinates
    ldr     addr,   =mario_direct
    ldrb    direct, [addr]
    cmp     direct, #0              //none
    beq     mario_none
    cmp     direct, #1              //right
    beq     mario_right
    cmp     direct, #2              //left
    beq     mario_left
mario_none:
    cmp     yloc,   #23
    bge     mario_dies              //fallen off the screen
    cmp     collide,    #4          //fall on goomba
    beq     mario_kill
    ldr     addr,   =0x906
    cmp     sprite, addr
    bgt     mario_none_left
mario_none_right:
    cmp     yloc,   #20
    ldreq   sprite, =0x6
    beq     mario_none_done
    ldr     sprite, =0x506
    b       mario_none_done
mario_none_left:
    cmp     yloc,   #20
    ldreq   sprite, =0x1006
    beq     mario_none_done
    ldr     sprite, =0x1506
    b       mario_none_done
mario_none_done:
    bl      mario_delete
    b       mario_update
mario_right:
    cmp     mpause, #1              //game paused = 1
    beq     mario_unpause           //repeat last sprite and unpause
    ldr addr,   =collide_data
    ldrb    collide,    [addr,#8]   //#8 is block to top right of mario
    cmp     collide,    #1
    beq     mario_right_sprite      //can't go right
    cmp     collide,    #2
    beq     mario_right_sprite      //can't go right
    cmp     collide,    #3
    beq     mario_right_sprite      //can't go right
    ldrb    collide,    [addr,#5]   //#5 is block to right of mario
    cmp     collide,    #1
    beq     mario_right_sprite      //can't go right
    cmp     collide,    #2
    beq     mario_right_sprite      //can't go right
    cmp     collide,    #3
    beq     mario_right_sprite      //can't go right
    cmp     xloc,       #31
    beq     mario_right_sprite      //can't go right
    ldrb    collide,    [addr,#1]   //#1 is block to bottom of mario
    cmp     collide,    #0
    bne     mario_right_okay
mario_right_fall:
    ldrb    collide,    [addr,#2]   //#2 is block to bottom right of mario
    cmp     collide,    #1
    beq     mario_right_sprite      //can't go right
    cmp     collide,    #2
    beq     mario_right_sprite      //can't go right
    cmp     collide,    #3
    beq     mario_right_sprite      //can't go right
    b       mario_right_okay
mario_right_okay:
    add     xloc,       #1          //can move right
    ldrb    collide,    [addr,#5]   //#5 is block to right of mario
    cmp     collide,    #4
    bge     mario_dies              //enemies
    ldrb    collide,    [addr,#1]   //#1 is block to bottom of mario
    cmp     collide,    #0
    ldreq   sprite, =0x506          //jump right
    bleq    mario_delete
    beq     mario_update
    ldr     addr,   =mario_count
    ldrb    direct, [addr]          //get number of times going right
    cmp     direct, #0
    beq     mario_stop_right        //check for previous left direction
    b       mario_right_sprite
mario_right_sprite:
    ldr addr,   =mario_jump_count
    ldr direct, [addr]
    cmp direct, #4
    bne mario_right_sprite_cont
    ldr addr,   =mario_direct
    ldr direct, [addr]
    cmp direct, #1
    bne mario_right_sprite_cont
mario_right_block_land:
    ldr     addr,       =collide_data
    ldrb    collide,    [addr,#5]   //#5 is block to right of mario
    cmp     collide,    #0
    addne   xloc,   #1
    b       mario_right_sprite_cont
mario_right_sprite_cont:
    //direct(mod3)
    ldr     addr,   =mario_count
    ldr     direct, [addr]
    mov     addr,   #4
    mov     r6, direct
    sdiv    r6,     addr
    mul     r6,     addr
    sub     direct, r6
    //compare to sprite number
    cmp     direct, #0
    ldreq   sprite, =0x106
    cmp     direct, #1
    ldreq   sprite, =0x206
    cmp     direct, #2
    ldreq   sprite, =0x306
    bl      mario_delete
    b       mario_update
mario_stop_right:
    ldr     r6,     =0x506
    cmp     sprite, r6
    ldrgt   sprite, =0x406          //change in direction sprite
    blgt    mario_delete
    bgt     mario_update
    ldr     sprite, =0x106          //first right sprite
    bl      mario_delete
    b       mario_update
mario_left:
    cmp     mpause, #1              //game paused = 1
    beq     mario_unpause           //repeat last sprite and unpause
    ldr addr,   =collide_data
    ldrb    collide,    [addr,#6]   //#6 is block to top left of mario
    cmp     collide,    #1
    beq     mario_left_sprite      //can't go left
    cmp     collide,    #2
    beq     mario_left_sprite      //can't go left
    cmp     collide,    #3
    beq     mario_left_sprite      //can't go left
    ldrb    collide,    [addr,#3]   //#3 is block to left of mario
    cmp     collide,    #1
    beq     mario_left_sprite      //can't go left
    cmp     collide,    #2
    beq     mario_left_sprite      //can't go left
    cmp     collide,    #3
    beq     mario_left_sprite      //can't go left
    cmp     xloc,       #0
    beq     mario_left_sprite      //can't go left
    ldrb    collide,    [addr,#1]   //#1 is block to bottom of mario
    cmp     collide,    #0
    bne     mario_left_okay
mario_left_fall:
    ldrb    collide,    [addr,#0]   //#0 is block to bottom left of mario
    cmp     collide,    #1
    beq     mario_left_sprite      //can't go left
    cmp     collide,    #2
    beq     mario_left_sprite      //can't go left
    cmp     collide,    #3
    beq     mario_left_sprite      //can't go left
    b       mario_left_okay
mario_left_okay:
    sub     xloc,       #1          //can move left
    ldrb    collide,    [addr,#3]   //#3 is block to left of mario
    cmp     collide,    #4
    bge     mario_dies              //enemies
    ldrb    collide,    [addr,#1]   //#1 is block to bottom of mario
    cmp     collide,    #0
    ldreq   sprite, =0x1506          //jump left
    bleq    mario_delete
    beq     mario_update
    ldr     addr,   =mario_count
    ldrb    direct, [addr]          //get number of times going left
    cmp     direct, #0
    beq     mario_stop_left        //check for previous left direction
    b       mario_left_sprite
mario_left_sprite:
    ldr addr,   =mario_jump_count
    ldr direct, [addr]
    cmp direct, #4
    bne mario_left_sprite_cont
    ldr addr,   =mario_direct
    ldr direct, [addr]
    cmp direct, #2
    bne mario_left_sprite_cont
mario_left_block_land:
    ldr     addr,       =collide_data
    ldrb    collide,    [addr,#3]   //#3 is block to left of mario
    cmp     collide,    #0
    subne   xloc,   #1
    b       mario_left_sprite_cont
mario_left_sprite_cont:
    //direct(mod3)
    ldr     addr,   =mario_count
    ldr     direct, [addr]
    mov     addr,   #4
    mov     r6, direct
    sdiv    r6,     addr
    mul     r6,     addr
    sub     direct, r6
    //compare to sprite number
    cmp     direct, #0
    ldreq   sprite, =0x1106
    cmp     direct, #1
    ldreq   sprite, =0x1206
    cmp     direct, #2
    ldreq   sprite, =0x1306
    bl      mario_delete
    b       mario_update
mario_stop_left:
    ldr     r6,     =0x506
    cmp     sprite, r6
    ldrle   sprite, =0x1406         //change in direction sprite
    blle    mario_delete
    ble     mario_update
    ldr     sprite, =0x1106         //first left sprite
    bl      mario_delete
    b       mario_update
mario_break:
    //cancel any remaining jump
    ldr r6, =mario_jump_count
    ldr direct, =0x99
    str direct, [r6]
    //current map draw and update to sky (broke wood block)
    sub yloc,   #1
    ldr sprite, =0x7300
    bl  draw
    ldr addr,   =map_current
    add r6, xloc,   yloc,   lsl #5
    lsl r6, #1
    ldr sprite, =0x7300
    strh    sprite, [addr,  r6]
    //check for goomba above block
    sub yloc,   #1
    ldr addr,   =map_current
    add r6, xloc,   yloc,   lsl #5
    lsl r6, #1
    ldrh    sprite, [addr,  r6]
    ldr addr,   =0x4
    cmp sprite, addr
    ldreq   sprite, =0x7300
            //update game score
            ldr addr,   =stat_score
            ldrb r6, [addr,#1]
            ldrb direct, [addr]
            addeq r6, #1
            cmp r6, #10
            moveq   r6, #0
            addeq   direct, #1
            strb    r6, [addr,#1]
            strb    direct, [addr]
    ldr addr,   =0x1004
    cmp sprite, addr
    ldreq   sprite, =0x7300
        //update game score
        ldreq addr,   =stat_score
        ldreq r6, [addr]
        addeq r6, #100
        streq r6, [addr]
    ldr addr,   =map_current
    add r6, xloc,   yloc,   lsl #5
    lsl r6, #1
    strh    sprite, [addr,  r6]
    bl  draw
    //restore mario sprite and position
    ldr     addr,   =mario_sprite
    ldrh    sprite, [addr]
    add yloc, #3
    bl  mario_delete
    b   mario_update
mario_coin:
    //cancel any remaining jump
    ldr r6, =mario_jump_count
    ldr direct, =0x99
    str direct, [r6]
    //draw coin above mystery box
    sub yloc, #2
    ldr sprite, =0x2
    bl  draw
    //game status to coin shown
    mov r6, #1
    ldr addr, =coin_shown
    strb    r6, [addr]
    //game status update coin coordinates
    ldr addr, =coin_coord
    strb    xloc, [addr]
    strb    yloc, [addr, #1]
    //current map draw and update to empty block
    add yloc,   #1
    ldr sprite, =0x6500
    bl  draw
    ldr addr,   =map_current
    add r6, xloc,   yloc,   lsl #5
    lsl r6, #1
    ldr sprite, =0x6500
    strh    sprite, [addr,  r6]
    //update game coin count
    ldr addr,   =stat_coins
    ldr r6, [addr]
    add r6, #1
    str r6, [addr]
    //restore mario sprite and position
    ldr     addr,   =mario_sprite
    ldrh    sprite, [addr]
    add yloc, #3
    bl  mario_delete
    b   mario_update
mario_kill:
    //delete monster, restore original map element
    add yloc,   #1
    ldr addr,   =map_current
    add r6, xloc,   yloc,   lsl #5
    lsl r6, #1
    ldr sprite, =0x7300
    strh    sprite, [addr,  r6]
    bl  draw
    //update game score
    ldr addr,   =stat_score
    ldrb r6, [addr,#1]
    ldrb direct, [addr]
    add r6, #1
    cmp r6, #10
    moveq   r6, #0
    addeq   direct, #1
    strb    r6, [addr,#1]
    strb    direct, [addr]
    //restore mario sprite and position
    sub yloc,   #2
    ldrb    direct, =0x99
    ldr     addr,   =mario_direct
    strb    direct, [addr]
    ldr r6, =0x606
    cmp     sprite, r6
    ldrlt   sprite, =0x506
    ldrgt   sprite, =0x1506
    bl  mario_delete
    b   mario_update
mario_dies:
    ldr sprite, =0x2006
    b   mario_dies_check
mario_dies_cont:
    sub xloc,   #1
mario_dies_check:
    ldr     addr,   =mario_death_jump
    ldrb    r6, [addr]
    cmp     r6, #4
    blt     mario_dies_jump
    b       mario_dies_fall
mario_dies_jump:
    add     r6, #1
    str     r6, [addr]
    ldr     addr,   =mario_coord
    ldrb    xloc,   [addr]
    ldrb    yloc,   [addr,#1]
    bl  mario_delete
    sub     yloc,   #1
    b       mario_update
mario_dies_fall:
    ldr     addr,   =mario_coord
    ldrb    xloc,   [addr]
    ldrb    yloc,   [addr,#1]
    add     yloc,   #1
    bl  mario_delete
    cmp     yloc,   #24
    ble     mario_update
    ldr     addr,   =stat_lives
    ldr     direct, [addr]
    sub     direct, #1
    str     direct, [addr]
    cmp     direct, #0
    moveq   r0,     #4
    beq     mario_done                  //game over 0 lives remain
    ldr     addr,   =mario_coord
    mov     xloc,   #15
    mov     yloc,   #0
    strb    xloc,   [addr]
    strb    yloc,   [addr,#1]
    ldr     addr,   =mario_death_jump
    ldrb    r6, [addr]
    mov     r6, #0
    strb    r6, [addr]
    ldr     addr,   =mario_sprite
    ldr     sprite, =0x6
    strb    sprite, [addr]
    ldr     addr,   =mario_direct
    mov     direct, #0
    strb    direct, [addr]
    bl  mario_delete
    b   mario_update
mario_update:
    ldr     addr,   =mario_sprite
    strh    sprite, [addr]
    ldr     addr,   =mario_coord
    strb    xloc,   [addr]
    strb    yloc,   [addr, #1]
    b       mario_draw
mario_unpause:
    mov     mpause, #0
    ldr     mpause, =pause
    strb    mpause, [mpause]
    b       mario_draw
mario_draw:
    .unreq  mpause
    .unreq  direct
    xcount  .req    r4
    mov     xcount, #0
    ycount  .req    r5
    mov     ycount, #0
    bl      library
    // offset = [(y * 1024) + (x * 32)] * 32  = (x << 5) + (y << 10)
    add		offset,	xloc,   yloc,  lsl #10
    lsl     offset, #5
    // offset *= 2 (for 16 bits per pixel = 2 bytes per pixel)
    lsl		offset, #1
mario_draw_pixel:
    ldrh    colour, [sprite],   #2
    ldr     r10,    =#27679                 //don't draw blue pixels
    cmp     colour, r10
    beq     mario_draw_skip
    //store color in framebufferpointer
    strh    colour, [fbp, offset]
mario_draw_skip:
    add     xcount, #1
    cmp     xcount, #31
    addle   offset, #2
    movgt   xcount, #0
    addgt   ycount, #1
    addgt   offset, r11
    cmp     ycount, #31
    bgt     mario_done
    cmp     xcount, #0
    b       mario_draw_pixel
//finished updating mario
mario_done:
    //check where mario is on x-axis
    cmp xloc, #24
    blt mario_done_done
    //check if user is inputting right button
    ldr addr,   =mario_direct
    ldr xcount, [addr]
    cmp xcount, #1
    bne mario_done_done
    //scroll screen
    //reduce mario's xaxis by 1
    sub     xloc,   #1
    bl      mario_delete
    sub     xloc,   #1
    bl      mario_delete
    add     xloc,   #1
    ldr     addr,   =mario_sprite
    ldrh    sprite, [addr]
    bl      draw_outline
    bl      screen_scroll
    bl      mario_delete
    ldr     addr,   =mario_direct
    ldrb    xloc,   [addr]
    mov     xloc,   #0
    strb    xloc,   [addr]
    ldr     addr,   =mario_coord
    ldrb    xloc,   [addr]
    cmp     xloc,   #25
    moveq   xloc,   #24
    strb    xloc,   [addr]
    ldr     addr,   =mario_sprite
    ldrh    sprite, [addr]
mario_done_done:
    .unreq  sprite
    .unreq  xloc
    .unreq  yloc
    .unreq  addr
    .unreq  fbp
    .unreq  offset
    .unreq  colour
    .unreq  xcount
    .unreq  ycount
    pop	{r4-r10, lr}
    mov pc, lr

.globl mario_delete
mario_delete:
    push    {r4-r10, lr}
    //backup mario
    mov     r4,     r0
    mov     r5,     r1
    mov     r6,     r2
    //old mario x location
    ldr     r1,     =mario_coord
    ldrb    r1,     [r1]
    //old mario x location
    ldr     r2,     =mario_coord
    ldrb    r2,     [r2, #1]
    //old mario block offset
    mov     r7,     r1
    add     r7,     r2, lsl #5
    lsl     r7,     #1
    //old block information
    ldr     r0,     =map_current
    ldrh    r0,     [r0, r7]
    //draw old block back in place
    bl      draw
    //restore mario
    mov     r0,     r4
    mov     r1,     r5
    mov     r2,     r6
    pop	{r4-r10, lr}
    mov pc, lr

.section .data
.globl mario_standr
mario_standr:
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\202\350\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\202\350\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\10\331\202\350\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\202\350\10\331\10\331\10\331"
.ascii "\10\331\10\331\10\331\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\202\350\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\202\350\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37lE\241E\241E\241E\241E\241E\241`\364`\364`\364\301\332"
.ascii "E\241\301\342@\364P\264\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\312\231E\241E\241E\241"
.ascii "E\241E\241\240\375\240\375\240\375`\364E\241E\241\240\375p\264"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\312\231\312\231`\364`\364E\241E\241`\364 \375 \375 \375"
.ascii "\240\375\301\332E\241\301\332\240\375\345\344\345\344\345\344"
.ascii "\345\344\345\344\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\312\231E\241 \375 \375E\241E\241\240\375\240\375 \375"
.ascii " \375\240\375`\364E\241E\241\240\375 \375 \375 \375 \375\345\344"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\312\231"
.ascii "E\241`\364 \375E\241E\241E\241\341\342 \375 \375 \375`\364 \375"
.ascii "\301\332e\241\341\332 \375 \375 \375 \375\345\344\345\344"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\312\231E\241 \375 \375"
.ascii "E\241E\241E\241E\241 \375\240\375 \375 \375\240\375`\364"
.ascii "E\241\341\342\240\375 \375 \375 \375 \375 \375\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\312\231E\241E\241E\241`\364`\364`\364"
.ascii " \375 \375 \375\240\375`\364E\241E\241E\241E\241E\241E\241"
.ascii "E\241\352\231\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\312\231E\241E\241E\241\240\375\240\375 \375 \375 \375 \375"
.ascii "\240\375`\364E\241E\241E\241E\241E\241E\241E\241\312\231\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\345\354 \375 \375 \375 \375 \375 \375 \375@\364@\364 \375"
.ascii "`\364 \375\345\344\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l \375 \375 \375 \375 \375 \375"
.ascii " \375 \375 \375 \375 \375 \375 \375\344\354\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\352\231E\241"
.ascii "E\241E\241\0\370\202\350E\241E\241E\241E\241E\241\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\312\231E\241E\241E\241\0\370\202\350E\241E\241"
.ascii "E\241E\241E\2410\242\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\352\231E\241E\241E\241E\241"
.ascii "E\241\0\370\202\350E\241E\241E\241E\241\0\370\202\350E\241\312\231"
.ascii "E\241E\241E\241\352\231\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\312\231E\241E\241E\241E\241E\241\0\370\202\350"
.ascii "E\241E\241E\241\202\350\0\370\202\350E\241E\241E\241E\241"
.ascii "E\241\312\231\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241"
.ascii "E\241E\241E\241E\241E\241E\241\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\202\350E\241E\241E\241E\241E\241E\241E\241E\241"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241"
.ascii "E\241E\241E\241\0\370\0\370\0\370\0\370\0\370\0\370\0\370\202\350"
.ascii "E\241E\241E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l \375 \375 \375 \375E\241E\241\0\370\202\350"
.ascii "\240\375`\364\0\370\0\370\0\370\301\332\240\375\301\332\0\370"
.ascii "\202\350E\241E\241 \375\240\375 \375 \375\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l \375 \375\240\375 \375E\241E\241\0\370\202\350"
.ascii " \375`\364\0\370\0\370\0\370\202\350\240\375\341\332\0\370"
.ascii "\202\350E\241E\241\240\375 \375 \375 \375\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l \375 \375 \375 \375\240\375 \375\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\301\332"
.ascii "\240\375\240\375 \375 \375 \375 \375\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l \375 \375 \375 \375 \375`\364\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\341\332`\364 \375"
.ascii " \375 \375 \375 \375\37l\37l\37l\37l\37l\37l\37l\37l \375"
.ascii " \375 \375 \375\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370 \375 \375"
.ascii " \375 \375\37l\37l\37l\37l\37l\37l\37l\37l\4\355\4\355\4\355"
.ascii "\4\355\202\350\0\370\0\370\0\370\0\370\0\370\347\330\202\350"
.ascii "\347\330\202\350\0\370\0\370\0\370\0\370\0\370\202\350\4\355"
.ascii "\4\355\4\355\4\355\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\202\350\0\370\0\370\0\370\0\370\347\330\37l\37l\37l/\252"
.ascii "\0\370\0\370\0\370\0\370\0\370\202\350\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\202\350\202\350"
.ascii "\0\370\202\350\202\350\37l\37l\37l\37l\37l\347\330\202\350"
.ascii "\202\350\0\370\202\350\202\350\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\352\231E\241E\241E\241E\241\312\231"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241\352\231"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\312\231"
.ascii "E\241E\241E\241E\241\312\231\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "E\241E\241E\241E\241E\241\312\231\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241E\241\312\231\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241"
.ascii "E\241E\241E\241\312\231\37l\37l\37l\37l\37l\37l\37l\37lE\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l"
.globl mario_standl
mario_standl:
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\202\350\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\202\350\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\7\331\10\331\10\331\10\331\10\331\10\331\202\350"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\202\350\10\331\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\202\350\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\202\350"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37lP\264`\364\301\332E\241\301\332`\364`\364`\364"
.ascii "E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lp\264\240\375E\241"
.ascii "E\241`\364\240\375\240\375\240\375E\241E\241E\241E\241E\241"
.ascii "\312\231\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\345\354\345\344\345\344\345\344\345\344\240\375\301\332"
.ascii "E\241\341\332\240\375 \375 \375 \375`\364E\241E\241`\364`\364"
.ascii "\312\231\312\231\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\344\354 \375 \375 \375 \375\240\375E\241E\241`\364\240\375"
.ascii " \375 \375\240\375\240\375E\241E\241 \375 \375E\241\312\231"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\345\354\345\354"
.ascii " \375 \375 \375 \375\301\332E\241\301\332 \375`\364 \375 \375"
.ascii " \375\301\332E\241E\241E\241 \375`\364E\241\312\231\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l \375 \375 \375 \375 \375\240\375"
.ascii "\301\332E\241`\364\240\375 \375 \375\240\375 \375E\241E\241"
.ascii "E\241E\241 \375 \375E\241\312\231\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\312\231E\241E\241E\241E\241E\241E\241"
.ascii "E\241`\364\240\375 \375 \375 \375`\364`\364`\364E\241E\241"
.ascii "E\241\312\231\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\312\231E\241E\241E\241E\241E\241E\241E\241`\364\240\375 \375"
.ascii " \375 \375 \375\240\375\240\375E\241E\241E\241\312\231\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\344\354"
.ascii " \375`\364 \375`\364`\364 \375 \375 \375 \375 \375 \375 \375"
.ascii "\345\344\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\344\354 \375 \375 \375 \375 \375 \375 \375"
.ascii " \375 \375 \375 \375 \375 \375\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37lE\241E\241E\241E\241E\241\202\350\0\370E\241E\241E\241"
.ascii "\352\231\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l/\242E\241E\241E\241E\241E\241\202\350"
.ascii "\0\370E\241E\241E\241\312\231\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\312\231E\241E\241E\241\312\231"
.ascii "E\241\202\350\0\370E\241E\241E\241E\241\202\350\0\370E\241"
.ascii "E\241E\241E\241E\241\352\231\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\312\231E\241E\241E\241E\241E\241\202\350\0\370"
.ascii "\202\350E\241E\241E\241\202\350\0\370E\241E\241E\241E\241"
.ascii "E\241\312\231\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241"
.ascii "E\241E\241E\241E\241E\241E\241\202\350\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370E\241E\241E\241E\241E\241E\241E\241E\241"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241"
.ascii "E\241E\241E\241\202\350\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "E\241E\241E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l \375 \375\240\375 \375E\241E\241\202\350\0\370"
.ascii "\301\332\240\375\301\332\0\370\0\370\0\370`\364\240\375\202\350"
.ascii "\0\370E\241E\241 \375 \375 \375 \375\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l \375 \375 \375\240\375E\241E\241\202\350\0\370"
.ascii "\341\332\240\375\202\350\0\370\0\370\0\370`\364 \375\202\350"
.ascii "\0\370E\241E\241 \375\240\375 \375 \375\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l \375 \375 \375 \375\240\375\240\375\301\332\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii " \375\240\375 \375 \375 \375 \375\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l \375 \375 \375 \375 \375`\364\301\332\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370`\364 \375"
.ascii " \375 \375 \375 \375\37l\37l\37l\37l\37l\37l\37l\37l \375 \375"
.ascii " \375 \375\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370 \375 \375"
.ascii " \375 \375\37l\37l\37l\37l\37l\37l\37l\37l\344\354\344\354\344\354"
.ascii "\344\354\202\350\0\370\0\370\0\370\0\370\0\370\202\350"
.ascii "\347\330\202\350\347\330\0\370\0\370\0\370\0\370\0\370\202\350"
.ascii "\4\355\4\355\4\355\4\355\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\202\350\0\370\0\370\0\370\0\370\0\370/\242\37l"
.ascii "\37l\37l\347\330\0\370\0\370\0\370\0\370\202\350\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\202\350"
.ascii "\202\350\0\370\202\350\202\350\7\331\37l\37l\37l\37l\37l\202\350"
.ascii "\202\350\0\370\202\350\202\350\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\312\231E\241E\241E\241E\241E\241"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\312\231E\241E\241E\241E\241"
.ascii "\352\231\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\312\231E\241E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\312\231E\241E\241E\241E\241\312\231\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241E\241E\241"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\312\231E\241E\241E\241E\241"
.ascii "E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241"
.ascii "E\241E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\312\231E\241E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l"
.globl mario_stepr
mario_stepr:
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\213\301\242\330\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\242\330\214\301"
.ascii "\214\301\214\301\214\301\214\301\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\242\330\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\202\330\242\330\242\330\242\330\242\330\242\330"
.ascii "\2\323\342\322\342\322\342\322\202\330\202\330\2\323\2\323"
.ascii "\2\323/\242/\242/\242\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\246\220\250\231E\241\250\231\246\220\246\220"
.ascii "\241\364`\375`\375`\375\342\322\246\220\2\323`\375\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l/\242\2\323\2\323\246\220E\241\2\323\2\323\241\364`\375`\375"
.ascii "`\375\342\322\246\220\2\323`\375\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241\241\364@\375\342\322"
.ascii "\246\220E\241`\375`\375`\375`\375`\375`\375\342\322\246\220"
.ascii "\2\323`\375`\375`\375`\375`\375\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\246\220\2\323`\375\241\364\246\220E\241"
.ascii "\2\323\241\364\241\364`\375`\375`\375\342\322\342\322\342\322"
.ascii "\241\364\241\364`\375`\375\241\364\241\364\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37lE\241\241\364`\375\2\323\246\220"
.ascii "E\241\246\220\246\220\241\364`\375`\375`\375`\375`\375\342\322"
.ascii "\246\220\2\323`\375`\375`\375`\375`\375`\375\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37lE\241\2\323\241\364\2\323\250\231\342\322"
.ascii "E\241E\241\241\364`\375`\375`\375\241\364\241\364\2\323"
.ascii "\246\220\2\323\241\364\241\364\241\364\241\364\313\314\313\314"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241\246\220\2\323"
.ascii "`\375`\375`\375`\375`\375`\375`\375`\375\2\323\246\220\246\220"
.ascii "\246\220\246\220\246\220\246\220\246\220\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\250\231\250\231\250\231\2\323"
.ascii "`\375`\375`\375`\375`\375`\375`\375`\375\342\322E\241E\241"
.ascii "\342\322E\241E\241\250\231\250\231\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l`\375`\375`\375`\375`\375"
.ascii "`\375`\375`\375`\375`\375`\375`\375`\375`\375\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\241\364\241\364\241\364\241\364\241\364\241\364\241\364\241\364"
.ascii "\241\364`\375\241\364`\375\241\364`\375\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241"
.ascii "E\241E\241E\241E\241E\241\242\330\0\370\242\330\250\231\37l"
.ascii "\37l\37l`\375\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241E\241E\241\242\330"
.ascii "\0\370\242\330E\241\37l\37l\37l`\375\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l`\375\2\323\246\220E\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241E\241E\241\246\220\2\323"
.ascii "`\375`\375`\375\241\364`\375\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\313\314`\375\342\322\246\220E\241E\241E\241E\241"
.ascii "E\241E\241E\241E\241E\241E\241\246\220\2\323`\375`\375`\375"
.ascii "`\375`\375\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\241\364"
.ascii "`\375`\375\342\322\0\370\242\330E\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241E\241E\241\2\323`\375`\375`\375\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l`\375`\375`\375\2\323\0\370\242\330"
.ascii "\250\231E\241E\241E\241E\241E\241E\241E\241E\241\246\220"
.ascii "\2\323`\375`\375`\375\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\250\231\2\323\2\323\242\330\0\370\0\370\242\330\242\330"
.ascii "\242\330\242\330\242\330\242\330\0\370\242\330\242\330"
.ascii "\242\330\242\330\242\330O\242\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37lE\241E\241\246\220\242\330\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370/\242\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37lE\241\242\330\242\330\242\330\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "/\242\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241"
.ascii "\242\330\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370/\242\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\250\231E\241\242\330"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\213\301\37l\202\330\0\370"
.ascii "\0\370\0\370\0\370\0\370\213\301\213\301\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241\202\330\0\370"
.ascii "\0\370\0\370\0\370\0\370\242\330\37l\37l\213\311\0\370\0\370"
.ascii "\0\370\0\370\0\370\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37lE\241E\241\37l\37l\37l\213\311\213\311\213\311\213\311"
.ascii "\213\311\37l\37l\37l\213\311\242\330\242\330\242\330\213\301"
.ascii "\213\301\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37lE\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241"
.ascii "E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37lE\241E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241E\241\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241"
.ascii "E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.globl mario_stepl
mario_stepl:
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\214\301\214\301\214\301\214\301\214\301\242\330"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\242\330\214\301\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\242\330\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii ".\242.\242.\242\2\323\2\323\2\323\202\330\202\330\342\322\342\322"
.ascii "\342\322\342\322\242\330\242\330\242\330\242\330\242\330"
.ascii "\242\330\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l`\375\2\323\246\220\342\322`\375`\375"
.ascii "`\375\241\354\246\220\246\220\250\231E\241\250\231\246\220\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l`\375\2\323\246\220\2\323`\375`\375`\375\241\364\342\322"
.ascii "\342\322E\241\246\220\2\323\2\323/\242\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l`\375`\375`\375`\375`\375"
.ascii "\2\323\246\220\2\323`\375`\375`\375`\375`\375`\375E\241\246\220"
.ascii "\342\322@\375\241\354E\241\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\241\364\241\364`\375`\375\241\364\241\364\342\322"
.ascii "\342\322\342\322`\375`\375`\375\241\364\241\364\2\323E\241"
.ascii "\246\220\241\364`\375\2\323\246\220\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l`\375`\375`\375`\375`\375`\375\2\323\246\220\2\323"
.ascii "`\375`\375`\375`\375`\375\241\364\246\220\246\220E\241\246\220"
.ascii "\2\323`\375\241\364E\241\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\312\314\312\314\241\364\241\364\241\364\241\364\2\323\246\220"
.ascii "\2\323\241\364\241\364`\375`\375`\375\241\364E\241E\241"
.ascii "\342\322\210\231\2\323\241\364\2\323E\241\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l.\242\246\220\246\220\246\220\246\220"
.ascii "\246\220\246\220\246\220\2\323`\375`\375`\375`\375`\375`\375"
.ascii "`\375`\375\2\323\246\220E\241E\241\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\250\231\250\231E\241E\241\342\322"
.ascii "E\241E\241\342\322`\375`\375`\375`\375`\375`\375`\375`\375\342\322"
.ascii "\210\231\210\231\210\231\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l`\375`\375`\375`\375`\375`\375`\375"
.ascii "`\375`\375`\375`\375`\375`\375`\375\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l`\375\240\364"
.ascii "`\375\240\364`\375\241\364\241\364\241\364\241\364\241\364\241\364"
.ascii "\241\364\241\364\241\364\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l`\375\37l\37l\37l"
.ascii "\250\231\242\330\0\370\242\330E\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l`\375\37l\37l\37lE\241\242\330\0\370\242\330E\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l`\375\241\354`\375`\375`\375"
.ascii "\3\323\246\220E\241E\241E\241E\241E\241E\241E\241E\241E\241"
.ascii "E\241\246\220\3\323`\375\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l`\375`\375`\375`\375`\375\2\323\246\220E\241E\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241E\241\246\220\2\323`\375"
.ascii "\313\314\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "`\375`\375`\375\2\323E\241E\241E\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241\242\330\0\370\2\323`\375`\375\241\354\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l`\375`\375`\375\2\323\246\220"
.ascii "E\241E\241E\241E\241E\241E\241E\241E\241\250\231\242\330"
.ascii "\0\370\2\323`\375`\375`\375\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37lO\242\242\330\242\330\242\330\242\330\242\330"
.ascii "\0\370\242\330\242\330\242\330\242\330\242\330\242\330"
.ascii "\0\370\0\370\242\330\2\323\2\323\250\231\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l/\242\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\242\330\246\220E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l/\242\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\242\330\242\330"
.ascii "\242\330E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l.\242\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\242\330E\241"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\213\311\213\311\0\370\0\370\0\370\0\370\0\370\202\330\37l\213\311"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\242\330E\241\250\231"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\0\370\0\370\0\370\0\370\0\370\213\311\37l\37l\202\330\0\370"
.ascii "\0\370\0\370\0\370\0\370\202\330E\241E\241E\241E\241\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\213\311\213\311"
.ascii "\242\330\242\330\242\330\213\311\37l\37l\37lk\311k\311k\311"
.ascii "k\311k\311\37l\37l\37lE\241E\241\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37lD\241D\241\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241"
.ascii "E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241"
.ascii "E\241E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37lE\241E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.globl mario_walkr
mario_walkr:
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\312\231\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\312\231\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\347\330\347\330\202\350\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\347\330"
.ascii "\347\330\347\330\347\330\347\330\347\330\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\202\350\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241\"\333`\364"
.ascii "`\364`\364\304\261E\241`\364`\364\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\206\241E\241"
.ascii "E\241E\241E\241E\241`\364 \375 \375 \375\304\261E\241`\364 \375"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\312\231\312\231`\364 \375\304\261E\241\"\333`\364 \375"
.ascii " \375 \375 \375\304\261E\241\2\365 \375\2\365\2\365\2\365"
.ascii "\313\314\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\206\241"
.ascii "E\241 \375 \375\"\333E\241\"\333 \375 \375 \375 \375 \375"
.ascii "\304\261E\241`\364 \375 \375 \375 \375\2\365\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\206\241\304\261 \375 \375\304\261"
.ascii "E\241\304\261\304\261`\364 \375 \375 \375`\364`\364\304\261"
.ascii "\304\261 \375 \375 \375 \375\2\365\313\314\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\206\241E\241 \375 \375\"\333E\241"
.ascii "E\241E\241\"\333 \375 \375 \375 \375 \375\304\261E\241 \375"
.ascii " \375 \375 \375 \375\2\365\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\206\241E\241\304\261\304\261\"\333\2\365`\364`\364 \375"
.ascii " \375 \375 \375\304\261\304\261E\241E\241\304\261\304\261"
.ascii "\304\261\304\261\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\206\241E\241E\241E\241\"\333 \375 \375 \375 \375 \375 \375"
.ascii " \375\304\261E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\313\314"
.ascii " \375 \375 \375 \375 \375 \375 \375 \375 \375`\364 \375`\364"
.ascii "\2\365\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\313\314\2\365 \375 \375 \375 \375 \375 \375"
.ascii " \375 \375 \375\2\365 \375\2\365\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\206\241\206\241\206\241\206\241"
.ascii "\206\241\206\241\304\261\202\350\0\370\0\370\0\370E\241\206\241"
.ascii "E\241\304\261\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\206\241E\241E\241E\241E\241E\241E\241\206\241"
.ascii "\202\350\0\370\0\370\0\370E\241E\241E\241E\241\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\2\365\2\365 \375\2\365"
.ascii "\304\261E\241E\241E\241E\241E\241E\241E\241\202\350\0\370"
.ascii "\0\370\0\370\0\370\0\370E\241E\241\206\241\206\241\206\241\304\261"
.ascii "\2\365 \375\2\365\2\365 \375\2\365\37l\37l \375 \375 \375"
.ascii " \375\304\261E\241\206\241\206\241E\241E\241E\241\206\241"
.ascii "\202\350\0\370\0\370\0\370\0\370\0\370E\241E\241E\241E\241E\241"
.ascii "E\241 \375 \375 \375 \375 \375 \375\37l\37l \375 \375 \375"
.ascii " \375 \375 \375\37l\37l\206\241E\241E\241E\241\202\350\0\370"
.ascii "`\364 \375\202\350\0\370\0\370\0\370\0\370\0\370E\241E\241E\241"
.ascii "\304\261 \375 \375 \375 \375\37l\37l \375 \375 \375 \375"
.ascii "\2\365\2\365\37l\37lE\241E\241E\241E\241\202\350\0\370\"\333"
.ascii " \375\202\350\0\370\0\370\0\370\0\370\0\370\206\241\206\241\206\241"
.ascii "\304\261\2\365 \375\2\365\2\365\37l\37l \375 \375 \375"
.ascii " \375\37l\37l\37l\37l\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\37l\37l\37l\37l"
.ascii "E\241\37l\37l\37l\37l\37l\2\365\2\365\2\365\2\365\37l\37l\37l"
.ascii "\37l\202\350\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\37l\37l\37l\37lE\241\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\202\350\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370E\241E\241E\241\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\202\350\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\202\350\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\202\350\202\350\0\370\0\370\0\370\0\370\0\370\0\370\202\350"
.ascii "\202\350\347\330\202\350\347\330\202\350\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37lE\241E\241E\241\0\370\0\370\0\370\0\370\0\370\0\370\37l\37l"
.ascii "\37l\37l\37l\37l\202\350\0\370\0\370\0\370\0\370\0\370E\241"
.ascii "E\241E\241\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241\202\350"
.ascii "\202\350\202\350\347\330\347\330\347\330\37l\37l\37l\37l"
.ascii "\37l\37l\347\330\347\330\347\330\347\330\347\330\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241\206\241"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\206\241"
.ascii "E\241E\241\206\241\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\206\241E\241E\241E\241E\241E\241"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l"
.globl mario_walkl
mario_walkl:
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\352\231\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\352\231\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\347\330\347\330\347\330\347\330\347\330\347\330"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\203\350\347\330\347\330\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\202\350\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l`\364`\364E\241\304\261`\364`\364`\364"
.ascii "\"\333E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l \375`\364E\241"
.ascii "\304\261 \375 \375 \375`\364E\241E\241E\241E\241E\241\207\231"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\313\314\3\365\3\365\3\365 \375\2\365E\241\304\261 \375 \375"
.ascii " \375 \375`\364\"\323E\241\304\261 \375`\364\312\231\312\231"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\2\365 \375 \375"
.ascii " \375 \375`\364E\241\304\261 \375 \375 \375 \375 \375\"\333"
.ascii "E\241\"\333 \375 \375E\241\207\241\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\313\314\3\365 \375 \375 \375 \375\304\261\304\261"
.ascii "`\364`\364 \375 \375 \375`\364\304\261\304\261E\241\304\261"
.ascii " \375 \375\304\261\207\241\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\2\365 \375 \375 \375 \375 \375E\241\304\261 \375"
.ascii " \375 \375 \375 \375\"\333E\241E\241E\241\"\333 \375 \375E\241"
.ascii "\207\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\304\261"
.ascii "\304\261\304\261\304\261E\241E\241\304\261\304\261 \375"
.ascii " \375 \375 \375`\364`\364\2\365\"\333\304\261\304\261E\241"
.ascii "\207\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "E\241E\241E\241E\241E\241E\241\304\261 \375 \375 \375 \375 \375"
.ascii " \375 \375\"\333E\241E\241E\241\206\241\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\2\365`\364 \375`\364 \375"
.ascii " \375 \375 \375 \375 \375 \375 \375 \375\313\314\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\2\365 \375\2\365 \375 \375 \375 \375 \375 \375 \375 \375"
.ascii " \375\2\365\313\314\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\304\261E\241"
.ascii "\206\241E\241\0\370\0\370\0\370\202\350\304\261\206\241\207\241"
.ascii "\207\241\207\241\207\241\207\241\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241"
.ascii "\0\370\0\370\0\370\202\350\206\241E\241E\241E\241E\241E\241"
.ascii "E\241\207\241\37l\37l\37l\37l\37l\37l\2\365 \375\3\365\3\365"
.ascii " \375\3\365\305\251\207\241\207\241\207\241E\241E\241\0\370"
.ascii "\0\370\0\370\0\370\0\370\202\350E\241E\241E\241E\241E\241E\241"
.ascii "E\241\304\261\3\365 \375\3\365\3\365\37l\37l \375 \375 \375"
.ascii " \375 \375 \375E\241E\241E\241E\241E\241E\241\0\370\0\370"
.ascii "\0\370\0\370\0\370\202\350\206\241E\241E\241E\241\206\241\206\241"
.ascii "E\241\304\261 \375 \375 \375 \375\37l\37l \375 \375 \375"
.ascii " \375\304\261E\241E\241E\241\0\370\0\370\0\370\0\370\0\370\202\350"
.ascii " \375`\364\0\370\202\350E\241E\241E\241\207\241\37l\37l"
.ascii " \375 \375 \375 \375 \375 \375\37l\37l\2\365\2\365 \375\2\365"
.ascii "\304\261\206\241\206\241\206\241\0\370\0\370\0\370\0\370\0\370"
.ascii "\202\350 \375\"\333\0\370\202\350E\241E\241E\241E\241\37l"
.ascii "\37l\2\365\2\365 \375 \375 \375 \375\37l\37l\37l\37l\37lE\241"
.ascii "\37l\37l\37l\37l\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\37l\37l\37l\37l \375"
.ascii " \375 \375 \375\37l\37l\37l\37l\37lE\241\37l\37l\37l\37l"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\203\350\37l\37l\37l\37l\2\365\2\365\2\365"
.ascii "\2\365\37l\37l\37l\37l\37lE\241E\241E\241\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\203\350\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37lE\241E\241E\241\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\203\350\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37lE\241E\241E\241\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\203\350\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241"
.ascii "E\241E\241\0\370\0\370\0\370\0\370\0\370\0\370\202\350\306\340"
.ascii "\202\350\306\340\202\350\202\350\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\202\350\202\350\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37lE\241E\241E\241\0\370\0\370\0\370\0\370\0\370\203\350\37l"
.ascii "\37l\37l\37l\37l\37l\0\370\0\370\0\370\0\370\0\370\0\370E\241"
.ascii "E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\306\340\306\340\306\340\306\340\306\340\37l\37l\37l\37l\37l"
.ascii "\37l\306\340\306\340\306\340\202\350\202\350\202\350E\241E\241"
.ascii "E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\206\241"
.ascii "E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\206\241E\241E\241\206\241\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241\207\241"
.ascii "\37l\37l\37l\37l\37l"
.globl mario_slowr
mario_slowr:
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\347\330\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\347\330\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\347\330\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\347\330\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\214\301\347\330a\360\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370a\360\347\330"
.ascii "\347\330\347\330\347\330\347\330\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\347\330\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\347\330\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\353\231\345\240\345\240\345\240\345\240"
.ascii "\345\240\201\353`\364`\364`\364\201\353\345\240E\241`\364\201\353"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\353\231E\241E\241E\241E\241\345\240`\364@\375@\375"
.ascii "@\375`\364\345\240E\241@\375\347\334\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\353\231\353\231\201\353"
.ascii "@\375E\241\345\240\201\353`\364@\375@\375@\375@\375`\364"
.ascii "\345\240\201\353@\375@\375\347\334\347\334\347\334\347\334\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241\345\240`\364"
.ascii "@\375\201\353\345\240`\364@\375@\375@\375@\375@\375`\364\345\240"
.ascii "E\241@\375@\375@\375@\375@\375\347\334\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37lE\241E\241`\364@\375E\241E\241E\241"
.ascii "E\241`\364@\375@\375@\375@\375`\364`\364E\241\201\353@\375@\375"
.ascii "@\375@\375@\375\347\334\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "E\241\345\240`\364@\375\353\231E\241E\241E\241`\364@\375@\375"
.ascii "@\375@\375@\375`\364\345\240E\241@\375@\375@\375@\375@\375"
.ascii "@\375\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241"
.ascii "`\364@\375`\364`\364@\375@\375@\375@\375`\364E\241E\241E\241"
.ascii "E\241E\241E\241E\241\353\231\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37lE\241E\241E\241E\241`\364@\375@\375@\375@\375"
.ascii "@\375@\375@\375`\364\345\240E\241E\241E\241E\241E\241E\241\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\347\334@\375@\375@\375@\375@\375@\375@\375@\375`\364@\375"
.ascii "`\364@\375`\364\347\334\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\347\334@\375@\375@\375@\375@\375"
.ascii "@\375@\375@\375@\375@\375@\375@\375@\375\347\334\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241"
.ascii "E\241E\241a\360\0\370E\241E\241E\241E\241E\241E\241\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37lE\241E\241E\241a\360\0\370\345\240E\241E\241"
.ascii "E\241E\241E\241\353\231\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241a\360\0\370\0\370\0\370a\360E\241E\241E\241\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241a\360\0\370\0\370a\360"
.ascii "a\360E\241E\241E\241\353\231\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241a\360"
.ascii "\0\370\0\370\0\370a\360@\375`\364\0\370\0\370a\360a\360@\375"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241"
.ascii "E\241E\241E\241E\241E\241a\360\0\370\0\370\0\370a\360@\375"
.ascii "\201\353\0\370\0\370\0\370a\360@\375\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241a\360\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "a\360\0\370\347\330\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\345\240E\241E\241E\241E\241E\241E\241E\241a\360"
.ascii "a\360a\360a\360a\360\0\370\0\370\0\370\0\370\0\370\347\330\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\0\370\0\370"
.ascii "\345\240E\241E\241E\241`\364@\375@\375@\375@\375@\375`\364"
.ascii "\0\370\0\370\0\370\0\370\0\370\347\330\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37la\360\347\330\347\330E\241E\241"
.ascii "\345\240`\364@\375@\375@\375@\375@\375\201\353\0\370\0\370\0\370"
.ascii "\0\370\347\330\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\347\330\0\370\345\240E\241`\364@\375"
.ascii "@\375@\375`\364\0\370\0\370\0\370\0\370\0\370\347\330\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37la\360\345\240\345\240\201\353`\364`\364@\375\201\353\0\370"
.ascii "a\360a\360a\360a\360\347\330\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\347\330\0\370"
.ascii "\0\370\0\370\0\370\0\370a\360E\241E\241E\241E\241E\241\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\347\330a\360a\360a\360a\360a\360a\360E\241E\241"
.ascii "E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "E\241E\241E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241E\241\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241"
.ascii "E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l"
.globl mario_slowl
mario_slowl:
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\347\330\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\347\330\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\347\330\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\347\330\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\347\330\347\330\347\330\347\330"
.ascii "\347\330a\360\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370a\360\347\330\214\301\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\347\330\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\347\330\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\201\353`\364E\241\345\250\201\353"
.ascii "`\364`\364`\364\201\353\345\240\345\240\345\240\345\240"
.ascii "\345\240\353\231\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\347\334@\375E\241\345\240`\364@\375"
.ascii "@\375@\375`\364\345\240E\241E\241E\241E\241\353\231\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\347\334\347\334"
.ascii "\347\334\347\334@\375@\375\201\353\345\240`\364@\375@\375@\375"
.ascii "@\375`\364\201\343\345\240E\241@\375\201\343\353\231\353\231"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\347\334@\375@\375"
.ascii "@\375@\375@\375E\241\345\240`\364@\375@\375@\375@\375@\375"
.ascii "`\364\345\240\201\353@\375`\364\345\240E\241\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\347\334@\375@\375@\375@\375@\375\201\353"
.ascii "E\241`\364`\364@\375@\375@\375@\375`\364E\241E\241E\241E\241"
.ascii "@\375`\364E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l@\375"
.ascii "@\375@\375@\375@\375@\375E\241\345\240`\364@\375@\375@\375"
.ascii "@\375@\375`\364E\241E\241E\241\353\231@\375`\364\345\240E\241"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\352\231E\241"
.ascii "E\241E\241E\241E\241E\241E\241`\364@\375@\375@\375@\375`\364"
.ascii "`\364@\375`\364E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241\345\240"
.ascii "`\364@\375@\375@\375@\375@\375@\375@\375`\364E\241E\241E\241"
.ascii "E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\347\334"
.ascii "`\364@\375`\364@\375`\364@\375@\375@\375@\375@\375@\375"
.ascii "@\375@\375\347\334\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\346\334@\375@\375@\375@\375@\375"
.ascii "@\375@\375@\375@\375@\375@\375@\375@\375\347\334\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241\0\370\201\360"
.ascii "E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\353\231E\241E\241E\241E\241"
.ascii "E\241\345\240\0\370a\360E\241E\241E\241\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241"
.ascii "E\241E\241a\360\0\370\0\370\0\370a\360E\241E\241E\241E\241"
.ascii "E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\353\231E\241E\241E\241a\360a\360\0\370"
.ascii "\0\370a\360E\241E\241E\241E\241E\241E\241E\241E\241\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l \375a\360a\360"
.ascii "\0\370\0\370`\364 \375a\360\0\370\0\370\0\370a\360E\241E\241"
.ascii "E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l@\375a\360\0\370\0\370\0\370\201\353@\375a\360"
.ascii "\0\370\0\370\0\370a\360E\241E\241E\241E\241E\241E\241\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\347\330\0\370"
.ascii "a\360\0\370\0\370\0\370\0\370\0\370\0\370\0\370a\360E\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\347\330\0\370\0\370\0\370\0\370\0\370"
.ascii "a\360a\360a\360a\360a\360E\241E\241E\241E\241E\241E\241"
.ascii "E\241\5\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\347\330\0\370\0\370\0\370\0\370\0\370`\364@\375 \375 \375"
.ascii " \375 \375`\364E\241E\241E\241\345\240\0\370\0\370\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\347\330\0\370"
.ascii "\0\370\0\370\0\370\201\353@\375@\375@\375@\375@\375`\364\345\240"
.ascii "E\241E\241\347\330\347\330a\360\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\347\330\0\370\0\370\0\370"
.ascii "\0\370\0\370`\364@\375@\375@\375`\364E\241\345\240\0\370\347\330"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\347\330a\360a\360a\360a\360\0\370\201\353@\375"
.ascii "`\364`\364\201\353\345\240\345\240a\360\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241"
.ascii "E\241E\241E\241E\241a\360\0\370\0\370\0\370\0\370\0\370\347\330"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241a\360a\360a\360"
.ascii "a\360a\360a\360\347\330\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241E\241E\241"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241"
.ascii "E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241"
.ascii "E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l"
.globl mario_stopl
mario_stopl:
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\7\331\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\7\331\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\7\331\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\7\331\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\7\331\7\331a\360\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\7\331\7\331"
.ascii "\7\331\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37lE\241a\360\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370a\360\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241\4\251"
.ascii "\4\251\4\251\4\251\4\251\4\251\4\251\4\251\301\353\200\364"
.ascii "\301\353\4\251$\272\301\353\346\344\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241E\241E\241\4\251\200\364@\375\200\364\4\251$\272@\375"
.ascii "\346\344\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\200\364\200\364$\272E\241\301\353\200\364\200\364\200\364"
.ascii "$\272E\241\301\353\200\364@\375@\375\200\364\200\364\200\364"
.ascii "@\375@\375\346\344\346\344\346\344\346\344\37l\37l\37l\37l"
.ascii "\37l\37l\37l@\375@\375@\375@\375$\272\4\251\301\353@\375@\375"
.ascii "@\375$\272\4\251\301\353@\375@\375@\375@\375@\375@\375@\375"
.ascii "@\375@\375@\375@\375\346\344\37l\37l\37l\37l\37l\37l\37l@\375"
.ascii "@\375@\375@\375$\272E\241\200\364@\375@\375@\375$\272E\241$\272"
.ascii "E\241\200\364@\375@\375@\375\200\364E\241E\241$\272$\272"
.ascii "@\375@\375\346\344\346\344\37l\37l\37l\37l\37l@\375@\375@\375"
.ascii "@\375$\272\4\251\301\353@\375@\375@\375$\272E\241E\241\4\251"
.ascii "\301\353@\375@\375@\375\301\353E\241E\241\4\251$\272@\375@\375"
.ascii "@\375@\375\37l\37l\37l\37l\37l\37l\37l\37l@\375\200\364\200\364"
.ascii "$\272E\241\200\364@\375\200\364\200\364\200\364\200\364"
.ascii "@\375@\375@\375@\375@\375\200\364\301\353E\241E\241$\272\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l@\375@\375@\375$\272"
.ascii "E\241\301\353@\375@\375@\375@\375@\375@\375@\375@\375@\375@\375"
.ascii "@\375\200\364E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\7\331a\360a\360\0\370a\360a\360\4\251E\241"
.ascii "$\272E\241E\241$\272\4\251a\360a\360@\375@\375\200\364\346\344"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\7\331"
.ascii "\0\370\0\370\0\370\0\370\0\370\4\251E\241E\241E\241E\241E\241"
.ascii "\4\251\0\370a\360@\375@\375@\375\346\344\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\7\331a\360\0\370\0\370\301\353@\375"
.ascii "@\375\200\364@\375@\375$\272E\241a\360\0\370\0\370\0\370"
.ascii "a\360$\272E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\7\331\0\370\0\370\0\370\301\353@\375@\375@\375@\375"
.ascii "@\375$\272E\241a\360\0\370\0\370\0\370a\360E\241E\241E\241"
.ascii "E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\7\331\0\370"
.ascii "\4\251E\241\200\364@\375@\375@\375@\375@\375$\272E\241E\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\7\331\0\370\4\251\4\251\301\353@\375"
.ascii "@\375@\375@\375@\375$\272E\241E\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\7\331\0\370\0\370\0\370\0\370\0\370\301\353@\375@\375@\375"
.ascii "$\272E\241E\241E\241E\241E\241E\241E\241E\241E\241E\241E\241"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\7\331a\360\0\370\0\370"
.ascii "\0\370\0\370\301\353@\375\200\364@\375$\272\4\251E\241E\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\7\331\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\4\251E\241E\241E\241E\241E\241"
.ascii "E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\7\331\0\370\0\370a\360\0\370a\360\0\370a\360\0\370"
.ascii "\0\370\4\251\4\251E\241\4\251\4\251E\241E\241\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\7\331\0\370\4\251"
.ascii "E\241E\241E\241E\241E\241a\360\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\7\331\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\7\331\7\331\4\251E\241E\241E\241E\241E\241"
.ascii "a\360a\360\0\370\0\370\0\370\0\370\0\370\0\370\7\331\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37lE\241E\241E\241E\241E\241E\241E\241a\360\0\370\0\370"
.ascii "\0\370\0\370\0\370\7\331\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\4\251\4\251\4\251E\241E\241"
.ascii "E\241E\241a\360a\360a\360\0\370a\360a\360\7\331\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241\37l\37l\37lE\241"
.ascii "a\360\0\370\0\370\0\370\4\251E\241E\241E\241E\241E\241\4\251"
.ascii "\0\370\7\331\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37lE\241E\241\37l\37l\37lE\241a\360a\360a\360a\360\4\251\4\251"
.ascii "\37l\37l\37l\37l\37l\7\331\7\331\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241E\241a\360\0\370\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241\7\331\7\331\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241E\241\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241"
.ascii "E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l"
.globl mario_stopr
mario_stopr:
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\7\331\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\10\331\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\7\331\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\10\331\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\7\331\7\331\7\331\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370a\360\10\331"
.ascii "\10\331\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37la\360\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370a\360E\241\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\301\353$\272\4\251\301\353\200\364\301\353\4\251\4\251\4\251"
.ascii "\4\251\4\251\4\251\4\251\4\251E\241E\241\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l@\375$\272\4\251"
.ascii "\200\364@\375\200\364\344\250E\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l@\375@\375\200\364\200\364\200\364@\375@\375"
.ascii "\200\364\301\353E\241$\272\200\364\200\364\200\364\301\353"
.ascii "E\241$\272\200\364\200\364\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l@\375@\375@\375@\375@\375@\375@\375@\375@\375@\375@\375"
.ascii "\301\353\4\251$\272@\375@\375@\375\301\353\4\251$\272@\375@\375"
.ascii "@\375@\375\37l\37l\37l\37l\37l\37l\37l@\375@\375$\272$\272"
.ascii "E\241E\241\200\364@\375@\375@\375\200\364E\241$\272E\241$\272"
.ascii "@\375@\375@\375\200\364E\241$\272@\375@\375@\375@\375\37l"
.ascii "\37l\37l\37l\37l@\375@\375@\375@\375$\272\4\251E\241E\241\301\353"
.ascii "@\375@\375@\375\301\353\344\250E\241E\241$\272@\375@\375"
.ascii "@\375\301\353\344\250$\272@\375@\375@\375@\375\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l#\272E\241E\241\301\353\200\364@\375@\375"
.ascii "@\375@\375@\375\200\364\200\364\200\364\200\364@\375\200\364"
.ascii "E\241$\272\200\364\200\364@\375\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37lE\241E\241E\241\200\364@\375@\375@\375@\375@\375"
.ascii "@\375@\375@\375@\375@\375@\375\301\353E\241$\272@\375@\375"
.ascii "@\375\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\346\344"
.ascii "\200\364@\375@\375a\360a\360\4\251$\272E\241E\241$\272E\241"
.ascii "\4\251a\360a\360\0\370a\360a\360\10\331\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\346\344@\375@\375@\375A\360"
.ascii "\0\370\4\251E\241E\241E\241E\241E\241\344\250\0\370\0\370\0\370"
.ascii "\0\370\0\370\10\331\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37lE\241E\241E\241E\241$\272a\360\0\370\0\370\0\370a\350"
.ascii "E\241$\272@\375@\375\200\364@\375@\375\301\353\0\370\0\370"
.ascii "a\350\10\331\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241"
.ascii "E\241E\241E\241a\360\0\370\0\370\0\370a\360E\241$\272@\375"
.ascii "@\375@\375@\375@\375\301\353\0\370\0\370\0\370\10\331\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241E\241E\241E\241$\272@\375@\375@\375@\375@\375\200\364"
.ascii "E\241\4\251\0\370\10\331\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37lE\241E\241E\241E\241E\241E\241E\241E\241E\241E\241"
.ascii "E\241$\272@\375@\375@\375@\375@\375\301\353\4\251\4\251\0\370"
.ascii "\10\331\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241E\241$\272@\375@\375@\375"
.ascii "\301\353\0\370\0\370\0\370\0\370\0\370\10\331\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241E\241\4\251$\272@\375\200\364@\375\301\353\0\370"
.ascii "\0\370\0\370\0\370a\360\7\331\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241E\241\4\251"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\10\331"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "E\241E\241\4\251\4\251E\241\4\251\4\251\0\370\0\370a\360\0\370"
.ascii "a\360\0\370a\360\0\370\0\370\10\331\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\7\331\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370a\360E\241E\241E\241E\241E\241\4\251"
.ascii "\0\370\10\331\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\7\331\0\370\0\370\0\370\0\370\0\370\0\370a\360"
.ascii "a\360E\241E\241E\241E\241E\241\4\251\7\331\7\331\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\7\331\0\370"
.ascii "\0\370\0\370\0\370\0\370a\360E\241E\241E\241E\241E\241E\241"
.ascii "E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\7\331A\360A\360\0\370a\360a\360a\360E\241"
.ascii "E\241E\241E\241\4\251\4\251\4\251\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\7\331\0\370"
.ascii "\4\251E\241E\241E\241E\241E\241\4\251\0\370\0\370\0\370"
.ascii "a\350E\241\37l\37l\37lE\241E\241\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\7\331\7\331\37l\37l\37l\37l\37l\4\251"
.ascii "\4\251a\360a\360a\360a\360E\241\37l\37l\37lE\241E\241\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\0\370a\350E\241E\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\7\331\7\331E\241E\241E\241"
.ascii "E\241E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37lE\241E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241E\241\37l\37l"
.ascii "\37l\37l\37l"
.globl mario_dead
mario_dead:
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\201\350\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\355\261\355\261\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l \375 \375\37l\37l"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\37l\37l\37l \375 \375\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l \375\240\364\37l\37l\300\371\300\371\201\350"
.ascii "\201\350\201\350\300\371\300\371\300\371\300\371\201\350"
.ascii "\201\350\300\371\300\371\355\261\37l\37l\240\364 \375\37l\37l"
.ascii "\37l\37l\37l \375 \375 \375 \375 \375\240\375\240\364E\241"
.ascii "E\241 \375\240\375D\272\345\230b\333\240\375\240\375\240\375"
.ascii " \375E\241\345\230\240\364\240\375b\333\345\230E\241\240\364"
.ascii "\240\375 \375 \375 \375 \375 \375 \375 \375 \375 \375 \375\240\364"
.ascii "b\333E\241E\241\240\364\240\375D\272\345\230b\333\240\375"
.ascii " \375\240\375\240\364E\241E\241\240\364\240\375D\272\345\230"
.ascii "\345\230\240\364\240\364 \375 \375 \375 \375 \375 \375 \375"
.ascii " \375\240\375b\333\345\230E\241E\241E\241\240\364\240\375D\272"
.ascii "\345\230b\333 \375 \375 \375\240\364E\241E\241\240\364\240\375"
.ascii "D\272E\241E\241\345\230\345\230b\333\240\375 \375 \375"
.ascii " \375 \375 \375 \375\240\375b\333\345\230E\241E\241E\241\240\364"
.ascii "\240\375D\272\345\230b\333\240\375 \375 \375 \375E\241\345\230"
.ascii "\240\364\240\375D\272\345\230E\241E\241\345\230b\333\240\375"
.ascii " \375 \375 \375 \375 \375 \375\240\375b\333E\241E\241E\241"
.ascii "E\241E\241E\241b\333 \375\240\364 \375 \375 \375 \375\240\364"
.ascii " \375D\272E\241E\241E\241E\241E\241\345\230b\333\240\375"
.ascii " \375 \375 \375 \375 \375 \375\240\375b\333\345\230E\241E\241"
.ascii "E\241E\241\345\230\240\364\240\375 \375 \375 \375 \375 \375"
.ascii "\240\375\240\375D\272E\241E\241E\241E\241E\241E\241b\333\240\375"
.ascii " \375 \375 \375\37l\37l\37l\37l\37lE\241E\241E\241E\241"
.ascii "E\241E\241D\272D\272b\333\240\375 \375 \375 \375D\272D\272E\241"
.ascii "E\241E\241E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37lE\241E\241E\241E\241\345\230\345\230\345\230\345\230"
.ascii "b\333\240\375\240\375\240\375 \375E\241\345\230\345\230"
.ascii "\345\230E\241E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37lE\241E\241b\333b\333E\241\345\230D\272b\333"
.ascii "b\333b\333b\333\345\230E\241b\333b\333D\272\345\230E\241"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241"
.ascii "E\241 \375\240\375D\272\345\230\345\230\345\230\345\230\345\230"
.ascii "\345\230\345\230\345\230\240\364\240\375D\272\345\230E\241"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241"
.ascii "E\241\240\364\240\375b\333D\272D\272D\272D\272D\272D\272D\272"
.ascii "D\272\240\364\240\375b\333\345\230E\241\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241\240\364\240\375"
.ascii " \375\240\375\240\375 \375\240\375 \375\240\375 \375\240\375"
.ascii "\240\375\240\375D\272\345\230E\241\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241\240\364\240\364"
.ascii " \375 \375 \375 \375 \375 \375 \375 \375 \375\240\364 \375D\272"
.ascii "E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370b\333\240\375 \375 \375"
.ascii " \375 \375 \375 \375\240\375\201\350\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\240\364 \375 \375 \375 \375 \375"
.ascii " \375 \375\240\375\201\350\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241\344\300\0\370"
.ascii "\0\370\0\370\0\370\344\300D\272D\272D\272D\272D\272E\241"
.ascii "D\272D\272\201\350\0\370\0\370\0\370\0\370\344\300\344\300E\241"
.ascii "\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241\0\370\0\370"
.ascii "\0\370\0\370\344\300\345\230\345\230\345\230\345\230\345\230"
.ascii "E\241\345\230\345\230\201\350\0\370\0\370\0\370\0\370E\241"
.ascii "E\241E\241E\241\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241"
.ascii "\344\300\344\300\0\370\0\370\201\350\344\300\344\300E\241E\241"
.ascii "E\241E\241\344\300\201\350\0\370\0\370\201\350\344\300\344\300"
.ascii "E\241E\241E\241E\241\37l\37l\37l\37l\37l\37lE\241E\241E\241"
.ascii "E\241E\241E\241\0\370\0\370\0\370\0\370\201\350E\241E\241"
.ascii "E\241E\241\0\370\0\370\0\370\0\370\344\300E\241E\241E\241E\241"
.ascii "E\241E\241\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241"
.ascii "E\241\0\370\0\370\0\370\0\370\344\300E\241E\241E\241E\241\0\370"
.ascii "\0\370\0\370\0\370\344\300E\241E\241E\241E\241E\241E\241"
.ascii "\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241\0\370"
.ascii "\0\370b\333 \375\300\371\201\350\201\350\0\370\201\350\240\364"
.ascii "\240\364\201\350\0\370\344\300E\241E\241E\241E\241E\241E\241"
.ascii "\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241\0\370"
.ascii "\0\370\240\364\240\375b\333\0\370\0\370\0\370\201\350\240\375"
.ascii "\240\375\201\350\0\370\344\300E\241E\241E\241E\241E\241E\241"
.ascii "\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241\0\370"
.ascii "\0\370\300\371\300\371\300\371\0\370\0\370\0\370\0\370\300\371"
.ascii "\300\371\201\350\0\370\344\300E\241E\241E\241E\241E\241"
.ascii "E\241\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\344\300E\241E\241E\241E\241E\241E\241\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\344\300E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37lE\241E\241E\241E\241\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\344\300E\241"
.ascii "E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241"
.ascii "E\241E\241E\241\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\344\300E\241E\241E\241"
.ascii "E\241\37l\37l\37l\37l\37l"
.globl mario_jumpr
mario_jumpr:
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l \375 \375 \375 \375"
.ascii " \375 \375\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l \375"
.ascii " \375 \375 \375 \375 \375\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\345\340\345\340\345\340\345\340\345\340\345\340"
.ascii "\345\340\345\340\345\340\345\340\37l\37l\37l\37l \375 \375"
.ascii " \375 \375 \375 \375\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\37l\37l\37l\37l#\355`\375 \375 \375 \375 \375\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\345\340\345\340\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\345\340\345\340"
.ascii "\345\340\345\340\345\340\345\340 \375 \375 \375 \375\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370`\375`\375 \375 \375\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l$\261$\261$\261$\261$\261\344\261\300\364"
.ascii "\300\364\300\364\301\343$\261$\261\301\343\300\364\37l"
.ascii "\37l$\261$\261\344\261\344\261\344\261\344\261\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241\344\261"
.ascii "`\375 \375`\375\301\343E\241E\241\300\364#\355\37l\37lE\241E\241"
.ascii "E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\311\231"
.ascii "\311\231#\355\301\343E\241\344\261\300\364\300\364 \375 \375"
.ascii "`\375\301\343E\241E\241\300\364`\375#\355\346\344E\241E\241"
.ascii "E\241E\241E\241E\241\37l\37l\37l\37l\37l\37l\37l\37lE\241"
.ascii "\344\261`\375\300\364E\241\344\261`\375`\375 \375 \375`\375\301\343"
.ascii "E\241E\241\300\364 \375 \375\300\364E\241E\241E\241E\241"
.ascii "E\241E\241\37l\37l\37l\37l\37l\37l\37l\37l\311\231E\241`\375"
.ascii "\300\364E\241E\241\344\261\344\261`\375 \375 \375\300\364"
.ascii "\300\364\300\364\344\261\344\261 \375`\375\300\364\300\364 \375"
.ascii "\301\343E\241E\241\37l\37l\37l\37l\37l\37l\37l\37lE\241\344\261"
.ascii "`\375\300\364E\241E\241E\241\344\261`\375 \375 \375 \375"
.ascii " \375`\375E\241E\241\300\364 \375 \375 \375`\375\300\364E\241"
.ascii "E\241\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241E\241\344\261"
.ascii "\300\364\300\364\300\364\300\364 \375 \375`\375\301\343E\241"
.ascii "E\241E\241E\241\344\261E\241\344\261E\241\344\261\311\231"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\311\231E\241E\241\344\261"
.ascii "`\375`\375 \375 \375 \375 \375`\375\301\343E\241E\241E\241"
.ascii "E\241E\241E\241E\241E\241E\241\311\231\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l \375 \375`\375 \375 \375"
.ascii " \375 \375 \375\300\364 \375 \375\300\364 \375\300\364E\241"
.ascii "\311\231\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\300\364 \375\300\364 \375\300\364 \375\300\364"
.ascii " \375 \375 \375\300\364 \375 \375\300\364E\241\311\231\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\311\231E\241E\241E\241E\241E\241"
.ascii "E\241E\241E\241$\261\0\370\345\340E\241E\241E\241E\241E\241\344\261"
.ascii "\0\370\0\370E\241\311\231\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\311\231E\241E\241E\241E\241E\241E\241E\241E\241"
.ascii "$\261\0\370\0\370E\241E\241E\241E\241E\241E\241\0\370\0\370E\241"
.ascii "\311\231\37l\37l\37l\37l\37l\37l\37l\37l\311\231E\241E\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241E\241E\241E\241$\261\0\370"
.ascii "\345\340E\241E\241E\241E\241E\241E\241\0\370\345\340\37l\37l"
.ascii "\37l\37lE\241E\241\37l\37l\311\231\344\261E\241E\241E\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241E\241$\261\0\370\0\370E\241"
.ascii "E\241E\241$\261E\241E\241\0\370\345\340\37l\37l\37l\37lE\241"
.ascii "E\241 \375 \375 \375 \375E\241E\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241E\241E\241$\261\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\345\340\37l\37l\37l\37lE\241E\241 \375"
.ascii " \375 \375 \375\344\261\344\261\311\231E\241E\241$\261$\261$\261"
.ascii "E\241E\241E\241$\261\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\345\340\37l\37l\37l\37lE\241E\241 \375 \375"
.ascii " \375 \375 \375 \375\37l\37l\0\370\0\370\0\370\0\370E\241$\261"
.ascii "\0\370\0\370\0\370\301\343`\375\301\343\0\370\0\370\0\370"
.ascii "\0\370`\375 \375\0\370\0\370E\241E\241E\241E\241#\355#\355 \375"
.ascii " \375#\355\346\344\37l\37l\0\370\0\370\0\370\0\370E\241$\261"
.ascii "\0\370\0\370\0\370\345\340`\375\301\343\0\370\0\370\0\370"
.ascii "\0\370\300\364\300\364\0\370\0\370E\241E\241E\241E\241\37l\37l"
.ascii "\346\344 \375\37l\37l\311\231E\241\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370E\241E\241E\241E\241\37l"
.ascii "\37l\346\344\346\344\37l\37l\311\231$\261\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370E\241E\241E\241E\241"
.ascii "\37l\37l\37l\37l\311\231E\241E\241E\241E\241E\241\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370E\241E\241E\241E\241\37l"
.ascii "\37l\37l\37l\311\231E\241E\241E\241$\261$\261\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\345\340\345\340\345\340\345\340\345\340\345\340\37l\37l\37l"
.ascii "\37l\37l\37l\311\231E\241E\241E\241E\241E\241\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\311\231"
.ascii "E\241\311\231\311\231\311\231\311\231\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\345\340\345\340\345\340\345\340"
.ascii "\345\340\345\340\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\311\231E\241\37l\37l\37l\37l\345\340\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\345\340\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\311\231E\241\37l\37l"
.ascii "\37l\37l\0\370\0\370\0\370\0\370\0\370\0\370\0\370\345\340\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii ""
.globl mario_jumpl
mario_jumpl:
.ascii " \375 \375 \375 \375 \375 \375\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l \375 \375 \375 \375 \375 \375\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l \375 \375 \375 \375 \375 \375\37l"
.ascii "\37l\37l\37l\345\340\345\340\345\340\345\340\345\340\345\340"
.ascii "\345\340\345\340\345\340\345\340\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l \375 \375 \375 \375\200\375$\355\37l\37l"
.ascii "\37l\37l\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l \375"
.ascii " \375 \375 \375\345\340\345\340\345\340\345\340\345\340\345\340"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\345\340\345\340\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii " \375 \375`\375`\375\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\344\261\344\261"
.ascii "\344\261\344\261$\261$\261\37l\37l\240\364\301\343$\261"
.ascii "$\261\301\343\240\364\240\364\240\364\344\261$\261$\261$\261"
.ascii "$\261$\261\37l\37l\37l\37l\37l\37l\37l\37l\37l\37lE\241E\241"
.ascii "E\241E\241E\241E\241\37l\37l#\355\240\364E\241E\241\301\343`\375"
.ascii " \375`\375\344\261E\241E\241E\241E\241E\241\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241\346\344"
.ascii "$\355`\375\240\364E\241E\241\301\343`\375 \375 \375\300\364"
.ascii "\300\364\344\261E\241\301\343\3\355\311\231\311\231\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37lE\241E\241E\241E\241E\241E\241\300\364"
.ascii " \375 \375\300\364E\241E\241\301\343`\375 \375 \375`\375"
.ascii "`\375\344\261E\241\300\364`\375\344\261E\241\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37lE\241E\241\301\343 \375\240\364\240\364`\375"
.ascii " \375\344\261\344\261\300\364\300\364\300\364 \375 \375`\375"
.ascii "\344\261\344\261E\241E\241\300\364`\375E\241\311\231\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37lE\241E\241\300\364`\375 \375 \375 \375"
.ascii "\300\364E\241E\241\200\375 \375 \375 \375 \375`\375\344\261"
.ascii "E\241E\241E\241\300\364`\375\344\261E\241\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\311\231\344\261E\241\344\261E\241\344\261"
.ascii "E\241E\241E\241E\241\301\343`\375 \375 \375\300\364\300\364"
.ascii "\300\364\300\364\344\261E\241E\241E\241\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\311\231E\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241E\241\301\343`\375 \375 \375 \375 \375`\375`\375\344\261"
.ascii "E\241E\241\311\231\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\311\231E\241\300\364 \375\300\364 \375 \375\300\364"
.ascii " \375 \375 \375 \375 \375`\375 \375 \375\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\311\231E\241"
.ascii "\300\364 \375 \375\300\364 \375 \375 \375\300\364 \375\300\364"
.ascii " \375\300\364 \375\300\364\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\311\231E\241\0\370"
.ascii "\0\370\344\261E\241E\241E\241E\241E\241\345\340\0\370$\261E\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241\312\231\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\311\231E\241\0\370\0\370E\241E\241"
.ascii "E\241E\241E\241E\241\0\370\0\370$\261E\241E\241E\241E\241E\241"
.ascii "E\241E\241E\241\311\231\37l\37l\37l\37lE\241E\241\37l\37l"
.ascii "\37l\37l\345\340\0\370E\241E\241E\241E\241E\241E\241\345\340"
.ascii "\0\370$\261E\241E\241E\241E\241E\241E\241E\241E\241E\241E\241"
.ascii "E\241E\241\312\231\37l\37lE\241E\241\37l\37l\37l\37l\305\340"
.ascii "\0\370E\241E\241$\261E\241E\241E\241\0\370\0\370$\261E\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241E\241E\241E\241\344\261\311\231"
.ascii "\37l\37lE\241E\241\37l\37l\37l\37l\305\340\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370$\261E\241E\241E\241"
.ascii "E\241E\241E\241E\241E\241E\241E\241E\241 \375 \375 \375 \375"
.ascii "E\241E\241\37l\37l\37l\37l\305\340\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370$\261E\241E\241E\241$\261$\261"
.ascii "$\261E\241E\241\311\231\344\261\344\261 \375 \375 \375 \375E\241"
.ascii "E\241E\241E\241\0\370\0\370 \375`\375\0\370\0\370\0\370\0\370"
.ascii "\301\343`\375\301\343\0\370\0\370\0\370$\261E\241\0\370"
.ascii "\0\370\0\370\0\370\37l\37l \375 \375 \375 \375 \375 \375E\241"
.ascii "E\241E\241E\241\0\370\0\370\300\364\300\364\0\370\0\370\0\370"
.ascii "\0\370\301\343`\375\345\340\0\370\0\370\0\370$\261E\241\0\370"
.ascii "\0\370\0\370\0\370\37l\37l\346\344#\355 \375 \375#\355#\355"
.ascii "E\241E\241E\241E\241\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370E\241\312\231\37l\37l \375\346\344\37l"
.ascii "\37lE\241E\241E\241E\241\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370$\261\311\231\37l\37l\346\344\346\344"
.ascii "\37l\37lE\241E\241E\241E\241\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370E\241E\241E\241E\241E\241\312\231\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\305\340\305\340\305\340\305\340\305\340"
.ascii "\305\340\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\0\370$\261$\261E\241E\241E\241\311\231\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370E\241E\241E\241E\241E\241\312\231\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\305\340\305\340\305\340"
.ascii "\305\340\305\340\305\340\0\370\0\370\0\370\0\370\0\370\0\370"
.ascii "\0\370\0\370\311\231\311\231\311\231\311\231E\241\311\231\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\305\340\0\370\0\370\0\370\0\370\0\370\0\370\345\340"
.ascii "\37l\37l\37l\37lE\241\311\231\37l\37l\37l\37l\37l\37l\37l\37l"
.ascii "\37l\37l\37l\37l\37l\37l\37l\37l\37l\37l\305\340\0\370\0\370"
.ascii "\0\370\0\370\0\370\0\370\0\370\37l\37l\37l\37lE\241\311\231"
.ascii "\37l\37l"
