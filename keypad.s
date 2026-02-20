#include <xc.inc>

global  KeyPad_Setup, KeyPad_ReadColumns
global  KeyPad_GetValue
global  KeyPad_Read
global  KeyPad_LCD_Service

psect   udata_acs
column_pressed: ds 1
keypad_value:   ds 1
key_char:       ds 1        ; used by LCD service routine

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
        movf    PORTE, W, A
        andlw   0x0F
        return


; ------------------------------------------------------------
; KeyPad_GetValue
; Returns:
;   0..15  = key index
;   0xFF   = no key
; ------------------------------------------------------------
KeyPad_GetValue:

        ; ---- row 0 ----
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

        ; ---- row 1 ----
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

        ; ---- row 2 ----
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

        ; ---- row 3 ----
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

        movlw   0xFF
        return


row0_pressed:  movlw   0   ; base index
                bra     decode_col
row1_pressed:  movlw   4
                bra     decode_col
row2_pressed:  movlw   8
                bra     decode_col
row3_pressed:  movlw   12
                bra     decode_col


decode_col:
        btfsc   column_pressed, 0, A
        bra     col1
        return

col1:   addlw   1
        btfsc   column_pressed, 1, A
        bra     col2
        return

col2:   addlw   1
        btfsc   column_pressed, 2, A
        bra     col3
        return

col3:   addlw   1
        return


; ------------------------------------------------------------
; Convert key index → ASCII
; ------------------------------------------------------------
KeyPad_Read:
        call    KeyPad_GetValue
        movwf   keypad_value, A

        movlw   0xFF
        cpfseq  keypad_value, A
        bra     kp0
        retlw   0

kp0:    movlw   0x00
        cpfseq  keypad_value, A
        bra     kp1
        retlw   '1'
kp1:    movlw   0x01
        cpfseq  keypad_value, A
        bra     kp2
        retlw   '2'
kp2:    movlw   0x02
        cpfseq  keypad_value, A
        bra     kp3
        retlw   '3'
kp3:    movlw   0x03
        cpfseq  keypad_value, A
        bra     kp4
        retlw   'F'
kp4:    movlw   0x04
        cpfseq  keypad_value, A
        bra     kp5
        retlw   '4'
kp5:    movlw   0x05
        cpfseq  keypad_value, A
        bra     kp6
        retlw   '5'
kp6:    movlw   0x06
        cpfseq  keypad_value, A
        bra     kp7
        retlw   '6'
kp7:    movlw   0x07
        cpfseq  keypad_value, A
        bra     kp8
        retlw   'E'
kp8:    movlw   0x08
        cpfseq  keypad_value, A
        bra     kp9
        retlw   '7'
kp9:    movlw   0x09
        cpfseq  keypad_value, A
        bra     kpA
        retlw   '8'
kpA:    movlw   0x0A
        cpfseq  keypad_value, A
        bra     kpB
        retlw   '9'
kpB:    movlw   0x0B
        cpfseq  keypad_value, A
        bra     kpC
        retlw   'D'
kpC:    movlw   0x0C
        cpfseq  keypad_value, A
        bra     kpD
        retlw   'A'
kpD:    movlw   0x0D
        cpfseq  keypad_value, A
        bra     kpE
        retlw   '0'
kpE:    movlw   0x0E
        cpfseq  keypad_value, A
        bra     kpF
        retlw   'B'
kpF:    movlw   0x0F
        cpfseq  keypad_value, A
        bra     kp_unknown
        retlw   'C'

kp_unknown:
        retlw   0


; ============================================================
; KeyPad_LCD_Service
; ============================================================

extrn   LCD_first_line, LCD_second_line
extrn   LCD_shift_right_crsr, LCD_shift_left_crsr
extrn   LCD_clear_display, LCD_Write_Char
extrn   LCD_delay_ms

KeyPad_LCD_Service:
        call    KeyPad_Read
        movwf   key_char, A
        movf    key_char, W, A
        bz      svc_done

        movlw   20
        call    LCD_delay_ms

        call    KeyPad_Read
        movwf   key_char, A
        movf    key_char, W, A
        bz      svc_done

        movlw   'C'
        cpfseq  key_char, A
        bra     svc_not_clear
        call    LCD_clear_display
        call    LCD_first_line
        bra     svc_wait

svc_not_clear:
        movlw   'A'
        cpfseq  key_char, A
        bra     svc_not_left
        call    LCD_shift_left_crsr
        bra     svc_wait

svc_not_left:
        movlw   'B'
        cpfseq  key_char, A
        bra     svc_not_right
        call    LCD_shift_right_crsr
        bra     svc_wait

svc_not_right:
        movlw   'F'
        cpfseq  key_char, A
        bra     svc_not_first
        call    LCD_first_line
        bra     svc_wait

svc_not_first:
        movlw   'E'
        cpfseq  key_char, A
        bra     svc_not_second
        call    LCD_second_line
        bra     svc_wait

svc_not_second:
        movlw   'D'
        cpfseq  key_char, A
        bra     svc_not_delete
        call    LCD_shift_left_crsr
        movlw   ' '
        call    LCD_Write_Char
        call    LCD_shift_left_crsr
        bra     svc_wait

svc_not_delete:
        movf    key_char, W, A
        call    LCD_Write_Char

svc_wait:
        call    KeyPad_Read
        movwf   key_char, A
        movf    key_char, W, A
        bnz     svc_wait

        movlw   20
        call    LCD_delay_ms

svc_done:
        return
