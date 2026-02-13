; GPT generated code as an example of what is required 
    
    #include <xc.inc>  

    psect abs  
    org     0x100  
    goto    main  

  

SPI_MsaterInit:  
    bcf     (SSPCON1_SSPEN_MASK) | (SSP2CON1_CK_MASK) | (SSP2CON1_SSPM1_MASK)
    movlw SSP2CON1, A  
  
    ; Pin directions: RD4=SDO2 output, RD6=SCK2 output  
    bcf     TRISD, PORTD_SD02_POSN, A           ; RD4 output  
    bcf     TRISD, PORTD_SCK2_POSN, A           ; RD6 output  
    return  
    
SPI_MasterTransmit: ;transmit data held in W
    movwf SSP2BUF, A  ; write data to output buffer
  
Wait_Transmit:
	btfss PIR2, 5
    sent
	bra Wait_Transmit
	bcf PIR2, 5
	return

delay:  
    movlw   0xFF  
    movwf   0x20, A  
d1: movlw   0xFF  
    movwf   0x21, A  
d2: decfsz  0x21, F, A  
    bra     d2  
    decfsz  0x20, F, A  
    bra     d1  
    return  
  
;------------------------------------------------------------  
; Main: send test patterns forever  
;------------------------------------------------------------  
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