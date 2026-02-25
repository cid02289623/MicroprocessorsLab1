#include <xc.inc>

extrn   KeyPad_Setup, KeyPad_LCD_Service
extrn   LCD_Setup, LCD_clear_display, LCD_first_line
extrn   ADC_Setup, ADC_Read

psect   code, abs
rst:    org     0x0000
        goto    start

psect   code
start:
        call    LCD_Setup
        call    LCD_clear_display
        call    LCD_first_line

        clrf    LATD, A
        clrf    TRISD, A          ; PORTD all outputs (LEDs)

        call    KeyPad_Setup
        call    ADC_Setup

main_loop:
        call    ADC_Read
        movff   ADRESH, LATD      ; show top 8 bits on LEDs

        call    KeyPad_LCD_Service
        bra     main_loop