#include <xc.inc>

extrn   KeyPad_Setup, KeyPad_GetASCII, KeyPad_WaitRelease
extrn   UART_Setup, UART_Transmit_Byte

global  KeyPad_UART_Demo

psect   keypad_uart_code, class=CODE

KeyPad_UART_Demo:
        call    KeyPad_Setup
        call    UART_Setup

uart_loop:
        call    KeyPad_GetASCII     ; W = ASCII, or 0 if none
        bz      uart_loop

        call    UART_Transmit_Byte
        call    KeyPad_WaitRelease
        bra     uart_loop
