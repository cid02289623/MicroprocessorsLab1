#include <xc.inc>

extrn   KeyPad_Setup, KeyPad_GetASCII, KeyPad_WaitRelease
extrn   LCD_Setup, LCD_Write_Char

global  KeyPad_LCD_Demo

psect   keypad_lcd_code, class=CODE

KeyPad_LCD_Demo:
        call    KeyPad_Setup
        call    LCD_Setup

lcd_loop:
        call    KeyPad_GetASCII     ; W = ASCII, or 0 if none
        bz      lcd_loop

        call    LCD_Write_Char      ; print one char
        call    KeyPad_WaitRelease  ; prevent repeat while held
        bra     lcd_loop
