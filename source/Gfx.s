#ifdef __arm__

#include "Shared/gba_asm.h"
#include "Shared/EmuSettings.h"
#include "ARMZ80/ARMZ80.i"
#include "K005849/K005849.i"

	.global gfxInit
	.global gfxReset
	.global paletteInit
	.global paletteTxAll
	.global refreshGfx
	.global EMUPALBUFF
	.global endFrame
	.global gfxState
//	.global oamBufferReady
	.global gFlicker
	.global gTwitch
	.global gScaling
	.global gGfxMask
	.global vblIrqHandler
	.global yStart

	.global k005849_0
	.global k005849_0R
	.global k005849Ram_0W
	.global k005849_0W
	.global emuRAM


	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
gfxInit:					;@ Called from machineInit
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,=OAM_BUFFER1			;@ No stray sprites please
	mov r1,#0x200+SCREEN_HEIGHT
	mov r2,#0x100
	bl memset_
	adr r0,scaleParms
	bl setupSpriteScaling

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
scaleParms:					;@ NH     FH     NV     FV
	.long OAM_BUFFER1,0x0000,0x0100,0xff01,0x0150,0xfeb6
;@----------------------------------------------------------------------------
gfxReset:					;@ Called with CPU reset
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,=gfxState
	mov r1,#5					;@ 5*4
	bl memclr_					;@ Clear GFX regs

	ldr r0,=Z80SetNMIPin
	ldr r1,=Z80SetIRQPin		;@ Mr. Goemon
	ldr r2,=Z80SetIRQPin		;@ Green Beret
	ldr r3,=emuRAM
	bl k005849Reset0

	ldr r0,=BG_GFX+0x8000		;@ r0 = GBA/NDS BG tileset
	str r0,[koptr,#bgrGfxDest]
	ldr r0,=Gfx1Bg
	str r0,[koptr,#spriteRomBase]
	str r0,[koptr,#bgrRomBase]
	ldr r1,=vromBase0			;@ r1 = source
	ldr r1,[r1]
	mov r2,#0x14000
	bl convertTiles5849
	ldr r0,=BG_GFX+0x4000		;@ r0 = GBA/NDS BG tileset
	bl addBackgroundTiles

	ldr r0,[koptr,#bgrRomBase]	;@ Copy last gfx bank to next
	add r0,r0,#0x14000
	sub r1,r0,#0x04000
	mov r2,#0x04000
	bl memcpy

	ldr r0,=gGammaValue
	ldrb r0,[r0]
	bl paletteInit				;@ Do palette mapping
	bl paletteTxAll				;@ Transfer it

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
paletteInit:		;@ r0-r3 modified.
	.type paletteInit STT_FUNC
;@ Called by ui.c:  void paletteInit(u8 gammaVal);
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r9,lr}
	mov r1,r0					;@ Gamma value = 0 -> 4
	ldr r8,=promBase			;@ Proms
	ldr r8,[r8]
	mov r7,#0xE0
	ldr r6,=MAPPED_RGB
	mov r4,#32					;@ Green Beret bgr, r1=R, r2=G, r3=B
noMap:							;@ Map 00000000bbgggrrr  ->  0bbbbbgggggrrrrr
	ldrb r9,[r8],#1
	and r0,r9,#0xC0				;@ Blue ready
	bl gPrefix
	mov r5,r0

	and r0,r7,r9,lsl#2			;@ Green ready
	bl gPrefix
	orr r5,r0,r5,lsl#5

	and r0,r7,r9,lsl#5			;@ Red ready
	bl gPrefix
	orr r5,r0,r5,lsl#5

	strh r5,[r6],#2
	subs r4,r4,#1
	bne noMap

	ldmfd sp!,{r4-r9,lr}
	bx lr

;@----------------------------------------------------------------------------
gPrefix:
	orr r0,r0,r0,lsr#3
	orr r0,r0,r0,lsr#6
;@----------------------------------------------------------------------------
gammaConvert:	;@ Takes value in r0(0-0xFF), gamma in r1(0-4),returns new value in r0=0x1F
;@----------------------------------------------------------------------------
	rsb r2,r0,#0x100
	mul r3,r2,r2
	rsbs r2,r3,#0x10000
	rsb r3,r1,#4
	orr r0,r0,r0,lsl#8
	mul r2,r1,r2
	mla r0,r3,r0,r2
	mov r0,r0,lsr#13

	bx lr

;@----------------------------------------------------------------------------
paletteTxAll:				;@ Called from ui.c
	.type paletteTxAll STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r1,=promBase			;@ Proms
	ldr r1,[r1]
	add r1,r1,#32				;@ LUT
	ldr r2,=MAPPED_RGB
	ldr r0,=EMUPALBUFF+0x200	;@ Sprites first
	bl paletteTx0
	add r2,r2,#0x20
	ldr r0,=EMUPALBUFF
	bl paletteTx0
	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
paletteTx0:					;@ r0=dst, r1=source, r2=Palette
;@----------------------------------------------------------------------------
	mov r3,#256
palTx0Loop:
	ldrb r12,[r1],#1
	and r12,r12,#0xF
	mov r12,r12,lsl#1
	ldrh r12,[r2,r12]
	strh r12,[r0],#2
	subs r3,r3,#1
	bne palTx0Loop
	bx lr
;@----------------------------------------------------------------------------
k005849Reset0:			;@ r0=periodicIrqFunc, r1=frameIrqFunc, r2=frame2IrqFunc, r3=ram+LUTs
;@----------------------------------------------------------------------------
	ldr koptr,=k005849_0
	b k005849Reset

;@----------------------------------------------------------------------------
	.section .iwram, "ax", %progbits	;@ For the GBA
;@----------------------------------------------------------------------------
vblIrqHandler:
	.type vblIrqHandler STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r8,lr}
	bl vblSound1
	bl calculateFPS

	ldrb r0,gScaling
	cmp r0,#UNSCALED
	moveq r6,#0
	ldrne r6,=0x80000000 + ((GAME_HEIGHT-SCREEN_HEIGHT)*0x10000) / (SCREEN_HEIGHT-1)	;@ NDS 0x2B10 (was 0x2AAB)
	ldrbeq r4,yStart
	movne r4,#0
	add r4,r4,#0x10
	mov r7,r4,lsl#16
	orr r7,r7,#(GAME_WIDTH-SCREEN_WIDTH)/2

	ldr r0,gFlicker
	eors r0,r0,r0,lsl#31
	str r0,gFlicker
	addpl r6,r6,r6,lsl#16

	ldr r5,=SCROLLBUFF
	mov r0,r5

	ldr r1,=scrollTemp
	mov r12,#SCREEN_HEIGHT
scrolLoop2:
	ldr r2,[r1,r4,lsl#2]
	add r2,r2,r7
	mov r3,r2
	stmia r0!,{r2-r3}
	adds r6,r6,r6,lsl#16
	addcs r7,r7,#0x10000
	adc r4,r4,#1
	subs r12,r12,#1
	bne scrolLoop2


	mov r6,#REG_BASE
	strh r6,[r6,#REG_DMA0CNT_H]	;@ DMA0 stop

	add r0,r6,#REG_DMA0SAD
	mov r1,r5					;@ DMA0 src, scrolling:
	ldmia r1!,{r3-r4}			;@ Read
	add r2,r6,#REG_BG0HOFS		;@ DMA0 dst
	stmia r2,{r3-r4}			;@ Set 1st values manually, HBL is AFTER 1st line
	ldr r3,=0xA6600002			;@ noIRQ hblank 32bit repeat incsrc inc_reloaddst, 2 word
	stmia r0,{r1-r3}			;@ DMA0 go

	add r0,r6,#REG_DMA3SAD

	ldr r1,dmaOamBuffer			;@ DMA3 src, OAM transfer:
	mov r2,#OAM					;@ DMA3 dst
	mov r3,#0x84000000			;@ noIRQ 32bit incsrc incdst
	orr r3,r3,#48*2				;@ 48 sprites * 2 longwords
	stmia r0,{r1-r3}			;@ DMA3 go

	ldr r1,=EMUPALBUFF			;@ DMA3 src, Palette transfer:
	mov r2,#BG_PALETTE			;@ DMA3 dst
	mov r3,#0x84000000			;@ noIRQ 32bit incsrc incdst
	orr r3,r3,#0x100			;@ 256 words (1024 bytes)
	stmia r0,{r1-r3}			;@ DMA3 go

	ldr koptr,=k005849_0
	ldrb r2,[koptr,#sprBank]

	mov r0,#0x003B
	ldrb r1,gGfxMask
	bic r0,r0,r1
	tst r2,#0x80
	biceq r0,r0,#0x10
	strh r0,[r6,#REG_WININ]

	bl scanKeys
	bl vblSound2
	ldmfd sp!,{r4-r8,lr}
	bx lr


;@----------------------------------------------------------------------------
gFlicker:		.byte 1
				.space 2
gTwitch:		.byte 0

gScaling:		.byte SCALED
gGfxMask:		.byte 0
yStart:			.byte 0
				.byte 0
;@----------------------------------------------------------------------------
refreshGfx:					;@ Called from C.
	.type refreshGfx STT_FUNC
;@----------------------------------------------------------------------------
	adr koptr,k005849_0
;@----------------------------------------------------------------------------
endFrame:	;@ Called just before screen end (~line 240)	(r0-r2 safe to use)
;@----------------------------------------------------------------------------
	stmfd sp!,{r3,lr}

	ldr r0,=scrollTemp
	bl copyScrollValues
	mov r0,#BG_GFX
	bl convertTileMap5849
	ldr r0,tmpOamBuffer
	bl convertSprites5849
;@--------------------------

	ldr r0,dmaOamBuffer
	ldr r1,tmpOamBuffer
	str r0,tmpOamBuffer
	str r1,dmaOamBuffer

	mov r0,#1
	str r0,oamBufferReady

	ldr r0,=windowTop			;@ Load wTop, store in wTop+4.......load wTop+8, store in wTop+12
	ldmia r0,{r1-r3}			;@ Load with increment after
	stmib r0,{r1-r3}			;@ Store with increment before

	ldmfd sp!,{r3,lr}
	bx lr

;@----------------------------------------------------------------------------

tmpOamBuffer:		.long OAM_BUFFER1
dmaOamBuffer:		.long OAM_BUFFER2

oamBufferReady:		.long 0
emuPaletteReady:	.long 0

;@----------------------------------------------------------------------------
k005849_0R:					;@ I/O read, (0xE000-0xE044)
;@----------------------------------------------------------------------------
	cmp addy,#0xF800
	bpl memZ80R7
	mov r1,addy
	cmp addy,#0xE100
	bpl GreenBeretIO_R
	stmfd sp!,{addy,lr}
	adr koptr,k005849_0
	bl k005849_R
	ldmfd sp!,{addy,pc}

;@----------------------------------------------------------------------------
k005849Ram_0W:				;@ Ram write (0xC000-0xDFFF)
;@----------------------------------------------------------------------------
	bic r1,addy,#0xFE000
	ldr r2,k005849_0+gfxRAM
	strb r0,[r2,r1]
	mvn r1,r1,asr#11
	adr r2,k005849_0+gfxRAM
	strb r1,[r2,r1]
	bx lr

;@----------------------------------------------------------------------------
k005849_0W:					;@ I/O write  (0xE000-0xE044)
;@----------------------------------------------------------------------------
	mov r1,addy
	cmp addy,#0xE100
	bpl GreenBeretIO_W
	stmfd sp!,{addy,lr}
	adr koptr,k005849_0
	bl k005849_W
	ldmfd sp!,{addy,pc}

k005849_0:
	.space k005849Size
;@----------------------------------------------------------------------------
	.section .ewram, "ax"


gfxState:
adjustBlend:
	.long 0
windowTop:
	.long 0,0,0,0		;@ L/R scrolling in unscaled mode

	.byte 0
	.byte 0
	.byte 0,0

	.section .sbss
scrollTemp:
	.space 0x100*4
OAM_BUFFER1:
	.space 0x400
OAM_BUFFER2:
	.space 0x400
DMA0BUFF:
	.space 0x200
SCROLLBUFF:
	.space 0x400*2				;@ Scrollbuffer.
MAPPED_RGB:
	.space 0x400
EMUPALBUFF:
	.space 0x400
emuRAM:
	.space 0x2000
	.space SPRBLOCKCOUNT*4
	.space BGBLOCKCOUNT*4

	.align 9
Gfx1Bg:
	.space 0x18000

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
