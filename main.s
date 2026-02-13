#include <xc.inc>
psect code abs
        
ORG 0x100
goto main

SPI_MasterInit:
    
    bcf CKE2
    
    movlw   (SSP2CON1_SSPEN_MASK) | (SSP2CON1_CKP_MASK) | (SSP2CON1_SSPM1_MASK)
    movwf   SSP2CON1, A
    
    bcf     TRISD, 4, A
    bcf     TRISD, 6, A
    return

SPI_MasterTransmit:
    movwf   SSP2BUF

Wait_Transmit:
    btfss   PIR2, 5         ; SSP2IF
    bra     Wait_Transmit
    bcf     PIR2, 5
    return

delay:

    movlw   0x10
    movwf   0x20

d1:
    movlw   0x10
    movwf   0x21

d2:
    decfsz  0x21, F
    bra     d2

    decfsz  0x20, F
    bra     d1

    return


main:
    call    SPI_MasterInit
loop:

    movlw   0xAA
    call    SPI_MasterTransmit
    call delay

    bra     loop
