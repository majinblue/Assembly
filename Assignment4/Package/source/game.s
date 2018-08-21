//check if mario has crossed the finish line (flag pole)
.global game_win_check
game_win_check:
    push    {r4-r10, lr}
    ldr r4, =map_range
    ldrb r4, [r4,#1]            //check for the almost last x coordinate (125)
    cmp r4, #125                //mario has reached the end of the level
    bne game_win_false
    ldr r4, =mario_coord
    ldrb r5, [r4]
    cmp r5, #24                 //mario has reached x = 24 on screen
    bne  game_win_false
game_win:                       //you have won the game
    //update score with flag pole jump height (r6)
    ldrb r6, [r4,#1]            //mario's y_coordinate
    ldr r4,   =stat_score
    ldrb r5, [r4,#1]          //hundred's
    ldrb r7, [r4]             //thousand's
    cmp r6, #8
    addlt r7,   #1              //+1000 pts
    blt game_win_score
    cmp r6, #10
    addlt r5,   #8              //+ 800 pts
    blt game_win_score
    cmp r6, #12
    addlt r5,   #6              //+ 600 pts
    blt game_win_score
    cmp r6, #14
    addlt r5,   #4              //+ 400 pts
    blt game_win_score
    cmp r6, #16
    addlt r5,   #2              //+ 200 pts
    blt game_win_score
    cmp r6, #18
    addlt r5,   #1              //+ 100 pts
    blt game_win_score
game_win_score:
    //if the 100's place is > 10, carry over to 1000's
    cmp r5, #10
    subgt   r5, #10             //subtract and
    addgt   r7, #1              //carry over
    strb    r5, [r4,#1]         //store score
    strb    r7, [r4]            //store score
game_win_enemies:
    //spikes disappear
    ldr r6, =spike_show
    ldr r7, [r6]
    mov r7, #0
    str r7, [r6]
    //reload current map
    bl  screen_current
    //reload game text
    bl  text_game               //update score on screen
    //reload mario
    bl  mario_animate
game_win_pipe:
    //pipe shrinks to ground (animation)
    mov r4, #12                 //height of pipe (deletion)
    mov r5, #11                 //height of pipe (redraw)
    mov r10,    #8              //height offset for pipe
game_win_pipe_delete:
    ldr r6, =0x7300             //sky
    mov r0, r6                  //blue sky
    mov r1, #14                 //x-coord
    add r2, r4, r10             //y-coord
    bl  draw                    //draw blue sky
    mov r0, r6                  //blue sky
    mov r1, #15                 //x-coord
    add r2, r4, r10             //y-coord
    bl  draw                    //draw blue sky
    mov r0, r6                  //blue sky
    mov r1, #16                 //x-coord
    add r2, r4, r10             //y-coord
    bl  draw                    //draw blue sky
    cmp r4, #0                  //check row
    beq game_win_pipe_shrink_top          //done deleting pipe, redraw shrunken down one
    sub r4, #1                  //decrement height
    b   game_win_pipe_delete    //continue deleting
game_win_pipe_shrink_top:
    cmp r5, #0                  //done animation
    beq game_win_mario          //now animate mario
    add r10,    #1              //increment offset for pipe height
    ldr r6, =0x7                //top left of top lip of pipe
    ldr r7, =0x107              //top middle of top lip of pipe
    ldr r8, =0x207              //top right of top lip of pipe
    mov r0, r6                  //left top lip of pipe
    mov r1, #14                 //x-coord
    add r2, r4, r10             //y-coord
    bl  draw                    //draw left top lip of pipe
    mov r0, r7                  //middle top lip of pipe
    mov r1, #15                 //x-coord
    add r2, r4, r10             //y-coord
    bl  draw                    //draw middle top lip of pipe
    mov r0, r8                  //right top lip of pipe
    mov r1, #16                 //x-coord
    add r2, r4, r10             //y-coord
    bl  draw                    //draw right top lip of pipe
    cmp r4, r5                  //if this is the max height...
    bgt game_win_pipe_wait      //animate mario next (after wait)
    add r4, #1                  //increment height of pipe
game_win_pipe_shrink_middle:
    ldr r6, =0x1007             //top left of bottom lip of pipe
    ldr r7, =0x1107             //top middle of bottom lip of pipe
    ldr r8, =0x1207             //top right of bottom lip of pipe
    mov r0, r6                  //left bottom lip of pipe
    mov r1, #14                 //x-coord
    add r2, r4, r10             //y-coord
    bl  draw                    //draw left bottom lip of pipe
    mov r0, r7                  //middle bottom lip of pipe
    mov r1, #15                 //x-coord
    add r2, r4, r10             //y-coord
    bl  draw                    //draw middle bottom lip of pipe
    mov r0, r8                  //right bottom lip of pipe
    mov r1, #16                 //x-coord
    add r2, r4, r10             //y-coord
    bl  draw                    //draw right bottom lip of pipe
    cmp r4, r5                  //if this is the max height...
    beq game_win_pipe_wait      //loop delete and redraw (shrinking) animation (after wait)
    add r4, #1                  //increment height of pipe
game_win_pipe_shrink_bottom:
    ldr r6, =0x3007             //left pipe
    ldr r7, =0x3107             //middle pipe
    ldr r8, =0x3207             //right pipe
    mov r0, r6                  //left pipe
    mov r1, #14                 //x-coord
    add r2, r4, r10             //y-coord
    bl  draw                    //draw left pipe
    mov r0, r7                  //middle pipe
    mov r1, #15                 //x-coord
    add r2, r4, r10             //y-coord
    bl  draw                    //draw middle pipe
    mov r0, r8                  //right pipe
    mov r1, #16                 //x-coord
    add r2, r4, r10             //y-coord
    bl  draw                    //draw right pipe
    cmp r4, r5                  //if this is the max height...
    beq game_win_pipe_wait      //loop delete and redraw (shrinking) animation (after wait)
    add r4, #1                  //increment height of pipe
    b   game_win_pipe_shrink_bottom    //continue shrinking
game_win_pipe_wait:
    sub r5, #1                  //decrement
    mov r4, r5                  //reset
    add r4, #1                  //add 1 so that delete will include top of old pipe
    mov     r0, #900            //number of micro seconds
    lsl     r0, #6
    bl      Wait                //to wait
    bl      Wait                //to wait x2
    bl      Wait                //to wait x3
    bl      Wait                //to wait x4
    b   game_win_pipe_delete    //loop animation
game_win_mario:
    //remove the interferring parts of the big pipe that mario walks through to the castle
    ldr r4, =map_current
    ldr r5, =0x7300
    mov r6, #14
    mov r7, #20
    lsl     r8,     r7,  #5     //offset = y * 32
    add     r8,     r6          //offset += x
    lsl     r8,     #1          //offset *= 2
    strh    r5, [r4, r8]        //pipe part 1
    add     r8, #2              //increment
    strh    r5, [r4, r8]        //pipe part 2
    add     r8, #2              //increment
    strh    r5, [r4, r8]        //pipe part 3
    //animate mario sequence
    ldr r4, =mario_direct       //manually control mario movements for animation
    mov r5, #0                  //no directional input
    str r5, [r4]                //store into mario_direct
    ldr r4, =mario_jump_count   //cancel any remaining jump
    ldr r5, =0x99               //jump error
    str r5, [r4]                //store into mario_jump_count
game_win_mario_fall:
    bl  collision_handler       //check mario's surrounding blocks
    bl  mario_animate           //mario falls down flag pole
    mov     r0, #900            //number of micro seconds
    lsl     r0, #6
    bl      Wait                //to wait
    bl      Wait                //to wait x2
    ldr r4, =mario_coord        //check mario's y coord for finished fall
    ldrb r5, [r4,#1]            //y is in second byte
    cmp r5, #19                 //mario is on top of solid block
    blt game_win_mario_fall     //keep dropping otherwise
    ldr r4, =mario_direct       //manually control mario movements for animation
    mov r5, #2                  //left directional input
    str r5, [r4]                //store into mario_direct
    ldr r4, =mario_jump_count   //cancel any remaining jump
    mov r5, #0                  //jump reset
    str r5, [r4]                //store into mario_jump_count
game_win_mario_move:
    bl      collision_handler   //check mario's surrounding blocks
    ldr r4, =collide_data       //modify collide data
    mov r5, #0                  //free to move
    strb r5, [r4,#3]            //store data to the left of mario
    strb r5, [r4,#6]            //store data to the top left of mario
    bl  mario_animate           //mario walks left toward castle
    mov     r0, #900            //number of micro seconds
    lsl     r0, #6
    bl      Wait                //to wait
    bl      Wait                //to wait x2
    ldr r4, =mario_coord        //check mario's x coord for finished walk
    ldrb r5, [r4]                //x is in first byte
    cmp r5, #4                  //mario is at the castle entrance
    bgt game_win_mario_move     //keep moving
    ldr r0, =0x6200             //black block
    mov r1, #4                  //x = 4
    mov r2, #20                 //y = 20
    bl  draw                    //overwrite mario sprite (simulate entering castle)
    mov     r0, #900            //number of micro seconds
    lsl     r0, #6
    bl      Wait                //to wait
    bl      Wait                //to wait x2
    ldr r0, =0x102              //castle flag
    mov r1, #4                  //x = 4
    mov r2, #12                 //y =
    bl  draw
    mov     r0, #900            //number of micro seconds
    lsl     r0, #6
    mov     r1, #0              //loop 40 times
game_win_wait_loop:
    cmp     r1, #40
    bgt     game_win_wrapup
    bl      Wait                //to wait
    add     r1, #1
    b       game_win_wait_loop
game_win_wrapup:
    ldr     r0, =map_end        //load game win text background
    bl      screen_overlay      //show game win text background
    bl      text_win_menu       //show game win text
    mov     r0, #3              //return to SNES, player press A, which will branch to MAIN and reset game
game_win_false:                 //skipping here directly from earlier instructions mean the player has not won the game
    pop     {r4-r10,lr}
    mov     pc, lr

//you have lost the game
.globl game_lose
game_lose:
push    {r4-r10, lr}
    ldr     r0, =map_end        //load game win text background
    bl      screen_overlay      //show game win text background
    bl      text_lose_menu      //show game lost text
    mov     r0, #4              //return to SNES, player press A, which will branch to MAIN and reset game
    pop     {r4-r10,lr}
    mov     pc, lr

//reset game variables
.globl game_reset
game_reset:
    push    {lr}
    ldr r0, =stat_coins
    mov r1, #0
    str r1, [r0]
    ldr r0, =stat_score
    mov r1, #0
    strb r1, [r0]
    strb r1, [r0,#1]
    strb r1, [r0,#2]
    strb r1, [r0,#3]
    ldr r0, =stat_lives
    mov r1, #3
    str r1, [r0]
    ldr r0, =pause
    mov r1, #0
    str r1, [r0]
    ldr r0, =coin_shown
    mov r1, #0
    str r1, [r0]
    ldr r0, =animate_on
    mov r1, #0
    str r1, [r0]
    ldr r0, =lakitu_sprite
    mov r1, #1
    strb r1, [r0]
    ldr r0, =goomba_sprite
    mov r1, #1
    str r1, [r0]
    ldr r0, =spike_sprite
    mov r1, #1
    str r1, [r0]
    ldr r0, =spike_show
    mov r1, #1
    str r1, [r0]
    ldr r0, =map_range
    mov r1, #0
    strb r1, [r0]
    mov r1, #31
    strb r1, [r0,#1]
    ldr r0, =mario_coord
    mov r1, #2
    strb r1, [r0]
    mov r1, #20
    strb r1, [r0,#1]
    ldr r0, =mario_direct
    mov r1, #0
    str r1, [r0]
    ldr r0, =mario_count
    mov r1, #0
    str r1, [r0]
    ldr r0, =mario_jump_count
    mov r1, #0
    str r1, [r0]
    ldr r0, =mario_sprite
    ldr r1, =0x6
    str r1, [r0]
    ldr r0, =mario_death_jump
    mov r1, #0
    str r1, [r0]

    pop {lr}
    mov pc, lr

.section    .data
//game status
.global stat_coins
stat_coins:
    .byte   0
.align  4
.global stat_score
stat_score:
    .byte   0,0,0,0
.align  4
.global stat_lives
stat_lives:
    .byte   3
//    .ascii  "3"
.align  4
.globl pause
pause:
    .byte   0           //0 is unpaused, 1 is paused
.align  4
.globl map_range
map_range:
    .byte   0,31
.align  4

//coin animation data
.globl coin_shown
coin_shown:
    .byte   0           //1 means coin is on screen
.align  4
.globl coin_coord
coin_coord:
    .byte   0,0         //coordinates to remove it next animation cycle
.align  4

//enemy animation loop data
.globl  animate_on
animate_on:
    .byte   0           //animate every 4 WAIT cycles in SNES
.globl  lakitu_sprite
lakitu_sprite:
    .byte   1           //4 sprites
.align  4
.globl  goomba_sprite
goomba_sprite:          //2 sprites
    .byte   1
.align  4
.globl  spike_show      //show or hide
spike_show:
    .byte   1           //0 off or 1 on
.align  4
.globl  spike_sprite    //4 sprites
spike_sprite:
    .byte   1
.align  4

//mario animation data
.globl mario_coord
mario_coord:
    .byte   2,20
.align  4
.globl mario_direct
mario_direct:
    .byte   0           //0 is none, 1 is right, 2 is left
.align  4
.globl mario_count
mario_count:
    .byte   0           //number of sequential inputs in the same direction (left and right)
.align  4
.globl mario_jump_count
mario_jump_count:
    .byte   0           //number of sequential inputs for jump
.align  4
.globl mario_sprite
mario_sprite:
    .byte   6,0x0       //mario,sprite hex value
.align  4
.globl mario_death_jump
mario_death_jump:
    .byte   0           //number of times to animate dead mario (upwards)
.align  4

//dictates game movement
//0 = nothing (can move/fall through that block)
//1 = wall (can't move to that block)
//2 = wall with action (mystery box)
//3 = temp wall (move up to break, no actual movement) (wood)
//4 = temp block (move down to break) (any direction and die) (goomba)
//5 = death (move to block then die)
.globl  collide_data    //mario's surrounding immediate blocks
collide_data:
    .byte   1,1,1,0,0,0,0,0,0     //SW,S,SE,W,mario,E,NW,N,NE
//state of current map on screen
//updated through other functions
.align 4

.globl map_current
map_current:
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0x6d,0x0,0x6d,0x1,0x6d,0x2,0x6d,0x3,0x6d,0x4,0x6d,0x5,0x6d,0x6,0x6d,0x7,0x6d,0x8,0x6d,0x9,0x6d,0xa,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0x6d,0x10,0x6d,0x11,0x6d,0x12,0x6d,0x13,0x6d,0x14,0x6d,0x15,0x6d,0x16,0x6d,0x17,0x6d,0x18,0x6d,0x19,0x6d,0x1a,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0x6d,0x20,0x6d,0x21,0x6d,0x22,0x6d,0x23,0x6d,0x24,0x6d,0x25,0x6d,0x26,0x6d,0x27,0x6d,0x28,0x6d,0x29,0x6d,0x2a,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0x6d,0x30,0x6d,0x31,0x6d,0x32,0x6d,0x33,0x6d,0x34,0x6d,0x35,0x6d,0x36,0x6d,0x37,0x6d,0x38,0x6d,0x39,0x6d,0x3a,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0x6d,0x40,0x6d,0x41,0x6d,0x42,0x6d,0x43,0x6d,0x44,0x6d,0x45,0x6d,0x46,0x6d,0x47,0x6d,0x48,0x6d,0x49,0x6d,0x4a,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0x6d,0x50,0x6d,0x51,0x6d,0x52,0x6d,0x53,0x6d,0x54,0x6d,0x55,0x6d,0x56,0x6d,0x57,0x6d,0x58,0x6d,0x59,0x6d,0x5a,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,8,0x0,8,0x1,8,0x2,8,0x3,8,0x4,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,8,0x5,8,0x6,8,0x7,8,0x8,8,0x9,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x73,0,0x73,0,0x73,8,0xa,8,0xb,8,0xc,8,0xd,8,0xe,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,0,0x73,8,0x10,8,0x11,8,0x12,8,0x13,0,0x73,0,0x73,0,0x73,0,0x73
.byte  0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66
.byte  0,0x66,0,0x66,0,0x66,0,0x62,0,0x62,0,0x62,0,0x62,0,0x62,0,0x62,0,0x62,0,0x66,0,0x62,0,0x62,0,0x62,0,0x66,0,0x62,0,0x62,0,0x62,0,0x62,0,0x62,0,0x62,0,0x62,0,0x66,0,0x62,0,0x62,0,0x62,0,0x62,0,0x62,0,0x62,0,0x66,0,0x66,0,0x66
.byte  0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66,0,0x66
.align 4
