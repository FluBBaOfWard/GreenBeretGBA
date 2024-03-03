#ifdef __arm__

#include "Shared/gba_asm.h"
#include "Shared/EmuSettings.h"
#include "ARMZ80/ARMZ80mac.h"
#include "K005849/K005849.i"

	.global machineInit
	.global loadCart
	.global z80Mapper
	.global emuFlags
	.global romNum
	.global cartFlags
	.global romStart
	.global vromBase0
	.global promBase

	.global ROM_Space
	.global mainCpu
	.global testState



	.syntax unified
	.arm

	.section .rodata
	.align 2

rawRom:
ROM_Space:

// Code
	.incbin "gberet/577l03.10c"
	.incbin "gberet/577l02.8c"
	.incbin "gberet/577l01.7c"
// "Sprites"
	.incbin "gberet/577l06.5e"
	.incbin "gberet/577l05.4e"
	.incbin "gberet/577l08.4f"
	.incbin "gberet/577l04.3e"
// Tiles
	.incbin "gberet/577l07.3f"
// Proms
	.incbin "gberet/577h09.2f" // RGB Palette
	.incbin "gberet/577h10.5f" // Sprite Pal LUT
	.incbin "gberet/577h11.6f" // Character Pal LUT

/*
	.incbin "gberet/621d01.10c"
	.incbin "gberet/621d02.12c"
	.incbin "gberet/621d03.4d"
	.incbin "gberet/621d04.5d"
	.incbin "gberet/621a05.6d"
	.incbin "gberet/621a06.5f" // RGB Palette
	.incbin "gberet/621a07.6f" // Sprite Pal LUT
	.incbin "gberet/621a08.7f" // Character Pal LUT
*/
	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
machineInit: 	;@ Called from C
	.type   machineInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#0x0014				;@ 3/1 wait state
	ldr r1,=REG_WAITCNT
	strh r0,[r1]

	bl gfxInit
//	bl ioInit
	bl soundInit
//	bl cpuInit

	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
loadCart: 		;@ Called from C:  r0=rom number, r1=emuflags
	.type   loadCart STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	str r0,romNum
	str r1,emuFlags

//	ldr r7,=rawRom
	ldr r7,=ROM_Space
	cmp r0,#3
	str r7,romStart				;@ Set rom base
	add r0,r7,#0xC000			;@ 0xC000
	addeq r0,r0,#0x4000			;@ Mr. Goemon
	str r0,vromBase0			;@ Spr & bg
	add r0,r0,#0x14000
	str r0,promBase				;@ Colour prom

	bl doCpuMappingGreenBeret

	bl gfxReset
	bl ioReset
	bl soundReset
	bl cpuReset

	ldmfd sp!,{r4-r11,lr}
	bx lr

;@----------------------------------------------------------------------------
greenBeretMapping:						;@ Green Beret
	.long 0x00, memZ80R0, rom_W									;@ ROM
	.long 0x01, memZ80R1, rom_W									;@ ROM
	.long 0x02, memZ80R2, rom_W									;@ ROM
	.long 0x03, memZ80R3, rom_W									;@ ROM
	.long 0x04, memZ80R4, rom_W									;@ ROM
	.long 0x05, memZ80R5, rom_W									;@ ROM
	.long emuRAM, memZ80R6, k005849Ram_0W						;@ Graphic
	.long emptySpace, GreenBeretIO_R, GreenBeretIO_W			;@ IO

;@----------------------------------------------------------------------------
doCpuMappingGreenBeret:
;@----------------------------------------------------------------------------
	adr r2,greenBeretMapping
;@----------------------------------------------------------------------------
doZ80MainCpuMapping:
;@----------------------------------------------------------------------------
	ldr r0,=Z80OpTable
	ldr r1,=mainCpu
	ldr r1,[r1]
;@----------------------------------------------------------------------------
z80Mapper:		;@ Rom paging.. r0=cpuptr, r1=romBase, r2=mapping table.
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r8,lr}

	add r7,r0,#z80MemTbl
	add r8,r0,#z80ReadTbl
	add lr,r0,#z80WriteTbl

	mov r6,#8
z80MLoop:
	ldmia r2!,{r3-r5}
	cmp r3,#0x100
	addmi r3,r1,r3,lsl#13
	rsb r0,r6,#8
	sub r3,r3,r0,lsl#13

	str r3,[r7],#4
	str r4,[r8],#4
	str r5,[lr],#4
	subs r6,r6,#1
	bne z80MLoop
;@------------------------------------------
z80Flush:		;@ Update cpu_pc & lastbank
;@------------------------------------------
	reEncodePC
	ldmfd sp!,{r4-r8,lr}
	bx lr

;@----------------------------------------------------------------------------

romNum:
	.long 0						;@ RomNumber
romInfo:						;@ Keep emuflags/BGmirror together for savestate/loadstate
emuFlags:
	.byte 0						;@ EmuFlags      (label this so Gui.c can take a peek) see EmuSettings.h for bitfields
	.byte SCALED				;@ (display type)
	.byte 0,0					;@ (sprite follow val)
cartFlags:
	.byte 0 					;@ CartFlags
	.space 3

romStart:
mainCpu:
	.long 0
vromBase0:
	.long 0
promBase:
	.long 0

	.section .sbss
emptySpace:
	.space 0x2000
testState:
	.space 0x2048+0x34+0x48
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
