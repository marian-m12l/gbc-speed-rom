INCLUDE "hardware.inc"
INCLUDE "ibmpc1.inc"			; nice ascii tileset from devrs.com
INCLUDE "macros.inc"

SECTION "vblank", ROM0 [$40]
	jp VBlank


SECTION "Timer interrupt", ROM0[$50]
TimerInterrupt:
    jp Timer


SECTION "Header", ROM0[$100]

EntryPoint:
	di
	jp Start

REPT $150 - $104
	; FIXME Header data?
	db 0
ENDR


SECTION "Game code", ROM0[$150]

Start:
	di
	; Initialize hardware
	xor a
	ldh [rNR52], a	; Disable sound
	xor a
	ldh [rIE], a	; All interrupts OFF
	ld sp, $FFFF	; Set stack pointer
	; Setup a slow timer interrupt --> counter is incremented @ 16 Hz in Normal Speed
	ld a, $00
	ldh [rTMA], a	; Timer is reset to this values after each overflow --> 0 for the slowest timer interrupts
	ld a, %00000100
	ldh [rTAC], a	; Enable timer @ CPU clock / 1024 (Normal Speed --> 4096 Hz / CGB Double Speed --> 8192 Hz)
	ld a, $05		; Timer and VBlank interrupts: 0x04 | 0x01
	ldh [rIE], a

	; Initialize WRAM variables
	InitWord wCounter1
	InitWord wCounter2
	InitWord wSubCounter
	InitWord wDoubleSpeed
	InitWord wJoypad
	InitWord wLatched


.waitvbl:
	ldh a, [rLY]	; Read current line
	cp 144
	jr c, .waitvbl	; Loop if line 144 not reached

	xor a	;A=0
	ldh [rLCDC], a 		; Disable display

	; Copy font tiles to VRAM
	ld bc, TilesFontDataEnd-TilesFontData
	ld de, TilesFontData
	ld hl, vFontTiles	; Copy to tiles 0x20-0x3f
.ldtFont:
	ld a, [de]
	ldi [hl], a
	ldi [hl], a		; Font tiles are 1bpp --> copy each byte twice to convert to 2bpp
	inc de
	dec bc
	; Check if bc is 0
	ld a, c
	or b 	; A=(C OR B)
	jr nz, .ldtFont		; Jump to the next byte

	; Display static texts once
	PrintText TextDataSpeed, TextDataSpeedEnd-TextDataSpeed, 0, 20, 30
	PrintText TextDataCounter1, TextDataCounter1End-TextDataCounter1, 5, 20, 50
	PrintText TextDataCounter2, TextDataCounter2End-TextDataCounter2, 10, 20, 70
	PrintText TextDataDoubleSpeed, TextDataDoubleSpeedEnd-TextDataDoubleSpeed, 15, 20, 90


	; Scroll and palettes
	xor a	;A=0
	ldh [rSCY], a	; Reset Scroll Y
	ldh [rSCX], a 	; Reset Scroll X
	ld a, %11100100 ; 11=Black 10=Dark grey 01=Light grey 00=White/Transparent
	ldh [rBGP], a 	; BG palette
	ldh [rOBP0], a 	; Sprite palette 0
	ldh [rOBP0], a 	; Sprute palette 1
	; CGB Palettes
		; BG
	ld a, %10000000
	ldh [rBGPI], a
	ld a, $ff
	ldh [rBGPD], a
	ldh [rBGPD], a
	ld a, $99
	ldh [rBGPD], a
	ldh [rBGPD], a
	ld a, $33
	ldh [rBGPD], a
	ldh [rBGPD], a
	ld a, $00
	ldh [rBGPD], a
	ldh [rBGPD], a
		; OBJ0
	ld a, %10000000
	ldh [rOBPI], a
	ld a, $ff
	ldh [rOBPD], a
	ldh [rOBPD], a
	ld a, $99
	ldh [rOBPD], a
	ldh [rOBPD], a
	ld a, $33
	ldh [rOBPD], a
	ldh [rOBPD], a
	ld a, $00
	ldh [rOBPD], a
	ldh [rOBPD], a
	ld a, %10010011 ; Screen on, Background on, tiles at $8000
	ldh [rLCDC], a

	ei

