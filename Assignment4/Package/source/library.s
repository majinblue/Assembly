/* INPUT ARGUMENTS (from draw.s to library.s)
 - r0 = category and shape
 eg. 0c (block - cloud)
/* OTHER REGISTERS
 - r4 = shape
 - r5 = category
/* OUTPUT ARGUMENTS
 - r0 = 32x32 block pixel data */

.globl library
library:
    push    {r4-r10, lr}
    //return block data in r0
    bdata   .req        r0
    //category and shape
    shape   .req    r4
    mov     shape,  bdata
    //shape is 16 bits, put right 8 into category, keep left 8 in shape
    category    .req    r5
    mov     category,   shape
    bic     category,   #0xff00
    lsr     shape,  #8

    cmp category, #0            //drawBlock
    beq drawBlock
    cmp category, #1            //drawCloud
    beq drawCloud
    cmp category, #2            //drawElement
    beq drawElement
    cmp category, #3            //drawFlag
    beq drawFlag
    cmp category, #4            //drawGoomba
    beq drawGoomba
    cmp category, #5            //drawLakitu
    beq drawLakitu
    cmp category, #6            //drawMario
    beq drawMario
    cmp category, #7            //drawPipe
    beq drawPipe
    cmp category, #8            //drawPlant
    beq drawPlant
    cmp category, #9            //drawSpike
    beq drawSpike
    cmp category, #0x63         //draw(C)astle c hex
    beq drawCastle
    cmp category, #0x6d         //draw(M)enu m hex
    beq drawMenu

// check_Boundary on each x while y = 0
drawBlock:
// shape = block type (eg. mystery block)
    cmp shape,  #0x62           //(B)lack
    ldreq       bdata,  =black
    beq         draw_return
    cmp shape,  #0x63           //(C)loud
    ldreq       bdata,  =cloud
    beq         draw_return
    cmp shape,  #0x64           //soli(D)
    ldreq       bdata,  =solid
    beq         draw_return
    cmp shape,  #0x65           //(E)mpty
    ldreq       bdata,  =empty
    beq         draw_return
    cmp shape,  #0x66           //(F)loor
    ldreq       bdata,  =floor
    beq         draw_return
    cmp shape,  #0x6d           //(M)ystery
    ldreq       bdata,  =mystery
    beq         draw_return
    cmp shape,  #0x73           //(S)ky
    ldreq       bdata,  =sky
    beq         draw_return
    cmp shape,  #0x77           //(W)ood
    ldreq       bdata,  =wood
    beq         draw_return
