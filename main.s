; GPT generated code as an example of what is required 
    
    #include <xc.inc>  
  
;============================================================  
; Reset vector  
;============================================================  
psect   resetVec, class=CODE, reloc=2, abs  
org     0x0000  
    goto    main  
  
;============================================================  
; Code  
;============================================================  
psect   code, class=CODE, reloc=2  
  
;------------------------------------------------------------  
; SPI2 init (per starter-slides style):  
; - clear CKE (clock edge "negative" in their wording)  
; - SSP2CON1 = SSPEN + CKP + SSPM1  (Master, Fosc/64, idle high)  
; - RD4 (SDO2) output, RD6 (SCK2) output  
;------------------------------------------------------------  
spi2_init:  
    ; Set clock edge "negative" (CKE=0)  
    bcf     SSP2STAT, 6, A        ; CKE = bit6  
  
    ; SSP2CON1: SSPEN(bit5)=1, CKP(bit4)=1, SSPM1(bit1)=1 => 0x32  
    movlw   0x32  
    movwf   SSP2CON1, A  
  
    ; Pin directions: RD4=SDO2 output, RD6=SCK2 output  
    bcf     TRISD, 4, A           ; RD4 output  
    bcf     TRISD, 6, A           ; RD6 output  
  
    ; Clear SPI2 interrupt flag (SSP2IF is PIR2 bit5)  
    bcf     PIR2, 5, A  
    return  
  
;------------------------------------------------------------  
; SPI2 transmit  
; Input: WREG = byte to send  
; Wait on SSP2IF (PIR2 bit5), then clear it.  
;------------------------------------------------------------  
spi2_tx:  
    movwf   SSP2BUF, A            ; start transfer  
  
wait_tx:  
    btfss   PIR2, 5, A            ; wait SSP2IF=1  
    bra     wait_tx  
    bcf     PIR2, 5, A            ; clear SSP2IF  
  
    ; (Recommended robustness: read buffer to clear BF)  
    movf    SSP2BUF, W, A  
  
    return  
  
;------------------------------------------------------------  
; Small delay (adjust as needed)  
;------------------------------------------------------------  
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
    call    spi2_init  
  
loop:  
    movlw   0xAA  
    call    spi2_tx  
    call    delay  
  
    bra     loop  