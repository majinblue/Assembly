.globl  screen_current
//draw current map
screen_current:
    push    {r4-r10, lr}
    ldr	r4,	=map_current    //updated current map layout
    mov r5, #0              //halfword number
    mov	r6,	#32
    ldrb r10, =#768
    ldr     r3,    =FrameBufferPointer
    ldr     r3,    [r3]
    b   screen_Loop

.globl  screen_replace
//redraw and replace entire map
screen_replace:
     push {r4-r10, lr}
    //range: 0-127 (31 blocks for each map)
    new_map .req    r8              //incoming map
    mov     new_map,    r0          //r0 argument inputs desired map
    cur_map .req    r9
    ldr     cur_map,    =map_current
    //new blocks
    block   .req    r0
    //compare incoming blocks with current ones
    old_x   .req    r1      //x coordinate
    mov     old_x,  #0
    old_y   .req    r2      //y coordinate
    mov     old_y,  #0
    old_b   .req    r3      //block
    offset  .req    r10     //map data offset
map_replace:
    //map offset = [old_x + (old_y * 32)] * 2 (because 2 bytes represents each map coordinate)
    mov     offset, #0
    add     offset, old_y,  lsl #5
    add     offset, old_x
    lsl     offset, #1
    ldrh    block,  [new_map,  offset]
    strh    block,  [cur_map,  offset]
    bl      draw
skip_replace:
    add     old_x,  #1
    cmp     old_x,  #31
    movgt   old_x,  #0
    addgt   old_y,  #1
    cmp     old_y,  #23
    bgt     replace_done
    b       map_replace
replace_done:
    .unreq  new_map
    .unreq  block
    .unreq  old_x
    .unreq  old_y
    .unreq  offset
    b       update_Finished

.globl  screen_clear
//clear screen
screen_clear:
    push    {r4-r10, lr}
    ldr	r4,	=quit           //black screen layout
    mov r5, #0              //halfword number
    mov	r6,	#32
    ldrb r10, =#768
    ldr     r3,    =FrameBufferPointer
    ldr     r3,    [r3]
    b   screen_Loop