drawCastle:
// castle is 9*9 blocks
    //row 0
    cmp shape, #0x0             //0,0
    ldreq       bdata,  =castle_0_0
    beq         draw_return
    cmp shape, #0x1             //0,1
    ldreq       bdata,  =castle_0_1
    beq         draw_return
    cmp shape, #0x2             //0,2
    ldreq       bdata,  =castle_0_2
    beq         draw_return
    cmp shape, #0x3             //0,3
    ldreq       bdata,  =castle_0_3
    beq         draw_return
    cmp shape, #0x4             //0,4
    ldreq       bdata,  =castle_0_4
    beq         draw_return
    cmp shape, #0x5             //0,5
    ldreq       bdata,  =castle_0_5
    beq         draw_return
    cmp shape, #0x6             //0,6
    ldreq       bdata,  =castle_0_6
    beq         draw_return
    cmp shape, #0x7             //0,7
    ldreq       bdata,  =castle_0_7
    beq         draw_return
    cmp shape, #0x8             //0,8
    ldreq       bdata,  =castle_0_8
    beq         draw_return
    //row 1
    cmp shape, #0x10            //1,0
    ldreq       bdata,  =castle_1_0
    beq         draw_return
    cmp shape, #0x11            //1,1
    ldreq       bdata,  =castle_1_1
    beq         draw_return
    cmp shape, #0x12            //1,2
    ldreq       bdata,  =castle_1_2
    beq         draw_return
    cmp shape, #0x13            //1,3
    ldreq       bdata,  =castle_1_3
    beq         draw_return
    cmp shape, #0x14            //1,4
    ldreq       bdata,  =castle_1_4
    beq         draw_return
    cmp shape, #0x15            //1,5
    ldreq       bdata,  =castle_1_5
    beq         draw_return
    cmp shape, #0x16            //1,6
    ldreq       bdata,  =castle_1_6
    beq         draw_return
    cmp shape, #0x17            //1,7
    ldreq       bdata,  =castle_1_7
    beq         draw_return
    cmp shape, #0x18            //1,8
    ldreq       bdata,  =castle_1_8
    beq         draw_return
    //row 2
    cmp shape, #0x20            //2,0
    ldreq       bdata,  =castle_2_0
    beq         draw_return
    cmp shape, #0x21            //2,1
    ldreq       bdata,  =castle_2_1
    beq         draw_return
    cmp shape, #0x22            //2,2
    ldreq       bdata,  =castle_2_2
    beq         draw_return
    cmp shape, #0x23            //2,3
    ldreq       bdata,  =castle_2_3
    beq         draw_return
    cmp shape, #0x24            //2,4
    ldreq       bdata,  =castle_2_4
    beq         draw_return
    cmp shape, #0x25            //2,5
    ldreq       bdata,  =castle_2_5
    beq         draw_return
    cmp shape, #0x26            //2,6
    ldreq       bdata,  =castle_2_6
    beq         draw_return
    cmp shape, #0x27            //2,7
    ldreq       bdata,  =castle_2_7
    beq         draw_return
    cmp shape, #0x28            //2,8
    ldreq       bdata,  =castle_2_8
    beq         draw_return
    //row 3
    cmp shape, #0x30            //3,0
    ldreq       bdata,  =castle_3_0
    beq         draw_return
    cmp shape, #0x31            //3,1
    ldreq       bdata,  =castle_3_1
    beq         draw_return
    cmp shape, #0x32            //3,2
    ldreq       bdata,  =castle_3_2
    beq         draw_return
    cmp shape, #0x33            //3,3
    ldreq       bdata,  =castle_3_3
    beq         draw_return
    cmp shape, #0x34            //3,4
    ldreq       bdata,  =castle_3_4
    beq         draw_return
    cmp shape, #0x35            //3,5
    ldreq       bdata,  =castle_3_5
    beq         draw_return
    cmp shape, #0x36            //3,6
    ldreq       bdata,  =castle_3_6
    beq         draw_return
    cmp shape, #0x37            //3,7
    ldreq       bdata,  =castle_3_7
    beq         draw_return
    cmp shape, #0x38            //3,8
    ldreq       bdata,  =castle_3_8
    beq         draw_return
    //row 4
    cmp shape, #0x40            //4,0
    ldreq       bdata,  =castle_4_0
    beq         draw_return
    cmp shape, #0x41            //4,1
    ldreq       bdata,  =castle_4_1
    beq         draw_return
    cmp shape, #0x42            //4,2
    ldreq       bdata,  =castle_4_2
    beq         draw_return
    cmp shape, #0x43            //4,3
    ldreq       bdata,  =castle_4_3
    beq         draw_return
    cmp shape, #0x44            //4,4
    ldreq       bdata,  =castle_4_4
    beq         draw_return
    cmp shape, #0x45            //4,5
    ldreq       bdata,  =castle_4_5
    beq         draw_return
    cmp shape, #0x46            //4,6
    ldreq       bdata,  =castle_4_6
    beq         draw_return
    cmp shape, #0x47            //4,7
    ldreq       bdata,  =castle_4_7
    beq         draw_return
    cmp shape, #0x48            //4,8
    ldreq       bdata,  =castle_4_8
    beq         draw_return
    //row 5
    cmp shape, #0x50            //5,0
    ldreq       bdata,  =castle_5_0
    beq         draw_return
    cmp shape, #0x51            //5,1
    ldreq       bdata,  =castle_5_1
    beq         draw_return
    cmp shape, #0x52            //5,2
    ldreq       bdata,  =castle_5_2
    beq         draw_return
    cmp shape, #0x53            //5,3
    ldreq       bdata,  =castle_5_3
    beq         draw_return
    cmp shape, #0x54            //5,4
    ldreq       bdata,  =castle_5_4
    beq         draw_return
    cmp shape, #0x55            //5,5
    ldreq       bdata,  =castle_5_5
    beq         draw_return
    cmp shape, #0x56            //5,6
    ldreq       bdata,  =castle_5_6
    beq         draw_return
    cmp shape, #0x57            //5,7
    ldreq       bdata,  =castle_5_7
    beq         draw_return
    cmp shape, #0x58            //5,8
    ldreq       bdata,  =castle_5_8
    beq         draw_return
    //row 6
    cmp shape, #0x60            //6,0
    ldreq       bdata,  =castle_6_0
    beq         draw_return
    cmp shape, #0x61            //6,1
    ldreq       bdata,  =castle_6_1
    beq         draw_return
    cmp shape, #0x62            //6,2
    ldreq       bdata,  =castle_6_2
    beq         draw_return
    cmp shape, #0x63            //6,3
    ldreq       bdata,  =castle_6_3
    beq         draw_return
    cmp shape, #0x64            //6,4
    ldreq       bdata,  =castle_6_4
    beq         draw_return
    cmp shape, #0x65            //6,5
    ldreq       bdata,  =castle_6_5
    beq         draw_return
    cmp shape, #0x66            //6,6
    ldreq       bdata,  =castle_6_6
    beq         draw_return
    cmp shape, #0x67            //6,7
    ldreq       bdata,  =castle_6_7
    beq         draw_return
    cmp shape, #0x68            //6,8
    ldreq       bdata,  =castle_6_8
    beq         draw_return
    //row 7
    cmp shape, #0x70            //7,0
    ldreq       bdata,  =castle_7_0
    beq         draw_return
    cmp shape, #0x71            //7,1
    ldreq       bdata,  =castle_7_1
    beq         draw_return
    cmp shape, #0x72            //7,2
    ldreq       bdata,  =castle_7_2
    beq         draw_return
    cmp shape, #0x73            //7,3
    ldreq       bdata,  =castle_7_3
    beq         draw_return
    cmp shape, #0x74            //7,4
    ldreq       bdata,  =castle_7_4
    beq         draw_return
    cmp shape, #0x75            //7,5
    ldreq       bdata,  =castle_7_5
    beq         draw_return
    cmp shape, #0x76            //7,6
    ldreq       bdata,  =castle_7_6
    beq         draw_return
    cmp shape, #0x77            //7,7
    ldreq       bdata,  =castle_7_7
    beq         draw_return
    cmp shape, #0x78            //7,8
    ldreq       bdata,  =castle_7_8
    beq         draw_return
    //row 8
    cmp shape, #0x80            //8,0
    ldreq       bdata,  =castle_8_0
    beq         draw_return
    cmp shape, #0x81            //8,1
    ldreq       bdata,  =castle_8_1
    beq         draw_return
    cmp shape, #0x82            //8,2
    ldreq       bdata,  =castle_8_2
    beq         draw_return
    cmp shape, #0x83            //8,3
    ldreq       bdata,  =castle_8_3
    beq         draw_return
    cmp shape, #0x84            //8,4
    ldreq       bdata,  =castle_8_4
    beq         draw_return
    cmp shape, #0x85            //8,5
    ldreq       bdata,  =castle_8_5
    beq         draw_return
    cmp shape, #0x86            //8,6
    ldreq       bdata,  =castle_8_6
    beq         draw_return
    cmp shape, #0x87            //8,7
    ldreq       bdata,  =castle_8_7
    beq         draw_return
    cmp shape, #0x88            //8,8
    ldreq       bdata,  =castle_8_8
    beq         draw_return
