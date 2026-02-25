#include <xc.inc>

; ----- external modules -----
extrn   LCD_Setup, LCD_clear_display, LCD_first_line
extrn   LCD_Write_Char, LCD_delay_ms

extrn   ADC_Setup
extrn   ADC_Read_mV
extrn   LCD_display_ADC_mV

psect   code, abs
rst:    org     0x0000
        goto    start

psect   code
start:
        call    LCD_Setup
        call    LCD_clear_display
        call    ADC_Setup

main_loop:
        call    ADC_Read_mV

        call    LCD_first_line
        call    LCD_display_ADC_mV

        movlw   'm'
        call    LCD_Write_Char
        movlw   'V'
        call    LCD_Write_Char

        movlw   250
        call    LCD_delay_ms
        movlw   250
        call    LCD_delay_ms

        bra     main_loop

end