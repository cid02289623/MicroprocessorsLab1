#include <xc.inc>

global  KeyPad_Setup, KeyPad_ReadColumns
global  KeyPad_GetValue
    
psect   udata_acs
column_pressed: ds 1
keypad_value: ds   1

psect   keypad_code, class=CODE

   
KeyPad_Setup:
        ; pull-ups on for PORTE
        movlb   0x0F
        bsf     REPU
        movlb   0x00

        ; RE0-3 inputs, RE4-7 outputs
        movlw   0x0F
        movwf   TRISE, A

        ; rows idle high
        movlw   0xF0
        movwf   LATE, A

        return



KeyPad_ReadColumns:
	; reads 0-3 to see what column is pressed
	; if no column presed return 0-3 as high
	; returns low bit on column pressed from 0-3
        movf    PORTE, W, A
        andlw   0x0F
        return

; ------------------------------------------------------------
; KeyPad_GetValue
; Returns in W:
;   0..15  = key index in binary
;   0xFF   = no key
;
; ------------------------------------------------------------
KeyPad_GetValue:

        ; ---- row 0: RE4 low ----
        movlw   0xF0
        movwf   LATE, A
        bcf     LATE, 4, A
        nop
        nop
        call    KeyPad_ReadColumns
        movwf   column_pressed, A
        movlw   0x0F
        cpfseq  column_pressed, A
        bra     row0_pressed

        ; ---- row 1: RE5 low ----
        movlw   0xF0
        movwf   LATE, A
        bcf     LATE, 5, A
        nop
        nop
        call    KeyPad_ReadColumns
        movwf   column_pressed, A
        movlw   0x0F
        cpfseq  column_pressed, A
        bra     row1_pressed

        ; ---- row 2: RE6 low ----
        movlw   0xF0
        movwf   LATE, A
        bcf     LATE, 6, A
        nop
        nop
        call    KeyPad_ReadColumns
        movwf   column_pressed, A
        movlw   0x0F
        cpfseq  column_pressed, A
        bra     row2_pressed

        ; ---- row 3: RE7 low ----
        movlw   0xF0
        movwf   LATE, A
        bcf     LATE, 7, A
        nop
        nop
        call    KeyPad_ReadColumns
        movwf   column_pressed, A
        movlw   0x0F
        cpfseq  column_pressed, A
        bra     row3_pressed

        ; none pressed
        movlw   0xFF
        return


; each row starts at 0, 4, 8, 12
	
row0_pressed:
        movlw   0
        bra     decode_col

row1_pressed:
        movlw   4
        bra     decode_col

row2_pressed:
        movlw   8
        bra     decode_col

row3_pressed:
        movlw   12
        bra	decode_col


decode_col:
        ; column_pressed holds values D0-D3
	; btfss checks bit position in second argument and skips if 1
	; adds on the extra 1 and cheks gain

	movwf	keypad_value, A
        btfss   column_pressed, 0, A
        return
        addlw   1
        
	movwf	keypad_value, A
	btfss   column_pressed, 1, A
        return
        addlw   1
        
	movwf	keypad_value, A
	btfss   column_pressed, 2, A
	return
        addlw   1
	
	movwf	keypad_value, A
	return