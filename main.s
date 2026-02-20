;========================
; main.s
;========================
#include <xc.inc>

extrn   KeyPad_Setup, KeyPad_LCD_Service
extrn   LCD_Setup, LCD_clear_display, LCD_first_line

psect   code, abs
rst:    org     0x0000
        goto    start

psect   code
start:
        call    LCD_Setup
        call    LCD_clear_display
        call    LCD_first_line
        call    KeyPad_Setup

main_loop:
        call    KeyPad_LCD_Service
        bra     main_loop

        end     rst
