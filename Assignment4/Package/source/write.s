/* Input Arguments
 - r0 = block color
 - r1 = x start block
 - r2 = y start block
 - r3 = number of characters
 */

.globl clear_write
clear_write:
    push    {r4-r10, lr}
    mov     r6, r0
    mov     r4, r3
    mov     r5, #1
    ldr     r3, =FrameBufferPointer
    ldr     r3, [r3]
delete_char:
    mov     r0, r6
    bl      draw
    add     r1, #1
    add     r5, #1
    cmp     r5,  r4
    ble     delete_char
	pop		{r4-r10, pc}
    mov     pc,     lr

/* Input Arguments
 - r0 = character to write
 - r1 = block offset for pixel
 - r2 = text color
 */
.globl write
write:
    push    {r4-r10, lr}
    //character
    charac  .req    r0
    //pixel location
    offset  .req    r1
    //text color
    colour  .req    r2
    //x pixel coordinate = 0
    px      .req    r3
    //y pixel coordinate = 0
    py      .req    r4
    mov		py,		#0              //init the Y coordinate (pixel coordinate)
    //character font set address
    chAdr   .req    r5
    ldr     chAdr,  =font
    add		chAdr,	charac, lsl #4	//char address = font base + (char * 16)
    //row
    row     .req    r6
    //bitmask
    mask    .req    r7
    //pixel location
    px_lc   .req    r8
    //frame buffer pointer
    fbp     .req    r9
    ldr     fbp,    =FrameBufferPointer
    ldr     fbp,    [fbp]

charLoop$:
	mov		px,		#0			//init the X coordinate
	mov		mask,	#0x1		//set the bitmask to 1 in the LSB
	ldrb	row,	[chAdr], #1	//load the row byte, post increment chAdr

rowLoop$:
	tst		row,	mask		//test row byte against the bitmask
	beq		noPixel$
	b		DrawPixel			//draw pixel at (px, py)

DrawPixel:
    //pixel location = offset + 32 * [(y * 1024) + x]
    add     px_lc,  px, py, lsl #10
    add     px_lc,  offset
    ldr     r10,    =1024
    //offset *= 2 (for 16 bits per pixel = 2 bytes per pixel)
    lsl		px_lc, #1
    //store the colour (half word) at framebuffer pointer + offset
    strh	colour, [fbp, px_lc]
    //scale text by 4x
    add     px_lc,  #2
    strh	colour, [fbp, px_lc]
    add     px_lc,  #2
    strh	colour, [fbp, px_lc]
    add     px_lc,  #2
    strh	colour, [fbp, px_lc]
    add     px_lc,  r10,    lsl #1
    sub     px_lc,  #6
    strh	colour, [fbp, px_lc]
    add     px_lc,  #2
    strh	colour, [fbp, px_lc]
    add     px_lc,  #2
    strh	colour, [fbp, px_lc]
    add     px_lc,  #2
    strh	colour, [fbp, px_lc]
    add     px_lc,  r10,    lsl #1
    sub     px_lc,  #6
    strh	colour, [fbp, px_lc]
    add     px_lc,  #2
    strh	colour, [fbp, px_lc]
    add     px_lc,  #2
    strh	colour, [fbp, px_lc]
    add     px_lc,  #2
    strh	colour, [fbp, px_lc]
    add     px_lc,  r10,    lsl #1
    sub     px_lc,  #6
    strh	colour, [fbp, px_lc]
    add     px_lc,  #2
    strh	colour, [fbp, px_lc]
    add     px_lc,  #2
    strh	colour, [fbp, px_lc]
    b       noPixel$

noPixel$:
	add		px,		#3			//increment x coordinate by 3

	lsl		mask,	#1			//shift bitmask left by 1
	tst		mask,	#0x100		//test if the bitmask has shifted 8 times (test 9th bit)
	beq		rowLoop$
	add		py,		#2			//increment y coordinate by 3

    tst		chAdr,	#0xF
	bne		charLoop$			//loop back to charLoop$, unless address evenly divisibly be 16 (ie: at the next char)
    .unreq  charac
    .unreq  offset
    .unreq  colour
    .unreq  px
    .unreq  py
    .unreq  chAdr
    .unreq  row
    .unreq  mask
    .unreq  px_lc
    .unreq  fbp
	pop		{r4-r10, pc}
    mov     pc,     lr

/* Input Arguments
 - r0 = character to write
 - r1 = block offset for pixel
 - r2 = text color
 */
.globl small_write
small_write:
    push    {r4-r10, lr}
    //character
    charac  .req    r0
    //pixel location
    offset  .req    r1
    //text color
    colour  .req    r2
    //x pixel coordinate = 0
    px      .req    r3
    //y pixel coordinate = 0
    py      .req    r4
    mov		py,		#0              //init the Y coordinate (pixel coordinate)
    //character font set address
    chAdr   .req    r5
    ldr     chAdr,  =font
    add		chAdr,	charac, lsl #4	//char address = font base + (char * 16)
    //row
    row     .req    r6
    //bitmask
    mask    .req    r7
    //pixel location
    px_lc   .req    r8
    //frame buffer pointer
    fbp     .req    r9
    ldr     fbp,    =FrameBufferPointer
    ldr     fbp,    [fbp]

small_charLoop$:
	mov		px,		#0			//init the X coordinate
	mov		mask,	#0x1		//set the bitmask to 1 in the LSB
	ldrb	row,	[chAdr], #1	//load the row byte, post increment chAdr

small_rowLoop$:
	tst		row,	mask		//test row byte against the bitmask
	beq		small_noPixel$
	b		small_DrawPixel			//draw pixel at (px, py)

small_DrawPixel:
    //pixel location = offset + 32 * [(y * 1024) + x]
    add     px_lc,  px, py, lsl #10
    add     px_lc,  offset
    ldr     r10,    =1024
    //offset *= 2 (for 16 bits per pixel = 2 bytes per pixel)
    lsl		px_lc, #1
    //store the colour (half word) at framebuffer pointer + offset
    strh	colour, [fbp, px_lc]
    //scale text by 2x
    add     px_lc,  #2
    strh	colour, [fbp, px_lc]
    add     px_lc,  r10,    lsl #1
    sub     px_lc,  #2
    strh	colour, [fbp, px_lc]
    add     px_lc,  #2
    strh	colour, [fbp, px_lc]
    b       small_noPixel$

small_noPixel$:
	add		px,		#1			//increment x coordinate by 2

	lsl		mask,	#1			//shift bitmask left by 1
	tst		mask,	#0x100		//test if the bitmask has shifted 8 times (test 9th bit)
	beq		small_rowLoop$
	add		py,		#1			//increment y coordinate by 2

    tst		chAdr,	#0xF
	bne		small_charLoop$			//loop back to charLoop$, unless address evenly divisibly be 16 (ie: at the next char)
    .unreq  charac
    .unreq  offset
    .unreq  colour
    .unreq  px
    .unreq  py
    .unreq  chAdr
    .unreq  row
    .unreq  mask
    .unreq  px_lc
    .unreq  fbp
	pop		{r4-r10, pc}
    mov     pc,     lr

.section .data
font:
    .incbin	"font.bin"
