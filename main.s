#include <xc.inc>

extrn   KeyPad_Setup, KeyPad_GetValue

psect   code, abs
rst:    org 0x0000
        goto start

psect   code
start:
        clrf    TRISD, A
        clrf    LATD, A

        call    KeyPad_Setup

loop:
        call    KeyPad_GetValue     ; W = 0..15 or 0xFF
        movwf   LATD, A
        bra     loop

        end rst