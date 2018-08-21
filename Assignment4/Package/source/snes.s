.section    .text
// r2 = r10 = 0 = main/pause menu control mode
// r2 = r10 = 1 = game control mode
// r2 = r10 = 2 = pause control mode
.globl menu_control
menu_control:
    push {r4-r10, lr}
    mov r8, #0              //control mode
    mov r4, #0              //start game selected
    b   control
.globl game_control
game_control:
    push {r4-r10, lr}
    mov r8, #1              //control mode
    mov r4, #0              //pause status
    b   control
.globl pause_control
pause_control:
    push {r4-r10, lr}
    mov r8, #2              //control mode
    mov r4, #0              //pause status
    b   control
.globl end_control
end_control:
    push {r4-r10, lr}
    mov r8, #3              //control mode
    mov r4, #0              //pause status
    b   control
control:
    bl      Read_SNES       //branch and link to scan SNES controller input
    //copy current state to another register(previous state)
    mov     r10,    r0      //copy input data
    mov     r5,     #0      //button_number = 0 (up to 15)
    cmp     r8,     #1
    beq     g_Button_Check//special game button detection
    b       Button_Iterate
// --- send status to game for buttons that are pressed --- //
Button_Iterate:
    mov     r6,     #15     //counter for 16 buttons
    // check for button only the important buttons
    cmp     r5,     #3      //START
    beq     Button_Check
    cmp     r5,     #4      //UP
    beq     Button_Check
    cmp     r5,     #5      //DOWN
    beq     Button_Check
    cmp     r5,     #6      //LEFT
    beq     Button_Check
    cmp     r5,     #7      //RIGHT
    beq     Button_Check
    cmp     r5,     #8      //A
    beq     Button_Check
    cmp     r5,     #9     //no buttons past #9 needed
    bge     game_animation
    b       Next_Button
g_Button_Check:
    //button combos: START, -> + A, ->, <- + A, <-, NONE
    ldr     r7,     =0xefff //START
    cmp     r10,    r7
    beq     g_start
    ldr     r7,     =0xfe7f //-> + A
    cmp     r10,    r7
    beq     g_right_a
    ldr     r7,     =0xfeff //->
    cmp     r10,    r7
    beq     g_right
    ldr     r7,     =0xfd7f //<- + A
    cmp     r10,    r7
    beq     g_left_a
    ldr     r7,     =0xfdff //<-
    cmp     r10,    r7
    beq     g_left
    ldr     r7,     =0xff7f //A
    cmp     r10,    r7
    beq     g_a
    //no buttons pressed was already handled above in No_Input
    b       g_none          //this is for all other unimportant input
Button_Check:
    //iterate through status stack and print the necessary messages
    mov     r7,     r10     //copy button states
    sub     r6, r6, r5      //15 - r5(button number)
    lsr     r7, r7, r6      //logical shift right r6 times
    mvn     r9, #1          //0xfffe
    bic     r7, r9          //mask (bit clear) all bits except bit 0
    cmp     r7, #0          //bit 0 is either 1 or 0
    beq     Button_Pressed  //if pressed, go to Button_Pressed
    b       Next_Button     //if not pressed, skip to Next_Button
Button_Pressed:
    mov     r1, r5          //store button number r5 to r0 as argument
    b       Action          //actions for the game
Next_Button:
    //button_number++
    add     r5, #1      //button_number ++ (r5)
    b       Button_Iterate    //loop Button_Iterate
game_animation:
    cmp     r8,     #1              //game mode does not loop input
    bne     control
    bl      collision_handler       //check mario's surrounding blocks
    bl      game_jump_handler       //handling jumps (uses collision data)
    bl      animate_coin
    bl      animate_spike           //draws animated spikes
//    bl      animate_goomba          //draws animated goombas
//    bl      animate_lakitu          //draws animated lakitu
    bl      mario_animate           //update mario sprite
    cmp r0, #4                      //game lost!
    moveq   r8, #3                  //end game control mode
    bleq    game_lose
    beq     control
    bl      game_win_check
    cmp     r0, #3                  //game win!
    moveq   r8, #3                  //end game control mode
    beq     control
    mov     r0, #900                //number of micro seconds
    lsl     r0, #6
    bl      Wait                    //to wait
    bl      Wait                    //to wait x2
    b       control                 //before accepting input again

//*************************************************
//****************  SUBROUTINES  ******************
//*************************************************

