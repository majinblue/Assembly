.globl mario_animate
mario_animate:
push    {r4-r10, lr}
addr .req    r8
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
//game pause status
mpause  .req    r4
ldr     mpause, =pause
ldrb    mpause, [mpause]
//mario direction
direct  .req    r5
//collision information
collide .req    r7
//delete old mario sprite
    ldr     r0,     =map_current        //current map's address
    mov     r1,     xloc                //x axis of mario
    mov     r2,     yloc                //y axis of mario
    bl      offset_block                //find out what block mario is ontop of
    mov     r0, r3                      //mov that old block into r0
    bl      draw                        //draw old block back in place
//check if mario has run into an enemy block
    ldr     addr,   =collide_data       //collide data address
    ldrb    collide,    [addr, #4]      //#4 is the block behind mario
    cmp     collide,    #4              //goomba
    beq     mario_death
    cmp     collide,    #5              //death block
    beq     mario_death
//check if mario has fallen off map
    cmp yloc,   #24                     //fallen vertically past the last block
    beq mario_death
//check if game was recently unpaused
    cmp mpause, #1                      //game was unpaused
    bne mario_fall
    mov mpause, #0                      //change to unpaused
    ldr addr,   =pause                  //addres for pause status
    str mpause, [addr]                  //store new pause status
    b   mario_update_done               //restore mario to unpaused state
//check if mario is in the process of dying
    ldr addr,   =mario_sprite
    ldr r0, [addr]
    ldr r1, =0x2006
    cmp r0, r1
    beq mario_death
//determine mario's sprite
//falling mario
mario_fall:
    ldr     addr,   =mario_coord
    ldrb     r8, [addr,#1]
    ldr     addr,   =mario_jump_count   //jump count
    ldrb    direct, [addr]
    ldr     r6,     =0x99               //jump has been cancelled for some reason
    cmp     direct, r6
    beq     mario_fall_continue
    cmp     direct, #0                  //jump count is 0, mario is not jumping
    beq     mario_move
    b       mario_jump
mario_fall_continue:
    add     yloc,   #1                  //fall
    ldr     addr,   =mario_direct       //check if mario is also moving in a certain direction
    ldrb    direct, [addr]
    cmp     direct, #0                  //no direction
    bne     mario_fall_directional      //go process direction
mario_fall_straight:
    ldr     r6,     =0x606
    ldr     addr,   =mario_sprite
    ldrh    sprite, [addr]
    cmp     sprite, r6                  //determine which way to fall (jump sprite still)
    ldrlt   sprite, =0x506              //stand right
    ldrgt   sprite, =0x1506             //stand left
    b       mario_update                //update mario coordianates and animation
mario_fall_directional:
    ldr     addr,   =mario_direct       //check if mario is also moving in a certain direction
    ldrb    direct, [addr]
    cmp     direct, #1                  //movement to the right
    addeq   xloc,   #1                  //add 1 to xaxis (right)
    ldreq   sprite, =0x506              //jump right
    sub     xloc,   #1                  //sub 1 to xaxis (left)
    ldr     sprite, =0x1506             //jump left
    b       mario_update                //update mario coordianates and animation
//jumping mario
mario_jump:
    ldr     addr,   =mario_jump_count   //jump count
    cmp     direct, #0                  //jump count is 0, mario is not jumping
    subgt   yloc,   #1                  //decrement mario's y-axis to simulate jump
    ldr     addr,   =mario_direct       //check if mario is also moving in a certain direction
    ldrb    direct, [addr]
    cmp     direct, #0                  //no direction
    bne     mario_jump_directional      //go process direction
mario_jump_straight:
    ldr r6, =0x606
    ldr     addr,   =mario_sprite
    ldrh    sprite, [addr]
    cmp     sprite, r6                  //determine which way to fall (jump sprite still)
    ldrlt   sprite, =0x506              //jump right
    ldrgt   sprite, =0x1506             //jump left
    b       mario_update                //update mario coordianates and animation
mario_jump_directional:
    ldr     addr,   =mario_direct       //check if mario is also moving in a certain direction
    ldrb    direct, [addr]
    cmp     direct, #1                  //movement to the right
    addeq   xloc,   #1                  //add 1 to xaxis (right)
    ldreq   sprite, =0x506              //jump right
    sub     xloc,   #1                  //sub 1 to xaxis (left)
    ldr     sprite, =0x1506             //jump left
    b       mario_update                //update mario coordianates and animation
//standing mario (no input)
mario_stand:
    ldr r6, =0x606
    ldr     addr,   =mario_sprite
    ldrh    sprite, [addr]
    cmp     sprite, r6                  //determine which way to stand
    ldrlt   sprite, =0x6                //stand right
    ldrgt   sprite, =0x1006             //stand left
    b       mario_update_done           //otherwise done
//left and right mario
mario_move:
    ldr     addr,   =mario_direct       //check if mario is also moving in a certain direction
    ldrb    direct, [addr]
    cmp     direct, #0                  //no direction
    beq     mario_stand                 //not falling/jumping, not moving, so standing
    cmp     direct, #1
    beq     mario_right                 //mario is ONLY moving right
    b       mario_left                  //mario is ONLY moving left
mario_right:
    add     xloc,   #1                  //move to the right once
    ldr     r6,     =0x606
    ldr     addr,   =mario_sprite       //mario sprite address
    ldrh    sprite, [addr]              //previous sprite
    cmp     sprite, r6                  //compare
    ldrgt   sprite, =0x1406             //previously went in opposite direction
    bgt     mario_update                //update to fast stop and turn sprite
    ldr     addr,   =mario_count        //address for direction count
    ldr     direct, [addr]              //load how many rights mario has walked
    //direct(mod3)
    mov     addr,   #4                  //#4
    mov     r6,     direct              //move count to r6 register
    sdiv    r6,     addr                //r6/4
    mul     r6,     addr                //r6*4
    sub     direct, r6                  //direct - r6 = mario's # of rights modulo 4
    //compare to sprite number
    cmp     direct, #0
    ldreq   sprite, =0x106
    cmp     direct, #1
    ldreq   sprite, =0x206
    cmp     direct, #2
    ldreq   sprite, =0x306
    b       mario_update
mario_left:
    sub     xloc,   #1                  //move to the left once
    ldr     r6,     =0x606
    ldr     addr,   =mario_sprite       //mario sprite address
    ldrh    sprite, [addr]              //previous sprite
    cmp     sprite, r6                  //compare
    ldrlt   sprite, =0x406              //previously went in opposite direction
    bgt     mario_update                //update to fast stop and turn sprite
    ldr     addr,   =mario_count        //address for direction count
    ldr     direct, [addr]              //load how many rights mario has walked
    //direct(mod3)
    mov     addr,   #4                  //#4
    mov     r6,     direct              //move count to r6 register
    sdiv    r6,     addr                //r6/4
    mul     r6,     addr                //r6*4
    sub     direct, r6                  //direct - r6 = mario's # of rights modulo 4
    //compare to sprite number
    cmp     direct, #0
    ldreq   sprite, =0x1106
    cmp     direct, #1
    ldreq   sprite, =0x1206
    cmp     direct, #2
    ldreq   sprite, =0x1306
    b       mario_update
//checks for collisions, reverts/updates mario's coordinates
//animates mario
mario_update:
    //summarize movement, then check for collisions
    ldr     addr,   =mario_coord        //mario coordinate address
    ldrb    direct, [addr, #0]          //old mario x coordinate
    cmp     xloc,   direct              //check if it is the same as the new one
    blt     mario_update_w              //check west side for collisions
    bgt     mario_update_e              //check east side for collisions
    ldrb    direct, [addr, #1]          //old mario y coordinate
    cmp     yloc,   direct              //check if it is the same as the new one
    bgt     mario_update_s              //check south side for collisions
    blt     mario_update_n              //check north side for collisions
    ldrb    xloc,   [addr, #0]          //old mario x coordinate
    ldrb    yloc,   [addr, #1]          //old mario y coordinate
    b       mario_stand                 //no movement (stand)
    mario_update_w:
        //west collision check
        ldr addr,   =collide_data       //collide data address
        ldrb    collide,    [addr, #3]  //#3 is the block W of mario
        cmp collide,    #0
        beq mario_update_west           //movement okay
        cmp collide,    #1
        addeq   xloc,   #1              //can't move this way
        beq mario_update_west
        cmp collide,    #2
        addeq   xloc,   #1              //can't move this way
        beq mario_update_west
        cmp collide,    #3
        addeq   xloc,   #1              //can't move this way
        beq mario_update_west
        cmp collide,    #4
        beq mario_update_west           //movement okay
        cmp collide,    #5
        beq mario_update_west           //movement okay
    mario_update_west:
        ldr addr,   =collide_data       //collide data address
        ldrb    direct, [addr, #1]      //old mario y coordinate
        cmp     xloc,   direct          //check if it is the same as the new one
        blt     mario_update_sw         //check south side for collisions
        bgt     mario_update_nw         //check north side for collisions
        b       mario_update_done       //done check
        //southwest collision check
        mario_update_sw:
            ldr addr,   =collide_data       //collide data address
            ldrb    collide,    [addr, #0]  //#0 is the block SW of mario
            cmp collide,    #0
            beq mario_update_done           //movement okay
            cmp collide,    #1
            subeq   yloc,   #1              //can't move this way
            beq mario_update_done
            cmp collide,    #2
            subeq   yloc,   #1              //can't move this way
            beq mario_update_done
            cmp collide,    #3
            subeq   yloc,   #1              //can't move this way
            beq mario_update_done
            cmp collide,    #4
            bl  mario_kill                  //jump on goomba animation
            beq mario_update_done
            cmp collide,    #5
            beq mario_update_done           //movement okay
        //northwest collision check
        mario_update_nw:
            ldr addr,   =collide_data       //collide data address
            ldrb    collide,    [addr, #6]  //#6 is the block NW of mario
            cmp collide,    #0
            beq mario_update_done       //movement okay
            cmp collide,    #1
            add yloc,       #1          //can't move this way
            beq mario_update_done
            cmp collide,    #2
            bl  mario_coin              //coin animation
            beq mario_update_done
            cmp collide,    #3
            bl  mario_break             //break wook animation
            beq mario_update_done
            cmp collide,    #4
            beq mario_update_done       //movement okay
            cmp collide,    #5
            beq mario_update_done       //movement okay
    mario_update_e:
        //east collision check
        ldr addr,   =collide_data       //collide data address
        ldrb    collide,    [addr, #5]  //#5 is the block E of mario
        cmp collide,    #0
        beq mario_update_east           //movement okay
        cmp collide,    #1
        subeq   xloc,   #1              //can't move this way
        beq mario_update_east
        cmp collide,    #2
        subeq   xloc,   #1              //can't move this way
        beq mario_update_east
        cmp collide,    #3
        subeq   xloc,   #1              //can't move this way
        beq mario_update_east
        cmp collide,    #4
        beq mario_update_east           //movement okay
        cmp collide,    #5
        beq mario_update_east           //movement okay
    mario_update_east:
        ldr addr,   =collide_data       //collide data address
        ldrb    direct, [addr, #1]      //old mario y coordinate
        cmp     xloc,   direct          //check if it is the same as the new one
        blt     mario_update_se         //check south side for collisions
        bgt     mario_update_ne         //check north side for collisions
        b       mario_update_done       //done check
        //southeast collision check
        mario_update_se:
            ldr addr,   =collide_data       //collide data address
            ldrb    collide,    [addr, #2]  //#2 is the block SE of mario
            cmp collide,    #0
            beq mario_update_done           //movement okay
            cmp collide,    #1
            subeq   yloc,   #1              //can't move this way
            beq mario_update_done
            cmp collide,    #2
            subeq   yloc,   #1              //can't move this way
            beq mario_update_done
            cmp collide,    #3
            subeq   yloc,   #1              //can't move this way
            beq mario_update_done
            cmp collide,    #4
            bl  mario_kill                  //jump on goomba animation
            beq mario_update_done
            cmp collide,    #5
            beq mario_update_done           //movement okay
        //northeast collision check
        mario_update_ne:
            ldr addr,   =collide_data       //collide data address
            ldrb    collide,    [addr, #8]  //#8 is the block NE of mario
            cmp collide,    #0
            beq mario_update_done           //movement okay
            cmp collide,    #1
            add yloc,       #1              //can't move this way
            beq mario_update_done
            cmp collide,    #2
            bl  mario_coin                  //coin animation
            beq mario_update_done
            cmp collide,    #3
            bl  mario_break                 //break wook animation
            beq mario_update_done
            cmp collide,    #4
            beq mario_update_done           //movement okay
            cmp collide,    #5
            beq mario_update_done           //movement okay
    //south collision check
    mario_update_s:
        ldr addr,   =collide_data           //collide data address
        ldrb    collide,    [addr, #1]      //#1 is the block S of mario
        cmp collide,    #0
        beq mario_update_done               //movement okay
        cmp collide,    #1
        subeq   yloc,   #1                  //can't move this way
        beq mario_update_done
        cmp collide,    #2
        subeq   yloc,   #1                  //can't move this way
        beq mario_update_done
        cmp collide,    #3
        subeq   yloc,   #1                  //can't move this way
        beq mario_update_done
        cmp collide,    #4
        bl  mario_kill                      //jump on goomba animation
        beq mario_update_done
        cmp collide,    #5
        beq mario_update_done               //movement okay
    //north collision check
    mario_update_n:
        ldr addr,   =collide_data           //collide data address
        ldrb    collide,    [addr, #7]      //#7 is the block N of mario
        cmp collide,    #0
        beq mario_update_done               //movement okay
        cmp collide,    #1
        add yloc,       #1                  //can't move this way
        beq mario_update_done
        cmp collide,    #2
        bl  mario_coin                      //coin animation
        beq mario_update_done
        cmp collide,    #3
        bl  mario_break                     //break wook animation
        beq mario_update_done
        cmp collide,    #4
        beq mario_update_done               //movement okay
        cmp collide,    #5
        beq mario_update_done               //movement okay
//update mario's coordinates and draw mario
mario_update_done:
    //check if mario can still jump
    ldr     addr,   =mario_jump_count   //jump count
    ldrb    direct, [addr]
    cmp     direct, #4                  //jumped four blocks consecutively
    ldreq   direct, =0x99               //cancel jump
    str     direct, [addr]              //update jump
    //check if mario is walking into left/right walls
    cmp     xloc,   #0
    addlt   xloc,   #1
    cmp     xloc,   #31
    subgt   xloc,   #1
    //check if mario passed x=24, in which case the screen must scroll the map
    cmp     xloc,   #25
    blgt    screen_scroll
    subgt   xloc,   #2
    //update mario coordinates
    ldr     addr,   =mario_coord
    strb    xloc,   [addr]
    strb    yloc,   [addr, #1]
    //update mario sprite
    ldr     addr,   =mario_sprite
    str     sprite, [addr]
    //draw mario
    mov     r0, sprite
    mov     r1, xloc
    mov     r2, yloc
    bl      draw_outline
    b       mario_done
//jump on goomba, remove goomba, update score
mario_kill:
    push    {lr}
    add yloc,   #1                      //goomba below mario
    ldr addr,   =map_current            //current map address
    add r6, xloc,   yloc,   lsl #5
    lsl r6, #1
    ldr sprite, =0x7300                 //sky block to replace goomba
    strh    sprite, [addr,  r6]         //store in current map
    bl  draw                            //draw it on screen
    ldr addr,   =stat_score             //player's current score
    ldrb r6, [addr,#1]                  //hundreds place digit
    ldrb direct, [addr]                 //thousands place digit
    add r6, #1                          //add 100 points
    cmp r6, #10                         //if this digit (hundreds place) is more than 10:
    moveq   r6, #0                      //change to zero and...
    addeq   direct, #1                  //change to 1000 points
    strb    r6, [addr,#1]               //update score 100s
    strb    direct, [addr]              //update score 1000s
    //restore mario sprite and position
    sub     yloc,   #2                  //sub 1 for mario's position, then 1 to jump off goomba
    ldrb    direct, =0x99               //disable jumping, it is a jump of one block only
    ldr     addr,   =mario_jump_count   //jump count address
    strb    direct, [addr]              //update the jump count
    ldr r6, =0x606
    cmp     sprite, r6                  //determine which way to jump
    ldrlt   sprite, =0x506              //jump facing right
    ldrgt   sprite, =0x1506             //jump facing left
    b       mario_update                //update mario coordianates and animation
    //done goomba kill animation
    pop {lr}
    mov pc, lr
//break wooden block, and also kill goomba if it is ontop of it
mario_break:
    push    {lr}
    //cancel any remaining jump
    ldr r6, =mario_jump_count
    ldr direct, =0x99
    str direct, [r6]
    //current map draw and update to sky (broke the wood block)
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
    ldr addr,   =0x4                        //goomba block 2
    cmp sprite, addr
    ldreq   sprite, =0x7300                 //load over goomba block in map
    bleq    draw                            //draw over goomba
    beq     mario_score_update
    ldr addr,   =0x104                      //goomba block 1
    cmp sprite, addr
    ldreq   sprite, =0x7300                 //load over goomba block in map
    bleq    draw                            //draw over goomba
    beq     mario_score_update
    //done break block animation
    pop {lr}
    mov pc, lr
    //update score if goomba was killed
    mario_score_update:
        ldr addr,   =stat_score
        ldrb r6, [addr,#1]
        ldrb direct, [addr]
        addeq r6, #1
        cmp r6, #10
        moveq   r6, #0
        addeq   direct, #1
        strb    r6, [addr,#1]
        strb    direct, [addr]
    //restore mario position
    add yloc, #3
    //done break block animation
    pop {lr}
    mov pc, lr
mario_coin:
    push    {lr}
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
    //restore mario position
    add yloc, #3
    //done break block animation
    pop {lr}
    mov pc, lr
//mario is on the same block as an enemy/hole
mario_death:
    ldr sprite, =0x2006
    ldr     addr,   =mario_death_jump
    ldrb    r6, [addr]
    cmp     r6, #4
    blt     mario_dies_jump             //jumps 4 times before falling
    b       mario_dies_fall             //falls until offscreen
mario_dies_jump:
    add     r6, #1
    str     r6, [addr]
    ldr     addr,   =mario_coord
    ldrb    xloc,   [addr]              //ignore x-axis movement
    ldrb    yloc,   [addr,#1]
    sub     yloc,   #1                  //decrement y-axis (jumping)
    b       mario_update_done           //update mario animation
mario_dies_fall:
    ldr     addr,   =mario_coord
    ldrb    xloc,   [addr]              //ignore x-axis movement
    ldrb    yloc,   [addr,#1]           //increment y-axis (falling)
    add     yloc,   #1
    cmp     yloc,   #24
    ble     mario_update_done           //update mario animation
    ldr     addr,   =stat_lives         //address for player's life count
    ldr     direct, [addr]
    sub     direct, #1                  //subtract 1 life
    str     direct, [addr]
    cmp     direct, #0                  //if no lives are left
    moveq   r0,     #4                  //game lost status returned to game controller
    beq     mario_done                  //game over 0 lives remain
    ldr     addr,   =mario_coord        //address to mario's coordinates
    mov     xloc,   #15                 //reset to x=15
    mov     yloc,   #0                  //reset to y=0
    strb    xloc,   [addr]              //store x
    strb    yloc,   [addr,#1]           //store y
    ldr     addr,   =mario_death_jump   //address to mario death jump count
    ldrb    r6, [addr]
    mov     r6, #0                      //reset to 0 so this loop won't be triggered
    strb    r6, [addr]                  //till next death
    ldr     addr,   =mario_sprite       //default mario sprite
    ldr     sprite, =0x6
    strb    sprite, [addr]              //store sprite
    ldr     addr,   =mario_direct       //default neutral input direction
    mov     direct, #0
    strb    direct, [addr]              //store direction
    b       mario_update_done           //game resumes and mario falls from the sky
//everything is done now
mario_done:
    .unreq  sprite
    .unreq  xloc
    .unreq  yloc
    .unreq  addr
    .unreq  mpause
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
