.section    .init
.globl     _start

_start:
    b       main
    
.section .text
//main initialization
main:
    mov     sp, #0x8000
	bl		EnableJTAG      //for debugging
	bl		InitFrameBuffer //for drawing
    bl      InitGPIO        //for SNES controller

//game main menu
.globl main_menu_select
main_menu_select:
    bl 		main_menu
    //reset game variables
    bl      game_reset
    bl      menu_control
    cmp     r0, #1          //0 = start game, 1 = quit game
    beq     haltLoop$

//game has started
game_start:
    //load map
    ldr     r0, =map1               //r0 is address of new map to draw
    bl      screen_swap
    bl      text_game
    //load mario
    bl      collision_handler       //check mario's surrounding blocks
    mov r0, #0                      //mario's first movement is nothing
    bl      mario_animate
    mov     r0, #1200               //number of micro seconds
    lsl     r0, #6
    bl      Wait                    //to wait
game_loop:
    bl      game_control
    cmp     r0, #5                  //r0 = 5 quits game and resets vars
    beq     main_menu_select

//disable everything when mario wins, mario dies, mario loses

//ends program
haltLoop$:
    b		haltLoop$
