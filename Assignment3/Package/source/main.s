//cpsc359 assignment 3
//snes controller
//gevorg manukyan 10163988
//richard truong 10058625

.section    .init
.globl     _start

_start:
    b       main

.section    .text

//*************************************************
//******************  MAIN  ***********************
//*************************************************

main:
// --- initialize Stack Pointer, JTAG, UART, GPIO --- //
    mov     sp, #0x8000     //r13 initialize memory
    bl	    EnableJTAG      //initialize JTAG
    bl      InitUART        //initialize UART
    mov     r0, #9          //set r0 to 9
    bl      Init_GPIO       //initialize GPIO line 9
    mov     r0, #10         //set r0 to 10
    bl      Init_GPIO       //initialize GPIO line 10
    mov     r0, #11         //set r0 to 11
    bl      Init_GPIO       //initialize GPIO line 11
// --- print creators' names --- //
    ldr     r0,     =Creators 	//Address of the label for Creators in data section
    mov     r1,     #47         //Number of characters to print
    bl      WriteStringUART
// --- ask user for SNES controller input --- //
Request_Input:
    ldr     r0,     =RequestInput   //Address of the label for RequestInput in data section
    mov     r1,     #27             //Number of characters to print
    bl      WriteStringUART
// --- scans for changes in pressed buttons --- //
Scan_Input:
    bl      Read_SNES       //branch and link to scan SNES controller input
    ldr     r1,     =0xffff //r1 = 0xffff
    //if nothing has been pressed, scan input again
    cmp     r0,     r1      //check for any pressed buttons
    beq     No_Input        //wait until button(s) is(are) pressed
    //if nothing has changed since the last print (input message(s)), skip to same input
    cmp     r10,    r0      //compare state of current input to previous input
    beq     Same_Input
    //copy current state to another register(previous state)
    mov     r10,    r0      //update previous input state
    mov     r5,     #0      //button_number = 0 (up to 15)
    mov     r7,     r0      //copy button states
// --- print status for buttons that are pressed --- //
Button_Check:
    mov     r6,     #15     //counter for 16 buttons
    // check for button #13 (ignore - does not exist)
    cmp     r5,     #13      //button 13
    beq     Next_Input
    //iterate through status stack and print the necessary messages
    //r8 = lsl r7, (15 - r5)
    mov     r8, r7          //copy button states
    sub     r6, r6, r5      //15 - r5(button number)
debug:
    lsr     r8, r8, r6      //logical shift right r6 times
    mvn     r9, #1          //0xfffe
    bic     r8, r9          //mask (bit clear) all bits except bit 0
    //print a message for each button that is pressed
    cmp     r8, #0          //bit 0 is either 1 or 0
    beq     Button_Pressed  //if pressed, go to Button_Pressed
    b       Next_Button     //if not pressed, skip to Next_Button
Button_Pressed:
    mov     r0, r5          //store button number r5 to r0 as argument
    bl      Print_Message   //Print_Message(r5)
Next_Button:
    //button_number++
    add     r5, r5, #1      //button_number ++ (r5)
    b       Button_Check    //loop Button_Check
// --- moving on to the next round of input --- //
Next_Input:
    b       Request_Input
// --- when the state of pressed buttons has not changed, skip to here --- //
No_Input:
    mov     r10,    r0      //update previous input state to nothing
Same_Input:
    b       Scan_Input      //prevents printing the exact same output more than once
// --- program termination loop --- //
haltLoop$:
    b		haltLoop$

//*************************************************
//****************  SUBROUTINES  ******************
//*************************************************
// --- Initialize GPIO --- //
Init_GPIO:
        push    {lr}        //r14 link register
        cmp     r0, #9      //pin 9 switch
        beq     Set_LAT
        cmp     r0, #10     //pin 10 switch
        beq     Set_DAT
        cmp     r0, #11     //pin 11 switch
        beq     Set_CLK
        b       Exit_Init_GPIO      //invalid GPIO specification will exit subroutine
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
        b       Exit_Init_GPIO
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
        b       Exit_Init_GPIO
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
        b       Exit_Init_GPIO
    Exit_Init_GPIO:
        //Exit Init_GPIO function
        pop     {lr}        //r14
        mov     pc, lr      //r15, r14