drawCloud:
// clouds are width*2 blocks
    //2*2
    cmp shape, #0x0             //2*2 0,0
    ldreq       bdata,  =two_0_0
    beq         draw_return
    cmp shape, #0x1             //2*2 0,1
    ldreq       bdata,  =two_0_1
    beq         draw_return
    cmp shape, #0x10            //2*2 1,0
    ldreq       bdata,  =two_1_0
    beq         draw_return
    cmp shape, #0x11            //2*2 1,1
    ldreq       bdata,  =two_1_1
    beq         draw_return
    //3*2
    cmp shape, #0x20            //3*2 0,0
    ldreq       bdata,  =three_0_0
    beq         draw_return
    cmp shape, #0x21            //3*2 0,1
    ldreq       bdata,  =three_0_1
    beq         draw_return
    cmp shape, #0x22            //3*2 0,2
    ldreq       bdata,  =three_0_2
    beq         draw_return
    cmp shape, #0x30            //3*2 1,0
    ldreq       bdata,  =three_1_0
    beq         draw_return
    cmp shape, #0x31            //3*2 1,1
    ldreq       bdata,  =three_1_1
    beq         draw_return
    cmp shape, #0x32            //3*2 1,2
    ldreq       bdata,  =three_1_2
    beq         draw_return
    //4*2
    cmp shape, #0x40            //4*2 0,0
    ldreq       bdata,  =four_0_0
    beq         draw_return
    cmp shape, #0x41            //4*2 0,1
    ldreq       bdata,  =four_0_1
    beq         draw_return
    cmp shape, #0x42            //4*2 0,2
    ldreq       bdata,  =four_0_2
    beq         draw_return
    cmp shape, #0x43            //4*2 0,3
    ldreq       bdata,  =four_0_3
    beq         draw_return
    cmp shape, #0x50            //4*2 1,0
    ldreq       bdata,  =four_1_0
    beq         draw_return
    cmp shape, #0x51            //4*2 1,1
    ldreq       bdata,  =four_1_1
    beq         draw_return
    cmp shape, #0x52            //4*2 1,2
    ldreq       bdata,  =four_1_2
    beq         draw_return
    cmp shape, #0x53            //4*2 1,3
    ldreq       bdata,  =four_1_3
    beq         draw_return