.waitforInt:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	di ; disable interrupts during joypad polling
	ld a, $20		; Read d-pad
	ld [rP1], a
	ld a, [rP1]		; Read multiple times to avoid bouncing
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	and $0f			; Move d-pad status to high nibble and store in register b
	swap a
	ld b, a
	ld a, $10		; Read buttons
	ld [rP1], a
	ld a, [rP1]		; Read multiple times to avoid bouncing
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	and $0f			; Combine with d-pad status
	or b
	cpl				; Complement: buttons pressed are ones
	ld [wJoypad], a
	and $01
	jr z, .noButtonPress	; Do nothing if no button is pressed
	; Check latch
	ld a, [wLatched]
	or a, a
	jr nz, .keepWaiting
	; Latch
	ld a, $01
	ld [wLatched], a
.enableDoubleSpeed:
	; Switch speed
	ld a, $00
	ldh [rIE], a
	ld a, $30
	ldh [rP1], a
	ld a, $01
	ldh [rKEY1], a
	stop
	nop
	nop
	ld a, $05		; Timer and VBlank interrupts: 0x04 | 0x01
	ldh [rIE], a
	ld a, [wDoubleSpeed]
	xor $01
	ld [wDoubleSpeed], a
	jr .keepWaiting
.noButtonPress:
	; Release latch
	ld a, $00
	ld [wLatched], a
.keepWaiting:
	ei ; enable interrupts when done
	jr .waitforInt


Lockup:
	nop
	nop
	nop
	nop
	jr Lockup
SECTION "Additional lockup", ROM0[$04FC] ;I included this just to be safe.
	jp Lockup


;VBlank interrupt
VBlank:
	push af
	push bc
	push de
	push hl

	; TODO Do computation in main loop on shadow OAM + Only transfer in VBlank interrupt?

	; Move "SPEED" text x position depending on counter value / timer speed
	ld a, [wCounter1]
	sra a
	add a, $40
	PrintText TextDataSpeed, TextDataSpeedEnd-TextDataSpeed, 0, a, 30

	PrintWordHex wCounter1, 20, 100, 50
	PrintWordHex wCounter2, 24, 100, 70
	PrintWordHex wDoubleSpeed, 28, 100, 90

	;PrintWordHex wJoypad, 32, 80, 120
	;PrintWordHex rKEY1, 36, 80, 140

	pop hl
	pop de
	pop bc
	pop af

	reti					;[4]


; Timer interrupt
Timer:
	; Increment counter 1
	IncrementWord wCounter1
	; Increment counter 2
	; In Normal Speed, increment counter 2 normally
	ld a, [wDoubleSpeed]
	bit 0, a
	jr z, .incrementCounter2
	; In Double Speed, increment only once every two interrupts to compensate the faster clock and keep increment rate stable
	ld a, [wSubCounter]
	xor $01
	ld [wSubCounter], a
	bit 0, a
	jr z, .incrementCounter2
	jr .done
.incrementCounter2:
	IncrementWord wCounter2
.done:
	reti



SECTION "TILES", ROM0[$1000]

TilesFontData:
	chr_IBMPC1	2,3
TilesFontDataEnd:


TextDataSpeed:
	db "SPEED"
TextDataSpeedEnd:

TextDataCounter1:
	db "CTR 1"
TextDataCounter1End:

TextDataCounter2:
	db "CTR 2"
TextDataCounter2End:

TextDataDoubleSpeed:
	db "DOUBL"
TextDataDoubleSpeedEnd:


SECTION "VRAM Tiles", VRAM[$8000]
vEmptyTile:
	ds 1 * 16
vTile1:
    ds 1 * 16
vUnusedTiles:
	ds 30 * 16
vFontTiles:
	ds 32 * 16


; Data in WRAM

SECTION	"Variables", WRAMX

wTextPosX:			DS 1
wCounter1:			DS 2
wCounter2:			DS 2
wSubCounter:		DS 2
wJoypad:			DS 2
wLatched:			DS 2
wDoubleSpeed:		DS 2
wText:				DS 4


BANK1_START EQU $4000
BANK1_END	EQU $8000