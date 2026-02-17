#include <xc.inc>

extrn   UART_Setup, UART_Transmit_Message
extrn   LCD_Setup, LCD_Write_PM_Message, LCD_first_line, LCD_second_line
extrn   LCD_clear_display, LCD_shift_left, LCD_shift_right
extrn   delay_seconds, LCD_delay_ms

psect   udata_acs
btn_last:   ds 1

; Program memory strings
psect   data

TopMsg:
    db  'H','A','L',' ','9','0','0','0',':'
TopMsg_l EQU 9
align 2

BottomMsg:
    db  'B','O','T','T','O','M',' ','T','E','X','T'
BottomMsg_l EQU 11
align 2

AltMsg:
    db  'P','R','E','S','S','E','D','!'
AltMsg_l EQU 8
align 2

psect   code, abs
rst:    org 0x0000
        goto    setup

setup:
        ; Program Flash read setup
        bcf     CFGS
        bsf     EEPGD

        call    UART_Setup
        call    LCD_Setup

        ; RD6 input (button)
        bsf     TRISD, 6, A

        clrf    btn_last, A

        goto    draw_not_pressed

draw_not_pressed:
        call    LCD_clear_display

        call    LCD_first_line
        movlw   low highword(TopMsg)
        movwf   TBLPTRU, A
        movlw   high(TopMsg)
        movwf   TBLPTRH, A
        movlw   low(TopMsg)
        movwf   TBLPTRL, A
        movlw   TopMsg_l
        call    LCD_Write_PM_Message

        call    LCD_second_line
        movlw   low highword(BottomMsg)
        movwf   TBLPTRU, A
        movlw   high(BottomMsg)
        movwf   TBLPTRH, A
        movlw   low(BottomMsg)
        movwf   TBLPTRL, A
        movlw   BottomMsg_l
        call    LCD_Write_PM_Message
	

        bra     main_loop

draw_pressed:
        call    LCD_clear_display
        call    LCD_second_line

        movlw   low highword(AltMsg)
        movwf   TBLPTRU, A
        movlw   high(AltMsg)
        movwf   TBLPTRH, A
        movlw   low(AltMsg)
        movwf   TBLPTRL, A
        movlw   AltMsg_l
        call    LCD_Write_PM_Message

        bra     main_loop

main_loop:
    btfss   PORTD, 6, A    
    bra     not_pressed     

pressed:
    call    LCD_clear_display
    call    LCD_second_line

    movlw   low highword(AltMsg)
    movwf   TBLPTRU, A
    movlw   high(AltMsg)
    movwf   TBLPTRH, A
    movlw   low(AltMsg)
    movwf   TBLPTRL, A
    movlw   AltMsg_l
    call    LCD_Write_PM_Message
    
    movlw   1
    call    delay_seconds

    bra     main_loop

not_pressed:
    call    LCD_clear_display

    ; Top line
    call    LCD_first_line
    movlw   low highword(TopMsg)
    movwf   TBLPTRU, A
    movlw   high(TopMsg)
    movwf   TBLPTRH, A
    movlw   low(TopMsg)
    movwf   TBLPTRL, A
    movlw   TopMsg_l
    call    LCD_Write_PM_Message

    ; Bottom line
    call    LCD_second_line
    movlw   low highword(BottomMsg)
    movwf   TBLPTRU, A
    movlw   high(BottomMsg)
    movwf   TBLPTRH, A
    movlw   low(BottomMsg)
    movwf   TBLPTRL, A
    movlw   BottomMsg_l
    call    LCD_Write_PM_Message
 
    movlw   1
    call    delay_seconds


    bra     main_loop


        end     rst