drawElement:
// shape = element type (eg. mushroom)
    cmp shape, #0x0            //coin
    ldreq       bdata,  =coin
    beq         draw_return
    cmp shape, #0x1            //flag
    ldreq       bdata,  =flag
    beq         draw_return
    cmp shape, #0x2            //mushroom
    ldreq       bdata,  =mushroom
    beq         draw_return
    cmp shape, #0x3            //mushroom2 (life)
    ldreq       bdata,  =mushroom2
    beq         draw_return
drawFlag:
// draw row 0, 1 and then loop row 2 six times
    cmp shape, #0x0            //flag 0,0
    ldr bdata, =flag_0_0
    beq         draw_return
    cmp shape, #0x1            //flag 0,1
    ldr bdata, =flag_0_1
    beq         draw_return
    cmp shape, #0x10           //flag 1,0
    ldr bdata, =flag_1_0
    beq         draw_return
    cmp shape, #0x11           //flag 1,1
    ldr bdata, =flag_1_1
    beq         draw_return
    cmp shape, #0x20           //flag 2,0
    ldr bdata, =flag_2_0
    beq         draw_return
    cmp shape, #0x21           //flag 2,1
    ldr bdata, =flag_2_1
    beq         draw_return
drawGoomba:
// shape = goomba sprite (eg. walk left)
    cmp shape, #0x0            //walk right
    ldreq       bdata,  =goomba_walkr
    beq         draw_return
    cmp shape, #0x1            //walk left
    ldreq       bdata,  =goomba_walkr
    beq         draw_return
