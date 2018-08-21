//Created by:
//Gevorg Manukyan 10163988
//Richard Truong 10058625

.section    .init
.globl     _start

_start:
    b       main
    
.section .text

main:
mov     sp, #0x8000 // Initializing the stack pointer
	bl		EnableJTAG // Enable JTAG
	bl		InitUART //This is important to be able to use UART



ldr r0, =string0 	//Address of the label in data section containing the data you want to print	
mov r1, #48		//Number of characters to print
bl WriteStringUART 	

menu:	
ldr r0, =string1 	//Address of the label in data section containing the data you want to print
mov r1, #132	//Number of characters needed to be print
bl WriteStringUART  		

ldr r0,=Buffer	//The buffer which will store user input. user input will be stored in terms of bytes using ascii	
mov r1, #256    // Number of bytes allocated for user input in the memory
bl ReadLineUART // it will return in r0 number of characters user entered
		
	
ldr r4, =Buffer
ldrb r5, [r4], #1


cmp r5, #113		// check for q
beq stop		// quit

// if r5 is 1, 2, 3, or - then check next byte	
cmp r5, #49		// check for 1
beq checkNext	
cmp r5, #50		// check for 2
beq checkNext		
cmp r5, #51		// check for 3
beq checkNext
cmp r5, #45		// check for -
beq checkNegNext	// negative has a different check
// otherwise invalid option
b error0	
	
checkNext:
ldrb r6, [r4], #1
// if next byte is null, then branch for 1, 2, or 3
cmp r6, #0
beq switchCase
b error0
	
checkNegNext:
// if next byte is 1, then input was -1 (show summary)
ldrb r6, [r4], #1
ldrb r7, [r4], #1	// check for additional bytes
cmp r7, #0		// the third byte should be null
bne error0		// otherwise error// 
cmp r6, #49		// if second byte is 1
beq summary		// then input was -1 so go to summary
b error0		// otherwise error
	
switchCase:
ldrb r7, [r4], #1	// check for additional bytes
cmp r7, #0		// the third byte should be null
bne error0		// otherwise error
// branch for 1, 2, 3
cmp r5, #49	// 1 for square
beq square	
cmp r5, #50	// 2 for rectangle
beq rectangle	
cmp r5, #51	// 3 for triangle
beq triangle 	
	
error0:
// invalid user input	
ldr r0, =string11
mov r1, #34
bl WriteStringUART
b menu
	
square:
ldr r0, =string2 	//Address of the label in data section containing the data you want to print
mov r1, #71	//Number of characters needed to be printed
bl WriteStringUART	
	
ldr r0,=Buffer	//The buffer which will store user input. user input will be stored in terms of bytes using ascii	
mov r1, #256    // Number of bytes allocated for user input in the memory
bl ReadLineUART // it will return in r0 number of characters user entered
	
ldr r9, =squareStars 	//Prepare star count for squares (address)
ldr r10, [r9]		//Prepare star count for squares (value)
	
ldr r4, =Buffer		// Buffer to register 4
ldrb r5, [r4], #1	// load first byte of input
mov r7, r5		// duplicate byte for loops
mov r8, r5		// duplicate byte for loops
ldrb r6, [r4], #1	// check for second byte 
cmp r6, #0		// the second byte should be null
bne error1		// otherwise error

// valid dimmensions for shape	
cmp r5, #51		
beq skip0 
cmp r5, #52
beq skip0	
cmp r5, #53	
beq skip0
cmp r5, #54	
beq skip0 
cmp r5, #55
beq skip0	
cmp r5, #56	
beq skip0	
cmp r5, #57	
beq skip0
b error1

squareloop:
mov r5, r8
	
skip0:
ldr r0, =string3 	//Address of the label in data section containing the data you want to print
mov r1, #2	//Number of characters needed to be print
bl WriteStringUART
	
add r10, r10, #1	// increment star count of squares
	
sub r5, r5, #1
cmp r5, #48
bne skip0
	
ldr r0, =string4 	//Address of the label in data section containing the data you want to print
mov r1, #2	//Number of characters needed to be print
bl WriteStringUART
	