// --- Write bit to GPIO Latch line 9 --- ///
Write_Latch:
    push    {lr}        //r14
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
    pop     {lr}        //r14
    mov     pc, lr      //r15, r14 return from sub

// --- Write bit to GPIO Data line 10 --- ///
Read_Data:
    push    {lr}        //r14
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
    pop     {lr}        //r14
    mov     pc, lr      //r15, r14 return from sub

// --- Write bit to GPIO Clock line 11 --- ///
Write_Clock:
    push    {lr}        //r14
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
    pop     {lr}        //r14
    mov     pc, lr      //r15, r14 return from sub

// ---
Read_SNES:
        push    {lr}        //r14
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
        cmp     r4, #4      //check START button status
        beq     Start_Button//branch to Start_Button
        add     r4, r4, #1  //i++ (next button)
        cmp     r4, #17     //if(i < 17) then Pulse_Loop
        bne     Pulse_Loop
// ---
    End_Pulse:
        mov     r0, r9      //return button values in button register
        pop     {lr}        //r14
        mov     pc, lr      //r15, r14 return from sub
// --- Handles START button --- //
    Start_Button:
        mov r2, r9
        lsr r3, r2, #12
        mvn r5, #1
        bic r2, r5
        cmp r2, #0
        beq Terminate
    Skip_Termination:
        add r4, r4, #1
        b       Pulse_Loop
    Terminate:
        ldr	r0, =Button4 	//Address of the label for START button in data section
        mov	r1, #27         //Number of characters to print
        bl      WriteStringUART
        b       haltLoop$   //branch to haltLoop$ to terminate program

// --- Wait for specified number of micro seconds --- //
Wait:
        push    {lr}        //r14
        mov     r3, r0      //move argument to r3
        ldr     r0, =0x3F003004     //address of CLO
        ldr     r1, [r0]    //read CLO
        add     r1, r3      //add specified number of micro seconds
// --- wait loop --- //
    Wait_Loop:
        ldr     r2, [r0]
        cmp     r1, r2      //stop when CLO = r1 
        bhi     Wait_Loop
// --- ends wait loop --- //
    Exit_Wait_Loop:
        pop     {lr}        //r14
        mov     pc, lr      //r15, r14 return from sub

// --- Print message based on argument (button) --- //
Print_Message:
        push    {lr}        //r14
        mov r3, r0          //store argument (button number) in r2
        ldr	r0, =Button 	//Address of the label for "You have pressed "
        mov	r1, #19         //Number of characters to print
        bl      WriteStringUART
        ldr r0, =Buttons    //Address of the label for the buttons
        mov r1, #13         //Number of characters to print
        cmp r3, #3          //check for > #3 or < #3 (start button)
        blt     Keep_Button_Number
// --- reduce button number to calculate the correct string address (no START) --- //
    Reduce_Button_Number:
        sub r3, r3, #1
    Keep_Button_Number:
        mul r3, r1          //button number multiplied by length of each button string
        add r0, r3          //offset address to the correct button label
        bl      WriteStringUART
        pop {lr}            //r14
        mov pc, lr          //r15, r14 return from sub

//*************************************************
//*****************  STRINGS  *********************
//*************************************************
.section .data
Creators:
	.ascii "Created by: Gevorg Manukyan and Richard Truong"     // Size: 47
	.align

RequestInput:
	.ascii "\r\nPlease press a button... "  // Size: 27
	.align
Button:     //You have pressed
    .ascii "\r\nYou have pressed "          // Size: 19
    .align
Button4:    //START
    .ascii "\r\nProgram is terminating..."  // Size: 27
    .align
Buttons:    //button strings array
	.ascii "B            ", "Y            ", "SELECT       ", "Joy-pad UP   ", "Joy-pad DOWN ", "Joy-pad LEFT ", "Joy-pad RIGHT", "A            ", "X            ", "LEFT BUMPER  ", "RIGHT BUMPER "
    // Size: 13 each