//    cmp shape, #0x2            //flattened
//    ldreq       bdata,  =goomba_flat
//    beq         draw_return
drawLakitu:
// shape = lakitu sprite (eg. upside down)
    //0 degrees (north)
    cmp shape,  #0x0            //top left
    ldreq       bdata,  =north_0_0
    beq         draw_return
    cmp shape,  #0x1            //top right
    ldreq       bdata,  =north_0_1
    beq         draw_return
    cmp shape,  #0x2            //bottom left
    ldreq       bdata,  =north_1_0
    beq         draw_return
    cmp shape,  #0x3            //bottom right
    ldreq       bdata,  =north_1_1
    beq         draw_return
    //90 degrees (east)
    cmp shape,  #0x10           //top left
    ldreq       bdata,  =east_0_0
    beq         draw_return
    cmp shape,  #0x11           //top right
    ldreq       bdata,  =east_0_1
    beq         draw_return
    cmp shape,  #0x12           //bottom left
    ldreq       bdata,  =east_1_0
    beq         draw_return
    cmp shape,  #0x13           //bottom right
    ldreq       bdata,  =east_1_1
    beq         draw_return
    //180 degrees (south)
    cmp shape,  #0x20           //top left
    ldreq       bdata,  =south_0_0
    beq         draw_return
    cmp shape,  #0x21           //top right
    ldreq       bdata,  =south_0_1
    beq         draw_return
    cmp shape,  #0x22           //bottom left
    ldreq       bdata,  =south_1_0
    beq         draw_return
    cmp shape,  #0x23           //bottom right
    ldreq       bdata,  =south_1_1
    beq         draw_return
    //270 degrees (west)
    cmp shape,  #0x30           //top left
    ldreq       bdata,  =west_0_0
    beq         draw_return
    cmp shape,  #0x31           //top right
    ldreq       bdata,  =west_0_1
    beq         draw_return
    cmp shape,  #0x32           //bottom left
    ldreq       bdata,  =west_1_0
    beq         draw_return
    cmp shape,  #0x33           //bottom right
    ldreq       bdata,  =west_1_1
    beq         draw_return
drawMario:
    cmp shape, #0x0            //stand right
    ldr bdata, =mario_standr
    beq         draw_return
    cmp shape, #0x1            //step right
    ldr bdata, =mario_stepr
    beq         draw_return
    cmp shape, #0x2            //walk right
    ldr bdata, =mario_walkr
    beq         draw_return
    cmp shape, #0x3            //slow right
    ldr bdata, =mario_slowr
    beq         draw_return
    cmp shape, #0x4            //stop right
    ldr bdata, =mario_stopr
    beq         draw_return
    cmp shape, #0x5            //jump right
    ldr bdata, =mario_jumpr
    beq         draw_return
    cmp shape, #0x10           //stand left
    ldr bdata, =mario_standl
    beq         draw_return
    cmp shape, #0x11           //step left
    ldr bdata, =mario_stepl
    beq         draw_return
    cmp shape, #0x12           //walk left
    ldr bdata, =mario_walkl
    beq         draw_return
    cmp shape, #0x13           //slow left
    ldr bdata, =mario_slowl
    beq         draw_return
    cmp shape, #0x14           //stop left
    ldr bdata, =mario_stopl
    beq         draw_return
    cmp shape, #0x15           //jump left
    ldr bdata, =mario_jumpl
    beq         draw_return
    cmp shape, #0x20           //dead
    ldr bdata, =mario_dead
    beq         draw_return