sub r7, r7, #1
cmp r7, #48
bne squareloop

ldr r9, =squareStars 	//Load star count for squares (address)	
str r10, [r9]	// store new count into squareStars
b menu	

error1:
ldr r0, =string5 	//Address of the label in data section containing the data you want to print
mov r1, #52	//Number of characters needed to be print
bl WriteStringUART 
b square

rectangle:
ldr r0, =string2 	//Address of the label in data section containing the data you want to print
mov r1, #71	//Number of characters needed to be print
bl WriteStringUART	
	
ldr r0,=Buffer	//The buffer which will store user input. user input will be stored in terms of bytes using ascii	
mov r1, #256    // Number of bytes allocated for user input in the memory
bl ReadLineUART // it will return in r0 number of characters user entered

ldr r9, =rectangleStars //Prepare star count for rectangles (address)
ldr r10, [r9]		//Prepare star count for rectangles (value)
	
ldr r4, =Buffer	
ldrb r5, [r4], #1
mov r7, r5
mov r8, r5	
ldrb r6, [r4], #1
cmp r6, #0
bne error2	

// valid dimmensions for shape	
cmp r5, #51	
beq skip1 
cmp r5, #52
beq skip1	
cmp r5, #53	
beq skip1
cmp r5, #54	
beq skip1 
cmp r5, #55
beq skip1	
cmp r5, #56	
beq skip1	
cmp r5, #57	
beq skip1
b error2

rectangleloop:
mov r5, r8
	
skip1:
ldr r0, =string3 	//Address of the label in data section containing the data you want to print
mov r1, #2	//Number of characters needed to be print
bl WriteStringUART
	
add r10, r10, #1	// increment star count of rectangles
	
sub r5, r5, #1
cmp r5, #48	
bne skip1

ldr r0, =string4 	//Address of the label in data section containing the data you want to print
mov r1, #2	//Number of characters needed to be print
bl WriteStringUART 

sub r7, r7, #1
cmp r7, #50
bne rectangleloop

ldr r9, =rectangleStars //Load star count for rectangle (address)	
str r10, [r9]	// store new count into rectangleStars
	
b menu	

error2:
ldr r0, =string5 	//Address of the label in data section containing the data you want to print
mov r1, #52	//Number of characters needed to be print
bl WriteStringUART 
b rectangle


triangle:
ldr r0, =string2 	//Address of the label in data section containing the data you want to print
mov r1, #71	//Number of characters needed to be print
bl WriteStringUART	
	
ldr r0,=Buffer	//The buffer which will store user input. user input will be stored in terms of bytes using ascii	
mov r1, #256    // Number of bytes allocated for user input in the memory
bl ReadLineUART // it will return in r0 number of characters user entered

ldr r9, =triangleStars 	//Prepare star count for triangle (address)
ldr r10, [r9]		//Prepare star count for triangle (value)
	
// valid shape dimmensions	
ldr r4, =Buffer	
ldrb r5, [r4], #1
mov r7, r5
ldrb r6, [r4], #1
cmp r6, #0
bne error3	
cmp r5, #51	
beq triangleloop 
cmp r5, #52
beq triangleloop	
cmp r5, #53	
beq triangleloop
cmp r5, #54	
beq triangleloop
cmp r5, #55
beq triangleloop	
cmp r5, #56	
beq triangleloop	
cmp r5, #57	
beq triangleloop
b error3

mov r7, r5	
mov r6, r5

triangleloop:                                  
mov r9, r7
	
skip2:
ldr r0, =string3 	//Address of the label in data section containing the data you want to print
mov r1, #2	//Number of characters needed to be print
bl WriteStringUART

add r10, r10, #1	// increment star count of triangles

sub r9, r9, #1
cmp r9, #48	
bne skip2

ldr r0, =string4 	//Address of the label in data section containing the data you want to print
mov r1, #2	//Number of characters needed to be print
bl WriteStringUART 

sub r7, r7, #1
cmp r7, #48
	
sub r5, r5, #1	
bne triangleloop

ldr r9, =triangleStars 	//Load star count for triangles (address)	
str r10, [r9]	// store new count into triangleStars
	
b menu

