#include <xc.inc>
psect code abs
        
ORG 0x000
goto main
 
delay_one_second:

    movlw 0x10
    movwf 0x20       ; outer loop = 16

outer_loop:
    movlw 0xD0
    movwf 0x21       ; middle loop = 208

middle_loop:
    movlw 0xD0
    movwf 0x22       ; inner loop = 208

inner_loop:
    decfsz 0x22, F
    bra inner_loop

    decfsz 0x21, F
    bra middle_loop

    decfsz 0x20, F
    bra outer_loop

    return


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
    btfss   PIR2, 5
    bra     Wait_Transmit
    bcf     PIR2, 5
return




main:
    call    SPI_MasterInit
loop:

    movlw   0xAA
    call    SPI_MasterTransmit
    call    delay_one_second
    
    movlw   0x55
    call    SPI_MasterTransmit
    call    delay_one_second

    bra     loop