drawMenu:
// menu is 11*6 blocks
    //row 0
    cmp shape, #0x0             //0,0
    ldreq       bdata,  =menu_0_0
    beq         draw_return
    cmp shape, #0x1             //0,1
    ldreq       bdata,  =menu_0_1
    beq         draw_return
    cmp shape, #0x2             //0,2
    ldreq       bdata,  =menu_0_2
    beq         draw_return
    cmp shape, #0x3             //0,3
    ldreq       bdata,  =menu_0_3
    beq         draw_return
    cmp shape, #0x4             //0,4
    ldreq       bdata,  =menu_0_4
    beq         draw_return
    cmp shape, #0x5             //0,5
    ldreq       bdata,  =menu_0_5
    beq         draw_return
    cmp shape, #0x6             //0,6
    ldreq       bdata,  =menu_0_6
    beq         draw_return
    cmp shape, #0x7             //0,7
    ldreq       bdata,  =menu_0_7
    beq         draw_return
    cmp shape, #0x8             //0,8
    ldreq       bdata,  =menu_0_8
    beq         draw_return
    cmp shape, #0x9             //0,9
    ldreq       bdata,  =menu_0_9
    beq         draw_return
    cmp shape, #0xa             //0,a
    ldreq       bdata,  =menu_0_10
    beq         draw_return
    //row 1
    cmp shape, #0x10            //1,0
    ldreq       bdata,  =menu_1_0
    beq         draw_return
    cmp shape, #0x11            //1,1
    ldreq       bdata,  =menu_1_1
    beq         draw_return
    cmp shape, #0x12            //1,2
    ldreq       bdata,  =menu_1_2
    beq         draw_return
    cmp shape, #0x13            //1,3
    ldreq       bdata,  =menu_1_3
    beq         draw_return
    cmp shape, #0x14            //1,4
    ldreq       bdata,  =menu_1_4
    beq         draw_return
    cmp shape, #0x15            //1,5
    ldreq       bdata,  =menu_1_5
    beq         draw_return
    cmp shape, #0x16            //1,6
    ldreq       bdata,  =menu_1_6
    beq         draw_return
    cmp shape, #0x17            //1,7
    ldreq       bdata,  =menu_1_7
    beq         draw_return
    cmp shape, #0x18            //1,8
    ldreq       bdata,  =menu_1_8
    beq         draw_return
    cmp shape, #0x19            //1,9
    ldreq       bdata,  =menu_1_9
    beq         draw_return
    cmp shape, #0x1a            //1,a
    ldreq       bdata,  =menu_1_10
    beq         draw_return
    //row 2
    cmp shape, #0x20            //2,0
    ldreq       bdata,  =menu_2_0
    beq         draw_return
    cmp shape, #0x21            //2,1
    ldreq       bdata,  =menu_2_1
    beq         draw_return
    cmp shape, #0x22            //2,2
    ldreq       bdata,  =menu_2_2
    beq         draw_return
    cmp shape, #0x23            //2,3
    ldreq       bdata,  =menu_2_3
    beq         draw_return
    cmp shape, #0x24            //2,4
    ldreq       bdata,  =menu_2_4
    beq         draw_return
    cmp shape, #0x25            //2,5
    ldreq       bdata,  =menu_2_5
    beq         draw_return
    cmp shape, #0x26            //2,6
    ldreq       bdata,  =menu_2_6
    beq         draw_return
    cmp shape, #0x27            //2,7
    ldreq       bdata,  =menu_2_7
    beq         draw_return
    cmp shape, #0x28            //2,8
    ldreq       bdata,  =menu_2_8
    beq         draw_return
    cmp shape, #0x29            //2,9
    ldreq       bdata,  =menu_2_9
    beq         draw_return
    cmp shape, #0x2a            //2,a
    ldreq       bdata,  =menu_2_10
    beq         draw_return
    //row 3
    cmp shape, #0x30            //3,0
    ldreq       bdata,  =menu_3_0
    beq         draw_return
    cmp shape, #0x31            //3,1
    ldreq       bdata,  =menu_3_1
    beq         draw_return
    cmp shape, #0x32            //3,2
    ldreq       bdata,  =menu_3_2
    beq         draw_return
    cmp shape, #0x33            //3,3
    ldreq       bdata,  =menu_3_3
    beq         draw_return
    cmp shape, #0x34            //3,4
    ldreq       bdata,  =menu_3_4
    beq         draw_return
    cmp shape, #0x35            //3,5
    ldreq       bdata,  =menu_3_5
    beq         draw_return
    cmp shape, #0x36            //3,6
    ldreq       bdata,  =menu_3_6
    beq         draw_return
    cmp shape, #0x37            //3,7
    ldreq       bdata,  =menu_3_7
    beq         draw_return
    cmp shape, #0x38            //3,8
    ldreq       bdata,  =menu_3_8
    beq         draw_return
    cmp shape, #0x39            //3,9
    ldreq       bdata,  =menu_3_9
    beq         draw_return
    cmp shape, #0x3a            //3,a
    ldreq       bdata,  =menu_3_10
    beq         draw_return
    //row 4
    cmp shape, #0x40            //4,0
    ldreq       bdata,  =menu_4_0
    beq         draw_return
    cmp shape, #0x41            //4,1
    ldreq       bdata,  =menu_4_1
    beq         draw_return
    cmp shape, #0x42            //4,2
    ldreq       bdata,  =menu_4_2
    beq         draw_return
    cmp shape, #0x43            //4,3
    ldreq       bdata,  =menu_4_3
    beq         draw_return
    cmp shape, #0x44            //4,4
    ldreq       bdata,  =menu_4_4
    beq         draw_return
    cmp shape, #0x45            //4,5
    ldreq       bdata,  =menu_4_5
    beq         draw_return
    cmp shape, #0x46            //4,6
    ldreq       bdata,  =menu_4_6
    beq         draw_return
    cmp shape, #0x47            //4,7
    ldreq       bdata,  =menu_4_7
    beq         draw_return
    cmp shape, #0x48            //4,8
    ldreq       bdata,  =menu_4_8
    beq         draw_return
    cmp shape, #0x49            //4,9
    ldreq       bdata,  =menu_4_9
    beq         draw_return
    cmp shape, #0x4a            //4,a
    ldreq       bdata,  =menu_4_10
    beq         draw_return
    //row 5
    cmp shape, #0x50            //5,0
    ldreq       bdata,  =menu_5_0
    beq         draw_return
    cmp shape, #0x51            //5,1
    ldreq       bdata,  =menu_5_1
    beq         draw_return
    cmp shape, #0x52            //5,2
    ldreq       bdata,  =menu_5_2
    beq         draw_return
    cmp shape, #0x53            //5,3
    ldreq       bdata,  =menu_5_3
    beq         draw_return
    cmp shape, #0x54            //5,4
    ldreq       bdata,  =menu_5_4
    beq         draw_return
    cmp shape, #0x55            //5,5
    ldreq       bdata,  =menu_5_5
    beq         draw_return
    cmp shape, #0x56            //5,6
    ldreq       bdata,  =menu_5_6
    beq         draw_return
    cmp shape, #0x57            //5,7
    ldreq       bdata,  =menu_5_7
    beq         draw_return
    cmp shape, #0x58            //5,8
    ldreq       bdata,  =menu_5_8
    beq         draw_return
    cmp shape, #0x59            //5,9
    ldreq       bdata,  =menu_5_9
    beq         draw_return
    cmp shape, #0x5a            //5,a
    ldreq       bdata,  =menu_5_10
    beq         draw_return
