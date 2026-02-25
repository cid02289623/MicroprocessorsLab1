;========================
; main.s
;========================
#include <xc.inc>

extrn   KeyPad_Setup, KeyPad_LCD_Service
extrn   LCD_Setup, LCD_clear_display, LCD_first_line, LCD_second_line
extrn   LCD_Write_Char
extrn   ADC_Setup, ADC_Read, ADC_Print_Dec4

psect   code, abs
rst:    org     0x0000
        goto    start

psect   code
start:
        call    LCD_Setup
        call    LCD_clear_display
        call    KeyPad_Setup
        call    ADC_Setup

main_loop:
        ; ----- KEYPAD OUTPUT: FORCE LINE 1 -----
        call    LCD_first_line           ; always reset cursor before keypad prints
        call    KeyPad_LCD_Service

        ; ----- ADC OUTPUT: FORCE LINE 2 -----
        call    ADC_Read
        call    LCD_second_line          ; always print ADC at start of line 2
        call    ADC_Print_Dec4

        ; wipe the rest of line 2 so old keypad junk disappears
        movlw   ' '
        call    LCD_Write_Char
        movlw   ' '
        call    LCD_Write_Char
        movlw   ' '
        call    LCD_Write_Char
        movlw   ' '
        call    LCD_Write_Char
        movlw   ' '
        call    LCD_Write_Char
        movlw   ' '
        call    LCD_Write_Char
        movlw   ' '
        call    LCD_Write_Char
        movlw   ' '
        call    LCD_Write_Char
        movlw   ' '
        call    LCD_Write_Char
        movlw   ' '
        call    LCD_Write_Char
        movlw   ' '
        call    LCD_Write_Char
        movlw   ' '
        call    LCD_Write_Char

        bra     main_loop

        end     rst