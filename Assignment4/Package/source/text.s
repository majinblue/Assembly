.globl  text_menu
text_menu:
    push    {r4-r10, lr}
    mov     r1, #3                      //32*32 block x-coordinate
    mov     r2, #22                     //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_creator           //"start game" text to r0
    ldr     r2, =colour_white           //hex colour to r2
    mov     r3, #26                     //number of letters in creator label
    bl      text_loop                   //write letter on screen
    mov     r1, #11                     //32*32 block x-coordinate
    mov     r2, #14                     //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_start             //"start game" text to r0
    ldr     r2, =colour_white           //hex colour to r2
    mov     r3, #10                     //number of letters in "start game"
    bl      text_loop                   //write letter on screen
    mov     r1, #11                     //32*32 block x-coordinate
    mov     r2, #16                     //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_quit              //"quit game" text
    ldr     r2, =colour_black           //16-bit hex colour
    mov     r3, #9                      //number of letters in "quit game"
    bl      text_loop                   //write letter on screen
    pop     {r4-r10,lr}
    mov     pc, lr

.globl  text_game
text_game:
    push    {r4-r10, lr}
    mov     r1, #28                     //32*32 block x-coordinate
    mov     r2, #2                      //32*32 block y-coordinate
    ldr     r0, =0x7300                 //sky block
    bl      draw                        //draw block
    mov     r1, #28                     //32*32 block x-coordinate
    mov     r2, #2                      //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =stat_lives             //lives count
    ldr     r2, =colour_white           //16-bit hex colour
    mov     r3, #1                      //number of letters in number
    bl      num_to_hex
    mov     r1, #25                     //32*32 block x-coordinate
    mov     r2, #2                      //32*32 block y-coordinate
    ldr     r0, =0x302                  //mushroom block
    bl      draw                        //draw block
    mov     r1, #26                     //32*32 block x-coordinate
    mov     r2, #2                      //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_lives             //lives text
    ldr     r2, =colour_white           //16-bit hex colour
    mov     r3, #2                      //number of letters in x03
    bl      text_loop                   //write letter on screen
    mov     r1, #3                      //32*32 block x-coordinate
    mov     r2, #1                      //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_mario             //"mario" text to r0
    ldr     r2, =colour_white           //hex colour to r2
    mov     r3, #5                      //number of letters in mario label
    bl      text_loop                   //write letter on screen
    mov     r1, #18                     //32*32 block x-coordinate
    mov     r2, #1                      //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_world             //"world" text to r0
    ldr     r2, =colour_white           //hex colour to r2
    mov     r3, #5                      //number of letters in world
    bl      text_loop
    mov     r1, #3                      //32*32 block x-coordinate
    mov     r2, #2                      //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_score             //"start game" text to r0
    ldr     r2, =colour_white           //hex colour to r2
    mov     r3, #2                      //number of letters in score"
    bl      text_loop                   //write letter on screen
    mov     r1, #5                      //32*32 block x-coordinate
    mov     r2, #2                      //32*32 block y-coordinate
    ldr     r0, =0x7300                 //sky block
    bl      draw                        //draw block
    mov     r1, #6                      //32*32 block x-coordinate
    mov     r2, #2                      //32*32 block y-coordinate
    ldr     r0, =0x7300                 //sky block
    bl      draw                        //draw block
    mov     r1, #7                      //32*32 block x-coordinate
    mov     r2, #2                      //32*32 block y-coordinate
    ldr     r0, =0x7300                 //sky block
    bl      draw                        //draw block
    mov     r1, #8                      //32*32 block x-coordinate
    mov     r2, #2                      //32*32 block y-coordinate
    ldr     r0, =0x7300                 //sky block
    bl      draw                        //draw block
    mov     r1, #5                      //32*32 block x-coordinate
    mov     r2, #2                      //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =stat_score             //lives count
    ldr     r2, =colour_white           //16-bit hex colour
    mov     r3, #4                      //number of letters in number
    bl      num_to_hex
    mov     r1, #19                     //32*32 block x-coordinate
    mov     r2, #2                      //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_one               //level text
    ldr     r2, =colour_white           //16-bit hex colour
    mov     r3, #3                      //number of letters in 1-1
    bl      text_loop                   //write letter on screen
    mov     r1, #11                     //32*32 block x-coordinate
    mov     r2, #2                      //32*32 block y-coordinate
    ldr     r0, =0x2                    //coin block
    bl      draw                        //draw block
    mov     r1, #12                     //32*32 block x-coordinate
    mov     r2, #2                      //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_coins             //coins text
    ldr     r2, =colour_white           //16-bit hex colour
    mov     r3, #2                      //number of letters in x00
    bl      text_loop                   //write letter on screen
    mov     r1, #14                     //32*32 block x-coordinate
    mov     r2, #2                      //32*32 block y-coordinate
    ldr     r0, =0x7300                 //sky block
    bl      draw                        //draw block
    mov     r1, #14                     //32*32 block x-coordinate
    mov     r2, #2                      //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =stat_coins             //lives count
    ldr     r2, =colour_white           //16-bit hex colour
    mov     r3, #1                      //number of letters in number
    bl      num_to_hex
    pop     {r4-r10,lr}
    mov     pc, lr

