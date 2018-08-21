.globl pause_menu
pause_menu:
    push    {r4-r10, lr}
    ldr     r0, =map_pause
    bl      screen_overlay
    bl      text_pause
    pop     {r4-r10,lr}
    mov     pc, lr

.globl select_continue
select_continue:
    push    {r4-r10, lr}
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

.globl select_menu
select_menu:
    push    {r4-r10, lr}
    mov     r1, #11                     //32*32 block x-coordinate
    mov     r2, #11                     //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_continue          //"continue" text to r0
    ldr     r2, =colour_orange          //hex colour to r2
    mov     r3, #8                      //number of letters in "continue"
    bl      text_loop                   //write letter on screen
    mov     r1, #11                     //32*32 block x-coordinate
    mov     r2, #13                     //32*32 block y-coordinate
    bl      calculate_offset
    mov     r1, r0                      //offset set to r1
    ldr     r0, =text_return            //"main menu" text
    ldr     r2, =colour_white           //16-bit hex colour
    mov     r3, #9                      //number of letters in "main menu"
    bl      text_loop                   //write letter on screen
    pop     {r4-r10,lr}
    mov     pc, lr