// --- Write bit to GPIO Latch line 9 --- ///
Write_Latch:
    push    {r4-r10,lr}        //r14
    mov     r1, r0      //move argument to r1
    // load the address of SET Register
    ldr		r0, =0x3F200000     //GPIO Base
    //
    mov     r2, #9      //LSB of line
    mov     r3, #1      //Value (1) to write
    lsl     r3, r2      //aligning #1 with line
    teq     r1, #0      //value to write
    streq   r3, [r0,    #40]    // GPCLR0 (0x28)
    strne   r3, [r0,    #28]    // GPSET0 (0x1C)
    pop     {r4-r10,lr}        //r14
    mov     pc, lr      //r15, r14 return from sub

// --- Write bit to GPIO Data line 10 --- ///
Read_Data:
    push    {r4-r10,lr}        //r14
    // load the address of SET Register
    ldr		r0, =0x3F200000     //GPIO Base
    // load the value of SET Register
    ldr		r1, [r0,    #52]    // GPLEV0
    //
    mov     r2, #10     //line number
    mov     r3, #1      //Value (1) to write
    lsl     r3, r2      //aligning #1 with line
    and     r1, r3      //bitmask all but line
    teq     r1, #0      //value to check
    moveq   r0, #0      //return 0
    movne   r0, #1      //return 1
    pop     {r4-r10,lr}        //r14
    mov     pc, lr      //r15, r14 return from sub

// --- Write bit to GPIO Clock line 11 --- ///
Write_Clock:
    push    {r4-r10,lr}        //r14
    mov     r1, r0      //move argument to r1
    // load the address of SET Register
    ldr	    r0, =0x3F200000     //GPIO Base
    //
    mov     r2, #11     //line number
    mov     r3, #1      //Value (1) to write
    lsl     r3, r2      //aligning #1 with line
    teq     r1, #0      //value to write
    streq   r3, [r0,    #40]    // GPCLR0 (0x28)
    strne   r3, [r0,    #28]    // GPSET0 (0x1C)
    pop     {r4-r10,lr}        //r14
    mov     pc, lr      //r15, r14 return from sub

// ---
Read_SNES:
        push    {r4-r10,lr}        //r14
// ---
    Clear_Buttons:
    mov     r9, #0          //MOV buttons, #0
// ---
    Start_Clock:
        mov     r0, #1
        bl      Write_Clock //writeGPIO(CLOCK, #1)
// ---
    Start_Latch:
        mov     r0, #1
        bl      Write_Latch //writeGPIO(LATCH, #1)
// ---
    Initial_Wait:
        mov     r0, #12     //wait(12 micro seconds)
        bl      Wait
// ---
    Close_Latch:
        mov     r0, #0
        bl      Write_Latch //writeGPIO(LATCH, #0)
        mov     r4, #1      //i=1
// ---
    Pulse_Loop:
        lsl     r9, #1      //lsl button register
        mov     r0, #6
        bl      Wait        //wait(6 micro seconds)
        mov     r0, #0
        bl      Write_Clock //writeGPIO(CLOCK, #0)
        mov     r0, #6
        bl      Wait        //wait(6 micro seconds)
        bl      Read_Data   //readGPIO(DATA, b)
        orr     r9, r0      //store status of button in button register
        mov     r0, #1
        bl      Write_Clock //writeGPIO(CLOCK, #1)
        add     r4, r4, #1  //i++ (next button)
        cmp     r4, #17     //if(i < 17) then Pulse_Loop
        bne     Pulse_Loop
// ---
    End_Pulse:
        mov     r0, r9      //return button values in button register
        pop     {r4-r10,lr}        //r14
        mov     pc, lr      //r15, r14 return from sub

// --- Wait for specified number of micro seconds --- //
.globl Wait
Wait:
        push    {r4-r10,lr}        //r14
        mov     r4, r0      //move argument to r3
        ldr     r7, =0x3F003004     //address of CLO
        ldr     r5, [r7]    //read CLO
        add     r5, r4      //add specified number of micro seconds
// --- wait loop --- //
    Wait_Loop:
        ldr     r6, [r7]
        cmp     r5, r6      //stop when CLO = r1
        bhi     Wait_Loop
// --- ends wait loop --- //
    Exit_Wait_Loop:
        pop     {r4-r10,lr}        //r14
        mov     pc, lr      //r15, r14 return from sub

// --- Print message based on argument (button) --- //
Action:
    cmp r8, #0
    beq m_Action
    cmp r8, #2
    beq p_Action
    cmp r8, #3
    beq e_Action
m_Action:
    cmp r1, #4          //UP
    beq     m_up
	cmp r1, #5          //DOWN
    beq     m_down
	cmp r1, #8          //A
    beq     m_a
m_up:
    cmp r4, #0
    beq     Next_Button
    mov r4, #0
    bl      select_start
    b       Next_Button
m_down:
    cmp r4, #1
    beq     Next_Button
    mov r4, #1
    bl      select_quit
    b       Next_Button
m_a:
    cmp r4, #0
    bleq    clear_menu
    cmp r4, #0
    moveq   r0, r4
    beq     EndAction
    bl      screen_clear
    mov     r0, #1                  //returns 1 to main.s to quit game
    b       EndAction

p_Action:
    cmp r1, #3          //START
    beq     p_start
    cmp r1, #4          //UP
    beq     p_up
	cmp r1, #5          //DOWN
    beq     p_down
	cmp r1, #8          //A
    beq     p_a
p_start:
    bl  text_pause_clear//clear creator from bottom
    bl  screen_current  //hide pause menu
    bl  text_game
    bl  mario_animate   //show mario
    mov r8, #1          //in-game controls
    mov r4, #0
    b   control
p_up:
    cmp r4, #0
    beq     Next_Button
    mov r4, #0
    bl      select_continue
    b       Next_Button
p_down:
    cmp r4, #1
    beq     Next_Button
    mov r4, #1
    bl      select_menu
    b       Next_Button
p_a:
    cmp r4, #0
    bleq    p_start     //same as pressing start
    bl      screen_clear
    mov r0, #5
    b       EndAction

e_Action:
e_a:
    bl      screen_clear
    mov r0, #5
    b       EndAction

g_none:
    mov r0, #0
    bl      g_update
    mov r0, #0
    b       game_animation
g_start:
    bl      pause_menu  //show pause menu
    mov r8, #2          //pause menu controls
    mov r4, #0          //select continue
    mov r2, r4          //pass this to g_update_pause
    bl      g_update_pause
    b       control
g_left:
    mov r0, #2
    bl      g_update
    b       game_animation
g_left_a:
    mov r0, #2
    bl      g_update
    mov r0, #3
    b       game_animation
g_right:
    mov r0, #1
    bl      g_update
    b       game_animation
g_right_a:
    mov r0, #1
    bl      g_update
    mov r0, #3
    b       game_animation
g_a:
    mov r0, #0
    bl      g_update
    mov r0, #3
    b   game_animation
g_update:
    push {r4-r10, lr}
    ldr r7, =mario_count    //number of loops of the same direction
    ldr r4, [r7]
    ldr r6, =mario_direct   //set "game.s" mario's direction (used in mario animation)
    ldrb    r5, [r6]        //check
    cmp     r5, r0          //if same direction
    addeq   r4, #1          //increment mario_count
    streq   r4, [r7]        //store mario count
    beq     g_update_done
    str     r0, [r6]        //change to new direction
    mov     r4, #0          //change mario_count to 0
    str     r4, [r7]        //store mario count
g_update_done:
    pop {r4-r10, lr}
    mov pc, lr
g_update_pause:
    push {r4-r10, lr}
    ldr r6, =pause          //set game pause status to true (used in mario animation)
    strb    r2, [r6]
    b   g_update_done

// --- program termination --- //
EndAction:
	pop {r4-r10,lr}            //r14
    mov pc, lr          //r15, r14 return from sub

//counts number of times jump is held down
game_jump_handler:
    push    {r4-r10,lr}
    ldr r4, =mario_jump_count       //consecutive A presses
    ldr r5, [r4]
    ldr r6, =collide_data           //check block below mario
    ldr r8, =0x99                   //load 0x99 to r8
    cmp r5, r8                      //0x99 means mario is currently unable to jump
    bne game_jump_continue          //continue to jump
    cmp r0, #3
    bne     game_jump_reset
    ldrb r7, [r6,#1]                //load collide data block below
    cmp r7, #1                      //if it is a 1, then he can resume jumping
    moveq   r5, #0
//    beq     game_jump_cancel
    cmp r7, #2                      //if it is a 2, then he can resume jumping
    moveq   r5, #0
//    beq     game_jump_cancel
    cmp r7, #3                      //if it is a 3, then he can resume jumping
    moveq   r5, #0
//    beq     game_jump_cancel
    b   game_jump_continue
game_jump_reset:
    ldr r5, =0x99                   //load 0x99 to r5
    ldrb r7, [r6,#1]                //load collide data block below
    cmp r7, #1                      //if it is a 1, then he can resume jumping
    moveq   r5, #0
    cmp r7, #2                      //if it is a 2, then he can resume jumping
    moveq   r5, #0
    cmp r7, #3                      //if it is a 3, then he can resume jumping
    moveq   r5, #0
    b   game_jump_cancel
game_jump_continue:
    add     r5, #1                  //if A, then add to consective jump
    cmp     r5, #4                  //mario can jump a maximum of 4 blocks in height
    ble game_jump_cancel            //jump is not maxed out do not cancel
    ldrb    r7, [r6,#7]             //load collide data block above
    cmp r7, #0                      //nothing block
    beq game_jump_cancel
    cmp r7, #4                      //enemy or dead block
    bge game_jump_cancel
    ldr   r5, =0x99                 //store 0x99 as an error if jump is maxed out
//cancels jump command until mario lands previous jump
game_jump_cancel:
    strb    r5, [r4]                //store to mario_jump_count
    pop {r4-r10,lr}
    mov pc, lr

.globl InitGPIO
// --- Initialize GPIO --- //
InitGPIO:
        push    {lr}        //r14 link register
    Set_LAT:
// --- GPIO 9 LAT --- //
        // load the address of Function Select Register
        ldr		r0, =0x3F200000     //GPIO Base
        // load the value of Function Select Register
        ldr		r1, [r0]
        // clear bits 27-29 (for Line 9)
        mov	r2, #9          //LSB of line number
        mov r4, #3          //move 3 to r4 (3 function bits per line)
        mul r2, r2, r4      //multiplied by 3 function bits
        mov     r3, #7 	    //#7 is 111 for bitclearr
        lsl     r3, r2      //alilgning #7 with line
        bic		r1, r3      //bitclear line's function
        // set GPFSEL0 bits 27-29 (for line 9) to 001 (Output function)
        mov	r3, #1          //#1 is output function
        lsl     r3, r2      //aligning #1 with line
        orr		r1, r3      //setting line to #1
        // write back to Function Select Register
        str		r1, [r0]    //store line function back to address
    Set_DAT:
// --- GPIO 10 DAT --- //
        // load the address of Function Select Register
        ldr		r0, =0x3F200004     //GPIO Base + Offset
        // load the value of Function Select Register
        ldr		r1, [r0]
        // clear bits 0-2 (for Line 10)
        mov		r2, #0      //LSB of line number
        add     r4, r2, r2  //multiplied by 3 function bits
        add     r2, r4, r2  //multiplication continued
        mov     r3, #7 	    //#7 is 111 for bitclear
        lsl     r3, r2      //alilgning #7 with line
        bic		r1, r3      //bitclear line's function
        // set GPFSEL1 bits 0-2 (for line 10) to 000 (Input function)
        mov		r3, #0      //#0 is input function
        lsl     r3, r2      //aligning #0 with line
        orr		r1, r3      //setting line to #0
        // write back to Function Select Register
        str		r1, [r0]    //store line function back to address
    Set_CLK:
// --- GPIO 11 CLK --- //
        // load the address of Function Select Register
        ldr		r0, =0x3F200004     //GPIO Base + Offset
        // load the value of Function Select Register
        ldr		r1, [r0]
        // clear bits 3-5 (for Line 11)
        mov	r2, #1      //LSB of line number
        add     r4, r2, r2  //multiplied by 3 function bits
        add     r2, r4, r2  //multiplication continued
        mov     r3, #7 	    //#7 is 111 for bitclear
        lsl     r3, r2      //alilgning #7 with line
        bic		r1, r3      //bitclear line's function
        // set GPFSEL1 bits 3-5 (for line 11) to 001 (Output function)
        mov		r3, #1      //#1 is output function
        lsl     r3, r2      //aligning #1 with line
        orr		r1, r3      //setting line to #1
        // write back to Function Select Register
        str		r1, [r0]    //store line function back to address

    Exit_Init_GPIO:
        //Exit Init_GPIO function
        pop     {lr}        //r14
        mov     pc, lr      //r15, r14
