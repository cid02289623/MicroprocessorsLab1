; UPDATED
#include <xc.inc>

psect code, abs

main:
    org     0x0
    goto    setup          

    org     0x100

setup:
    bcf     CFGS            ; select program memory
    bsf     EEPGD           ; enable Flash access

    movlw   0xFF
    movwf   TRISD, A        ; PORTD as input (switches)
    clrf    TRISC, A        ; PORTC as output (LEDs)
    clrf    PORTC, A        ; clear LEDs

myTable:
    db  0x01
    db  0x02
    db  0x04
    db  0x08
    db  0x10
    db  0x20
    db  0x40
    db  0x80               ; LED pattern table

tableLen    EQU 8
counter     EQU 0x10

    align   2

start:
    movlw   low highword(myTable)
    movwf   TBLPTRU, A     ; table pointer upper
    movlw   high(myTable)
    movwf   TBLPTRH, A     ; table pointer high
    movlw   low(myTable)
    movwf   TBLPTRL, A     ; table pointer low

    movlw   tableLen
    movwf   counter, A     ; number of bytes to read

loop:
    tblrd*+                ; read byte from Flash to TABLAT
    movff   TABLAT, LATC   ; output to LEDs

    call    delay          ; visible delay
    
    
    
    decfsz  counter, A     ; next table entry
    bra     loop

    goto    start           ; restart pattern

delay:
    movf    PORTD, W, A    ; read switches
    movwf   0x11, A        ; outer delay count

d1:
    movlw   0xFF	   ; delay length
    movwf   0x12, A        ; inner delay count
  
d1a:
    movlw   0xAA	    ; delay length
    movwf   0x13, A   
d2:
    decfsz  0x13, A
    bra     d2
    decfsz  0x12, A
    bra     d1a
    decfsz  0x11, A
    bra     d1
    return

end main