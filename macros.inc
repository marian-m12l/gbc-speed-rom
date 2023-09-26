
; Params: variable address
MACRO InitWord
    ld de, \1
    xor a
    ld [de], a
    inc de
    ld [de], a
ENDM


; Params: variable address
MACRO IncrementWord
    ld de, \1		        ;[3]
    ld a, [de]				;[2]
    ld l, a					;[1]		; load low byte of variable value into l
    inc de					;[2]
    ld a, [de]				;[2]
    ld h, a					;[1]		; load high byte of variable value into h
    inc hl					;[2]
    ld de, \1       		;[3]
    ld a, l					;[1]
    ld [de], a				;[2]
    inc de					;[2]
    ld a, h					;[1]
    ld [de], a				;[2]
ENDM



; Params: text address, text length, sprite offset, x start position, y position
MACRO PrintText
    ld hl, _OAMRAM + (4 * \3) 	; HL = $FE00 + sprite offset
    ld b, \2
    ld a, \4
    ld [wTextPosX], a	; initial X position
    ld de, \1
.textLoop\@:
    ld [hl], \5 	; OAM sprite Y
    inc l
    ld a, [wTextPosX]
    ld [hl], a		; OAM sprite X
    add a, 10
    ld [wTextPosX], a   ; Increment X position
    inc l
    ld a, [de]
    ld [hl], a 		; OAM sprite tile = digit character
    inc de
    inc l
    ld [hl], $00 	; OAM sprite attributes = 0
    inc l
    dec b
    jr nz, .textLoop\@
ENDM


; Params: data address, sprite offset, x start position, y position
MACRO PrintWordHex
	; Display hex characters
	ld de, \1   ; de contains variable address
	ld a, [de]
	ld l, a		; load low byte of variable value into l
	inc de
	ld a, [de]
	ld h, a		; load high byte of variable value into h
	; hl contains variable VALUE

    ; To display the four nibbles:
	;   Right-shift 12 bits for 1st nibble
	;   Right-shift 8 bits and mask 4 bits for 2nd nibble
	;   Right-shift 4 bits and mask 4 bits for 3rd nibble
	;   Mask 4 bits for 4th nibble

	; 1st nibble
	ld a, h
	srl a
	srl a
	srl a
	srl a
	cp $0a
	jr c, .digit1\@
	add $07
.digit1\@
	add $30
	; a contains 1st nibble character
	ld [wText], a
	; 2nd nibble
	ld a, h
	ld b, $0f
	and b
	cp $0a
	jr c, .digit2\@
	add $07
.digit2\@
	add $30
	; a contains 2nd nibble character
	ld [wText+1], a
	; 3rd nibble
	ld a, l
	srl a
	srl a
	srl a
	srl a
	cp $0a
	jr c, .digit3\@
	add $07
.digit3\@
	add $30
	; a contains 3rd nibble character
	ld [wText+2], a
	; 4th nibble
	ld a, l
	ld b, $0f
	and b
	; a contains 4th nibble value ?
	; TODO add 0x30 for digits, 0x37 for letters
	cp $0a
	jr c, .digit4\@
	add $07
.digit4\@
	add $30
	; a contains 4th nibble character
	ld [wText+3], a
	; wText contains all hex characters --> update sprites / background tiles
	ld b, 4     ; FIXME Compute length? --> TextDataEnd-TextData
	ld a, \3
	ld [wTextPosX], a	; initial X position
	ld de, wText
	ld hl, _OAMRAM + (4 * \2) 	; HL=$FE00 + sprite offset
.textLoop\@:
	ld [hl], \4 	; OAM sprite Y
	inc l
	ld a, [wTextPosX]
	ld [hl], a		; OAM sprite X
	add a, 10
	ld [wTextPosX], a
	inc l
	ld a, [de]
	ld [hl], a 		; OAM sprite tile = hex character
	inc de
	inc l
	ld [hl], $00 	; OAM sprite attributes = 0
	inc l
	dec b
	jr nz, .textLoop\@
ENDM