drawPipe:
// draw row 0, 1 then loop 2, 3 as necessary
    cmp shape,  #0x0            //0,0 of pipe
    ldr bdata,  =pipe_0_0
    beq         draw_return
    cmp shape,  #0x1            //0,1 of pipe
    ldr bdata,  =pipe_0_1
    beq         draw_return
    cmp shape,  #0x2            //0,2 of pipe
    ldr bdata,  =pipe_0_2
    beq         draw_return
    cmp shape,  #0x10           //1,0 of pipe
    ldr bdata,  =pipe_1_0
    beq         draw_return
    cmp shape,  #0x11           //1,1 of pipe
    ldr bdata,  =pipe_1_1
    beq         draw_return
    cmp shape,  #0x12           //2,2 of pipe
    ldr bdata,  =pipe_1_2
    beq         draw_return
    cmp shape,  #0x20           //2,1 of pipe
    ldr bdata,  =pipe_2_0
    beq         draw_return
    cmp shape,  #0x21           //2,3 of pipe
    ldr bdata,  =pipe_2_1
    beq         draw_return
    cmp shape,  #0x22           //3,1 of pipe
    ldr bdata,  =pipe_2_2
    beq         draw_return
    cmp shape,  #0x30           //3,0 of pipe
    ldr bdata,  =pipe_3_0
    beq         draw_return
    cmp shape,  #0x31           //3,1 of pipe
    ldr bdata,  =pipe_3_1
    beq         draw_return
    cmp shape,  #0x32           //3,2 of pipe
    ldr bdata,  =pipe_3_2
    beq         draw_return