.globl  text_pause
text_pause:
    push    {r4-r10, lr}
    mov     r1, #3                      //32*32 block x-coordinate
    mov     r2, #22                     //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_creator           //"start game" text to r0
    ldr     r2, =colour_white           //hex colour to r2
    mov     r3, #26                     //number of letters in creator label
    bl      text_loop                   //write letter on screen
    mov     r1, #11                     //32*32 block x-coordinate
    mov     r2, #11                     //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_continue          //"continue" text to r0
    ldr     r2, =colour_white           //hex colour to r2
    mov     r3, #8                      //number of letters in "continue"
    bl      text_loop                   //write letter on screen
    mov     r1, #11                     //32*32 block x-coordinate
    mov     r2, #13                     //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_return            //"main menu" text
    ldr     r2, =colour_orange          //16-bit hex colour
    mov     r3, #9                      //number of letters in "main menu"
    bl      text_loop                   //write letter on screen
    pop     {r4-r10,lr}
    mov     pc, lr

.globl  text_pause_clear
text_pause_clear:
    push    {r4-r10, lr}
    mov     r1, #3                      //32*32 block x-coordinate
    mov     r2, #22                     //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_creator           //"start game" text to r0
    ldr     r2, =colour_black           //hex colour to r2
    mov     r3, #26                     //number of letters in creator label
    bl      text_loop                   //write letter on screen
    bl      text_loop                   //write letter on screen
    pop     {r4-r10,lr}
    mov     pc, lr

.globl  text_win_menu
text_win_menu:
    push    {r4-r10, lr}
    mov     r1, #3                      //32*32 block x-coordinate
    mov     r2, #22                     //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_creator           //"start game" text to r0
    ldr     r2, =colour_white           //hex colour to r2
    mov     r3, #26                     //number of letters in creator label
    bl      text_loop                   //write letter on screen
    mov     r1, #11                     //32*32 block x-coordinate
    mov     r2, #11                     //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_win               //"you win" text to r0
    ldr     r2, =colour_white           //hex colour to r2
    mov     r3, #8                      //number of letters in "continue"
    bl      text_loop                   //write letter on screen
    mov     r1, #6                      //32*32 block x-coordinate
    mov     r2, #13                     //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_press_a           //"main menu" text
    ldr     r2, =colour_white           //16-bit hex colour
    mov     r3, #19                     //number of letters in "press a to continue"
    bl      small_text_loop             //write letter on screen
    pop     {r4-r10,lr}
    mov     pc, lr

.globl  text_lose_menu
text_lose_menu:
    push    {r4-r10, lr}
    mov     r1, #3                      //32*32 block x-coordinate
    mov     r2, #22                     //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_creator           //"start game" text to r0
    ldr     r2, =colour_white           //hex colour to r2
    mov     r3, #26                     //number of letters in creator label
    bl      text_loop                   //write letter on screen
    mov     r1, #11                     //32*32 block x-coordinate
    mov     r2, #11                     //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_lose              //"you win" text to r0
    ldr     r2, =colour_white           //hex colour to r2
    mov     r3, #6                      //number of letters in "continue"
    bl      text_loop                   //write letter on screen
    mov     r1, #6                      //32*32 block x-coordinate
    mov     r2, #13                     //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_press_a           //"main menu" text
    ldr     r2, =colour_white           //16-bit hex colour
    mov     r3, #19                     //number of letters in "press a to continue"
    bl      small_text_loop             //write letter on screen
    pop     {r4-r10,lr}
    mov     pc, lr

