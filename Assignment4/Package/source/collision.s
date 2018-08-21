.globl collision_handler
collision_handler:
    push {r4-r10,lr}
    marx    .req    r4          //mario x location
    mary    .req    r5          //mario y location
    addr    .req    r7          //used for addressing
    blox    .req    r8          //block x location
    by      .req    r9          //block y location
    bup_r0  .req    r10         //backup r0
    mov bup_r0, r0
col_mario_locate:
    ldr addr,   =mario_coord
    mov     r0,     addr
    ldrb    marx,   [addr]
    ldrb    mary,   [addr,#1]
col_wall:
//bottom
    add by, mary,   #1
    cmp by, #22
    bleq    col_block_dead
    beq col_left_right
    //SW
    add by, mary,   #1
    sub blox, marx,   #1
    bl  col_block_analyze
    //S
    add by, mary,   #1
    mov blox, marx
    bl  col_block_analyze
    //SE
    add by, mary,   #1
    add blox, marx, #1
    bl  col_block_analyze
//left andright
col_left_right:
    //W
    mov by, mary
    sub blox, marx,   #1
    bl  col_block_analyze
    //E
    mov by, mary
    add blox, marx, #1
    bl  col_block_analyze
//top
    //NW
    sub by, mary,   #1
    sub blox, marx,   #1
    bl  col_block_analyze
    //N
    sub by, mary,   #1
    mov blox, marx
    bl  col_block_analyze
    //NE
    sub by, mary,   #1
    add blox, marx, #1
    bl  col_block_analyze
    b   col_done

//find and analyze block
col_block_analyze:
    push {lr}
    ldr r0, =map_current
    mov r1, blox
    mov r2, by
    bl  offset_block            //block data returns in r3
    bl  block_analyze
    pop {lr}
    mov     pc, lr

//done
col_done:
    .unreq  addr                //used for addressing
    .unreq  blox                //block x location
    .unreq  by                  //block y location
    mov r0, bup_r0
    .unreq  bup_r0
    pop {r4-r10,lr}
    mov     pc, lr

//compares newly drawn enemy to mario's location
//inputs
//r1 = xb
//r2 = yb
//r3 = block
//outputs
//r3 = block
//r4 = marx
//r5 = mary
.globl col_animate
col_animate:
    push {r4-r10,lr}
    ldr r8, =mario_coord
    ldrb    r4, [r8]            //mario's current x-coord
    ldrb    r5, [r8, #1]        //mario's current y-coord
    cmp     r1, r4              //compare x-coord of mario and animated object
    bne     skip_col_enemy      //doesn't match, ignore enemy
    cmp     r2, r5              //compare y-coord of mario and animated object
    bne     skip_col_enemy      //doesn't match, ignore enemy
    bl  block_analyze
skip_col_enemy:
    pop {r4-r10,lr}
    mov     pc, lr

//arguments
//r1 = block x axis
//r2 = block y axis
//r3 = block data
block_analyze:
    push {r6-r10,lr}
    cmbl    .req    r6          //register stores hex to compare
    stat    .req    r7          //status to store back onto collide_data
    block   .req    r8          //type of block
    offset  .req    r9          //offset for store to collide data
    addr    .req    r10         //addres register
    mov block,  r3              //save block data
//goomba
    ldr cmbl,   =0x4
    cmp block,  cmbl
    moveq   stat,   #4
    beq block_store
    ldr cmbl,   =0x104
    cmp block,  cmbl
    moveq   stat,   #4
    beq block_store
//spike
    ldr cmbl,   =0x9
    cmp block,  cmbl
    moveq   stat,   #5
    beq block_store
    ldr cmbl,   =0x109
    cmp block,  cmbl
    moveq   stat,   #5
    beq block_store
    ldr cmbl,   =0x1009
    cmp block,  cmbl
    moveq   stat,   #5
    beq block_store
    ldr cmbl,   =0x1109
    cmp block,  cmbl
    moveq   stat,   #5
    beq block_store
//mystery box
    ldr cmbl,   =0x6d00
    cmp block,  cmbl
    moveq   stat,   #2
    beq block_store
//wood box
    ldr cmbl,   =0x7700
    cmp block,  cmbl
    moveq   stat,   #3
    beq block_store
//sky and hole
    ldr cmbl,   =0x6200
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x7300
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
//cloud
    ldr cmbl,   =0x1
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x101
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x1001
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x1101
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
//plants
    ldr cmbl,   =0x8                //first plant block of first set
collide_plant_loop:
    ldr stat,   =0xf08              //borrow stat reg for comparison
    cmp cmbl,   stat                //first plant set check done
    ldreq   cmbl,   =0x1008         //start second plant set
    ldr stat,   =0x1408             //borrow stat reg for comparison
    cmp cmbl,   stat                //second plant set check done
    ldreq   cmbl,   =0x2008         //start third plant set
    ldr stat,   =0x2308             //borrow stat reg for comparison
    cmp cmbl,   stat                //third plant set check done
    ldreq   cmbl,   =0x3008         //start fourth plant set
    ldr stat,   =0x3a08             //borrow stat reg for comparison
    cmp cmbl,   stat                //fourth plant set check done
    beq collide_others              //no plant blocks, check others
    cmp block,  cmbl                
    moveq   stat,   #0
    beq block_store
    add cmbl,   #0x100              //next block of a set
    b   collide_plant_loop
//flags, clouds, and such
collide_others:
//flag
    ldr cmbl,   =0x3
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x103
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x1003
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x1103
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x2003
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x2103
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
//clouds
    ldr cmbl,   =0x1
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x101
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x1001
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x1101
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x2001
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x2101
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x3001
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x3101
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x4001
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x4101
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x5001
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x5101
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
//elements
    ldr cmbl,   =0x2
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x102
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x202
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
    ldr cmbl,   =0x302
    cmp block,  cmbl
    moveq   stat,   #0
    beq block_store
//otherwise collide
collide_yes:
    mov stat,   #1
    b   block_store
block_store:
    ldr addr,   =collide_data
    cmp r2, mary
    bgt south_store
    beq store
    blt north_store
south_store:
    cmp r1, marx
    //0 is SW
    movlt   offset, #0
    //1 is S
    moveq   offset, #1
    //2 is SE
    movgt   offset, #2
    b   store_block
store:
    cmp r1, marx
    //3 is W
    movlt   offset, #3
    //4 is what mario is infront of
    moveq   offset, #4
    //5 is E
    movgt   offset, #5
    b   store_block
north_store:
    cmp r1, marx
    //6 is NW
    movlt   offset, #6
    //7 is N
    moveq   offset, #7
    //8 is NE
    movgt   offset, #8
    b   store_block
store_block:
    strb    stat,  [addr, offset]
    .unreq marx
    .unreq mary
    .unreq  stat
    .unreq  block
    .unreq  offset
    pop {r6-r10,lr}
    mov pc,lr

col_block_dead:
    push {r7-r10,lr}
    ldr r7,   =collide_data
    mov r8, #5                  //dead if entering this block
    strb    r8, [r7]            //SW
    strb    r8, [r7,#1]         //S
    strb    r8, [r7,#2]         //SE
    pop {r7-r10,lr}
    mov pc, lr