.globl  screen_scroll
//screen scroll
//when mario steps past half x of the screen, load next block from new map
//only redraw blocks that have changed
screen_scroll:
    push {r4-r10, lr}
    //range: 0-127 (31 blocks for each map)
    range_f .req    r6              //first x block on current map
    range_l .req    r7              //last x block on current map
    new_map .req    r8              //incoming map
    //check if we have completely scrolled through map
    ldr r10,    =map_range
    ldrb r1, [r10,#1]
    cmp r1, #125
    bgt no_scroll
    //load current map
    current_map .req    r9
    ldr     current_map,    =map_current
    //new blocks
    block   .req    r0
    xaxis   .req    r1
    yaxis   .req    r2
    mov     yaxis,  #0
    //compare incoming blocks above with current ones
    old_b   .req    r3
    old_x   .req    r4
    mov     old_x,  #0
    old_y   .req    r5
    mov     old_y,  #0
    //offset
    offset  .req    r10
    //check which map to scroll
    ldr     range_f,    =map_range
    ldrb    range_f,     [range_f]
    ldr     range_l,    =map_range
    ldrb    range_l,     [range_l,  #1]
    cmp     range_l,    #62
    ldrle   new_map,    =map2
    ble     map_shift
    cmp     range_l,    #94
    ldrle   new_map,    =map3
    ble     map_shift
    ldr     new_map,    =map4
    b       map_shift
//shift all map_current blocks to the left
map_shift:
    //new block map offset = [(old_x + 2)+ (old_y * 32)] * 2
    add     offset, old_x,   old_y,   lsl #5
    add     offset, #1
    lsl     offset, #1
    ldrh    block,  [current_map,  offset]
    //old block map offset = [old_x + (old_y * 32)] * 2
    add     offset, old_x,   old_y,   lsl #5
    lsl     offset, #1
    ldrh    old_b,  [current_map,  offset]
    //replace block (redraw and remap) if necessary
    cmp     old_b,  block
    beq     skip_draw
    strh    block,  [current_map,  offset]
    mov     xaxis,  old_x
    mov     yaxis,  old_y
    bl      draw
skip_draw:
    add     old_x,  #1
    cmp     old_x,  #31
    movgt   old_x,  #0
    addgt   old_y,  #1
    beq     map_insert
    cmp     old_y,  #24
    beq     scroll_done
    b       map_shift
map_insert:
    ldr     range_f,    =map_range
    ldrb    range_f,     [range_f]
    ldr     range_l,    =map_range
    ldrb    range_l,     [range_l,  #1]
    //new map offset = [(range_l+1)(mod32) + (yaxis *32)) *2
    mov     xaxis,  #32
    add     range_l,    #1
    sdiv    xaxis,  range_l,    xaxis
    mov     old_b,  #32
    mul     xaxis,  xaxis,      old_b
    sub     offset, range_l,    xaxis
    add     offset, offset,     old_y, lsl #5
    lsl     offset, #1
    ldrh    block,  [new_map,   offset]
    //map offset = [old_x + (old_y * 32)] * 2 (because 2 bytes represents each map coordinate)
    mov     offset, #0
    add     offset, old_x,  old_y,  lsl #5
    lsl     offset, #1
    ldrh    old_b,  [current_map,  offset]
    cmp     old_b,  block
    beq     skip_draw
    mov     r1, old_x
    mov     r2, old_y
    strh    block,  [current_map,  offset]
    bl      draw
    b       skip_draw
scroll_done:
    ldr     r8, =map_range
    ldrb    range_f, [r8]
    add     range_f,#1
    strb    range_f,    [r8]
    ldrb    range_l, [r8,#1]
    add     range_l,#1
    strb    range_l,    [r8, #1]
    .unreq  block
    .unreq  old_x
    .unreq  old_y
    .unreq  current_map
    .unreq  xaxis
    .unreq  yaxis
    .unreq  offset
no_scroll:
    .unreq  range_f
    .unreq  range_l
    .unreq  new_map
    bl      text_game
    b       update_Finished

.globl  screen_swap
//screen swap
//when the current map needs to be switched out completely
//load new map onto current map data
//ie start/end/restart game
screen_swap:
    push {r4-r10, lr}
    //range: 0-127 (31 blocks for each map)
    new_map .req    r8              //incoming map
    mov     new_map,    r0          //r0 argument inputs desired map
    cur_map .req    r9
    ldr     cur_map,    =map_current
    //new blocks
    block   .req    r0
    //compare incoming blocks with current ones
    old_x   .req    r1      //x coordinate
    mov     old_x,  #0
    old_y   .req    r2      //y coordinate
    mov     old_y,  #0
    old_b   .req    r3      //block
    offset  .req    r10     //map data offset
map_update:
    //map offset = [old_x + (old_y * 32)] * 2 (because 2 bytes represents each map coordinate)
    mov     offset, #0
    lsl     offset, old_y,  #5
    add     offset, old_x
    lsl     offset, #1
    ldrh    old_b,  [cur_map,  offset]
    ldrh    block,  [new_map,  offset]
    cmp     old_b,  block
    beq     skip_swap
    strh    block,  [cur_map,  offset]
    bl      draw
skip_swap:
    add     old_x,  #1
    cmp     old_x,  #31
    movgt   old_x,  #0
    addgt   old_y,  #1
    cmp     old_y,  #23
    bgt     swap_done
    b       map_update
swap_done:
    .unreq  new_map
    .unreq  block
    .unreq  old_x
    .unreq  old_y
    .unreq  offset
    b       update_Finished

.globl  screen_overlay
//screen overlay
//when the current map needs to be switched out completely
//ie pause game
screen_overlay:
    push {r4-r10, lr}
    //range: 0-127 (31 blocks for each map)
    range_f .req    r6              //first x block on current map
    range_l .req    r7              //last x block on current map
    new_map .req    r8              //incoming map
    current_map .req    r9
    ldr     current_map,    =map_current
    ldr     range_f,    =map_range
    ldrb    range_f,    [range_f]
    ldr     range_l,    =map_range
    ldrb    range_l,    [range_l,  #1]
    mov     new_map,    r0          //r0 argument inputs desired map
    //new blocks
    block   .req    r0
    //compare incoming blocks above with current ones
    old_b   .req    r3
    old_x   .req    r1
    mov     old_x,  #0
    old_y   .req    r2
    mov     old_y,  #0
    //offset
    offset  .req    r10
map_overlay:
    //map offset = [old_x + (old_y * 32)] * 2 (because 2 bytes represents each map coordinate)
    mov     offset, #0
    add     offset, old_y,  lsl #5
    add     offset, old_x
    lsl     offset, #1
    ldrh    block,  [new_map,   offset]
    ldrh    old_b,  [current_map,  offset]
    cmp     old_b,  block
    beq     skip_overlay
    bl      draw
skip_overlay:
    add     old_x,  #1
    cmp     old_x,  #31
    movgt   old_x,  #0
    addgt   old_y,  #1
    cmp     old_y,  #23
    bgt     overlay_done
    b       map_overlay
overlay_done:
    .unreq  range_f
    .unreq  range_l
    .unreq  new_map
    .unreq  block
    .unreq  old_x
    .unreq  old_y
    .unreq  offset
    b       update_Finished

//for drawing entire map
screen_Loop:
    lsl     r7, r5, #1
    ldrh	r0,	[r4,r7]     //halfwords from map
    sdiv    r2,	r5, r6      //y coordinate block number
    mul	r1,	r2, r6
    sub r1, r5, r1          //x coordinate block number
    bl  draw
    add r5, #1
    cmp r5, r10             //last block
    beq update_Finished
    b   screen_Loop

update_Finished:
    pop    {r4-r10,lr}
    mov     pc, lr