small_text_loop:
    push {r4-r10, lr}
    mov     r4, r0
    mov     r5, r1
    mov     r6, r2
    mov     r7, r3
    mov     r8, #0
small_text_next:
    //character r0
    ldrb    r0, [r4],   #1
    //offset r1
    mov     r1, r5
    //colour r2
    mov     r2, r6
    bl      small_write
    add     r5, #32                     //next block to the right
    add     r8, #1
    cmp     r8, r7
    blt     small_text_next
    movgt   r8, #0
    pop     {r4-r10, lr}
    mov     pc, lr

.globl text_loop
text_loop:
    push {r4-r10, lr}
    mov     r4, r0
    mov     r5, r1
    mov     r6, r2
    mov     r7, r3
    mov     r8, #0
text_next:
    //character r0
    ldrb    r0, [r4],   #1
    //offset r1
    mov     r1, r5
    //colour r2
    mov     r2, r6
    bl      write
    add     r5, #32                     //next block to the right
    add     r8, #1
    cmp     r8, r7
    blt     text_next
    movgt   r8, #0
    pop     {r4-r10, lr}
    mov     pc, lr

.globl  calculate_offset
calculate_offset:
    //offset r1 = [(y * 1024) * 32 + (x * 32)] = [(x << 5) * (y << 10)] * 32
    lsl     r1, #5
    add		r0,	r1, r2, lsl #15
    bx      lr

num_to_hex:
    push {r4-r10, lr}
    mov     r4, r0
    mov     r5, r1
    mov     r6, r2
    mov     r7, r3
    mov     r8, #0
num_to_hex_next:
    //character r0
    ldrb    r0, [r4],   #1
    //zero
    cmp     r0, #0
    ldreq   r0, =0x30
    beq     num_converted
    //one
    cmp     r0, #1
    ldreq   r0, =0x31
    beq     num_converted
    //two
    cmp     r0, #2
    ldreq   r0, =0x32
    beq     num_converted
    //three
    ldr r1, =0x3
    cmp     r0, r1
    ldreq   r0, =0x33
    beq     num_converted
    //four
    cmp     r0, #4
    ldreq   r0, =0x34
    beq     num_converted
    //five
    cmp     r0, #5
    ldreq   r0, =0x35
    beq     num_converted
    //six
    cmp     r0, #6
    ldreq   r0, =0x36
    beq     num_converted
    //seven
    cmp     r0, #7
    ldreq   r0, =0x37
    beq     num_converted
    //eight
    cmp     r0, #8
    ldreq   r0, =0x38
    beq     num_converted
    //nine
    cmp     r0, #9
    ldreq   r0, =0x39
    beq     num_converted
num_converted:
    //offset r1
    mov     r1, r5
    //colour r2
    mov     r2, r6
    bl      write
    add     r5, #32                     //next block to the right
    add     r8, #1
    cmp     r8, r7
    blt     num_to_hex_next
    movgt   r8, #0
    pop     {r4-r10, lr}
    mov     pc, lr

.section    .data
text_coins:
    .ascii  "x0"
.align  4
text_score:
    .ascii  "00"
.align  4
text_lives:
    .ascii  "x0"
.align  4
.globl  text_creator
text_creator:
    .ascii  "CREATED BY: RICHARD TRUONG"
.align 4
.globl  text_start
text_start:
    .ascii  "START GAME"
.align 4
.globl  text_quit
text_quit:
    .ascii  "QUIT GAME"
.align  4
.globl  text_continue
text_continue:
    .ascii  "CONTINUE"
.align 4
.globl  text_return
text_return:
    .ascii  "MAIN MENU"
.align 4
text_world:
    .ascii  "WORLD"
.align  4
text_one:
    .ascii  "1-1"
.align  4
text_mario:
    .ascii  "MARIO"
.align 4
text_win:
    .ascii  "YOU  WIN"
.align 4
text_lose:
    .ascii  "YOU LOSE"
.align 4
text_press_a:
    .ascii  "PRESS A TO CONTINUE"
.align 4
.globl  colour_orange
colour_orange =0xd74a00
.align 4
.globl  colour_black
colour_black =0x0
.align 4
.globl  colour_white
colour_white =0xffffff
.align 4