error3:
ldr r0, =string5 	//Address of the label in data section containing the data you want to print
mov r1, #52	//Number of characters needed to be print
bl WriteStringUART 
b triangle	

summary:
ldr r0, =string7 	//Address of the label in data section containing the data you want to print
mov r1, #26		//Number of characters needed to be printed
bl WriteStringUART

// Total stars used will be calculated and stored in r5
mov r5,	#0	
ldr r4, =squareStars
ldr r6, [r4]	
ldr r4,	=rectangleStars
ldr r7, [r4]
ldr r4, =triangleStars
ldr r8, [r4]	
	
add r5, r5, r6
add r5, r5, r7
add r5, r5, r8

// Total stars printed by recursive loop
totalLoop:	
ldrb	r0,	[r5],	#1
mov r1, #1	
bl  WriteStringUART	
cmp	r0,	#0
bne	totalLoop	

squareSummary:
ldr r0, =string8 	//Address of the label in data section containing the data you want to print
mov r1, #36	//Number of characters needed to be printed
bl WriteStringUART
cmp r6, #0
bne meanSquare
mov r0, #48
mov r1, #1	
bl  WriteStringUART
b   rectangleSummary
// Square stars printed by recursive loop	
meanSquare:
udiv	r9, r6, r5
squareLoop:	
ldrb	r0,	[r9],	#1
mov r1, #1	
bl  WriteStringUART	
cmp	r0,	#0
bne	squareLoop
	
rectangleSummary:
ldr r0, =string9 	//Address of the label in data section containing the data you want to print
mov r1, #39	//Number of characters needed to be printed
bl WriteStringUART
cmp r7, #0
bne meanRectangle
mov r0, #48
mov r1, #1	
bl  WriteStringUART
b   triangleSummary
// rectangle stars printed by recursive loop	
meanRectangle:
udiv	r9, r7, r5
rectangleLoop:	
ldrb	r0,	[r9],	#1
mov r1, #1	
bl  WriteStringUART	
cmp	r0,	#0
bne	rectangleLoop

triangleSummary:
ldr r0, =string10 	//Address of the label in data section containing the data you want to print
mov r1, #38	//Number of characters needed to be printed
bl WriteStringUART
cmp r8, #0
bne meanTriangle
mov r0, #48
mov r1, #1	
bl  WriteStringUART
b   menu
// triangle stars printed by recursive loop	
meanTriangle:
udiv	r9, r8, r5
triangleLoop:	
ldrb	r0,	[r9],	#1	
mov r1, #1	
bl  WriteStringUART	
cmp	r0,	#0
bne	triangleLoop
	
b menu

stop:
	ldr r0, =string12 	//Address of the label in data section containing the data you want to print
	mov r1, #18	//Number of characters needed to be printed
	bl WriteStringUART
end:	
	b	end

.section .data  
string0:
	.ascii "Created By: Gevorg Manukyan and Richard Truong\r\n"
	.align
string1:	
	.ascii "Please enter the number of the object you want to draw. Press -1 for Summary or q to exit\r\n"
	.ascii "1- Square; 2- Rectangle; 3- Triangle\r\n"
	.align
string2:
	.ascii "Please enter width of object. Please make sure it is between 3 and 9.\r\n"
	.align
string3:
	.ascii "* "
	.align
string4:
	.ascii "\r\n"
	.align
string5:
	.ascii "Invalid number! The width should be between 3 and 9\r\n"
	.align
string6:
	.ascii " "
	.align
string7:
	.ascii "Total Number of Stars is:\r"
	.align
string8:
	.ascii "\nMean Stars used to draw Square(s):\r"
	.align
string9:
	.ascii "\nMean Stars used to draw Rectangle(s):\r"
	.align
string10:
	.ascii "\nMean Stars used to draw Triangle(s):\r"
	.align
string11:
	.ascii "Invalid Input: Please Choose Again\n\r"
	.align
string12:
	.ascii "Terminate Program."
	.align
	
squareStars:
    .int   0
rectangleStars:
    .int   0
triangleStars:
    .int   0
totalStars:
    .int   0

Buffer:
	.rept 256
	.byte 0
	.endr