drawPlant:
    //plant0 5*3
    cmp shape, #0x0             //p0_0_0
    ldr bdata,  =plant0_0_0
    beq         draw_return
    cmp shape, #0x1             //p0_0_1
    ldr bdata,  =plant0_0_1
    beq         draw_return
    cmp shape, #0x2             //p0_0_2
    ldr bdata,  =plant0_0_2
    beq         draw_return
    cmp shape, #0x3             //p0_0_3
    ldr bdata,  =plant0_0_3
    beq         draw_return
    cmp shape, #0x4             //p0_0_4
    ldr bdata,  =plant0_0_4
    beq         draw_return
    cmp shape, #0x5             //p0_1_0
    ldr bdata,  =plant0_1_0
    beq         draw_return
    cmp shape, #0x6             //p0_1_1
    ldr bdata,  =plant0_1_1
    beq         draw_return
    cmp shape, #0x7             //p0_1_2
    ldr bdata,  =plant0_1_2
    beq         draw_return
    cmp shape, #0x8             //p0_1_3
    ldr bdata,  =plant0_1_3
    beq         draw_return
    cmp shape, #0x9             //p0_1_4
    ldr bdata,  =plant0_1_4
    beq         draw_return
    cmp shape, #0xa             //p0_2_0
    ldr bdata,  =plant0_2_0
    beq         draw_return
    cmp shape, #0xb             //p0_2_1
    ldr bdata,  =plant0_2_1
    beq         draw_return
    cmp shape, #0xc             //p0_2_2
    ldr bdata,  =plant0_2_2
    beq         draw_return
    cmp shape, #0xd             //p0_2_3
    ldr bdata,  =plant0_2_3
    beq         draw_return
    cmp shape, #0xe             //p0_2_4
    ldr bdata,  =plant0_2_4
    beq         draw_return
    //plant1 4*1
    cmp shape, #0x10            //p1_0_0
    ldr bdata,  =plant1_0_0
    beq         draw_return
    cmp shape, #0x11            //p1_0_1
    ldr bdata,  =plant1_0_1
    beq         draw_return
    cmp shape, #0x12            //p1_0_2
    ldr bdata,  =plant1_0_2
    beq         draw_return
    cmp shape, #0x13            //p1_0_3
    ldr bdata,  =plant1_0_3
    beq         draw_return
    //plant2 3*1
    cmp shape, #0x20            //p2_0_0
    ldr bdata,  =plant2_0_0
    beq         draw_return
    cmp shape, #0x21            //p2_0_1
    ldr bdata,  =plant2_0_1
    beq         draw_return
    cmp shape, #0x22            //p2_0_2
    ldr bdata,  =plant2_0_2
    beq         draw_return
    //plant3 5*2
    cmp shape, #0x30            //p3_0_0
    ldr bdata,  =plant3_0_0
    beq         draw_return
    cmp shape, #0x31            //p3_0_1
    ldr bdata,  =plant3_0_1
    beq         draw_return
    cmp shape, #0x32            //p3_0_2
    ldr bdata,  =plant3_0_2
    beq         draw_return
    cmp shape, #0x33            //p3_0_3
    ldr bdata,  =plant3_0_3
    beq         draw_return
    cmp shape, #0x34            //p3_0_4
    ldr bdata,  =plant3_0_4
    beq         draw_return
    cmp shape, #0x35            //p3_1_0
    ldr bdata,  =plant3_1_0
    beq         draw_return
    cmp shape, #0x36            //p3_1_1
    ldr bdata,  =plant3_1_1
    beq         draw_return
    cmp shape, #0x37            //p3_1_2
    ldr bdata,  =plant3_1_2
    beq         draw_return
    cmp shape, #0x38            //p3_1_3
    ldr bdata,  =plant3_1_3
    beq         draw_return
    cmp shape, #0x39            //p3_1_4
    ldr bdata,  =plant3_1_4
    beq         draw_return
drawSpike:
    cmp shape, #0x0             //stand right
    ldr         bdata,  =spike_standr
    beq         draw_return
    cmp shape, #0x1             //walk right
    ldr         bdata,  =spike_walkr
    beq         draw_return
    cmp shape, #0x10            //stand left
    ldr         bdata,  =spike_standl
    beq         draw_return
    cmp shape, #0x11            //walk left
    ldr         bdata,  =spike_walkl
    beq         draw_return

draw_return:
    .unreq  bdata
    .unreq  shape
    .unreq  category
    pop	{r4-r10, lr}
    mov pc, lr
