#include <xc.inc>

PSECT resetVec,class=CODE,delta=2
ORG 0x0000
    goto main


PSECT code,class=CODE,delta=2


; =========================
; SPI MASTER INIT (SSP2)
; =========================
SPI_MasterInit:

    ; RD4 (SDO2) output
    bcf     TRISD, 4

    ; RD6 (SCK2) output
    bcf     TRISD, 6

    ; Clear SPI module
    clrf    SSP2CON1

    ; Enable SPI
    bsf     SSP2CON1, 5     ; SSPEN

    return

SPI_MasterTransmit:

    movwf   SSP2BUF

Wait_Transmit:
    btfss   PIR3, 7         ; SSP2IF
    bra     Wait_Transmit

    bcf     PIR3, 7
    return


; =========================
; SIMPLE DELAY
; =========================
delay:

    movlw   0x01
    movwf   0x20

d1:
    movlw   0x01
    movwf   0x21

d2:
    decfsz  0x21, F
    bra     d2

    decfsz  0x20, F
    bra     d1

    return


; =========================
; MAIN
; =========================
main:

    call    SPI_MasterInit

loop:

    movlw   0xAA
    call    SPI_MasterTransmit
    call    delay

    movlw   0x55
    call    SPI_MasterTransmit
    call    delay

    movlw   0xF0
    call    SPI_MasterTransmit
    call    delay

    movlw   0x0F
    call    SPI_MasterTransmit
    call    delay

    bra     loop
