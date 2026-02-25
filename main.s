;========================
; main.s  (fast Timer0 for small step widths)
;========================
#include <xc.inc>

extrn   DAC_Setup, DAC_Int_Hi
extrn   dac_step, dac_mode

psect   code, abs
rst:    org     0x0000
        goto    start

; High-priority interrupt vector
        org     0x0008
        goto    DAC_Int_Hi

psect   code
start:
        ; Set up ports/vars/interrupt enable (your module does this)
        call    DAC_Setup

        ; -------------------------------
        ; OVERRIDE TIMER0 TO RUN FASTER:
        ; 8-bit mode, internal clock (Fosc/4), no prescaler
        ; This makes each DAC step much shorter.
        ; -------------------------------

        ; Stop Timer0 while reconfiguring
        bcf     T0CON, 7, A          ; TMR0ON = 0

        ; T0CON bits: [7]=TMR0ON [6]=T08BIT [5]=T0CS [4]=T0SE [3]=PSA [2:0]=T0PS
        ; We want: TMR0ON=0, T08BIT=1, T0CS=0, T0SE=0, PSA=1, T0PS=000 (don't care when PSA=1)
        movlw   01001000B
        movwf   T0CON, A

        ; (Optional) clear timer register
        clrf    TMR0L, A

        ; Start Timer0
        bsf     T0CON, 7, A          ; TMR0ON = 1

        ; -------------------------------
        ; Choose waveform + speed knobs
        ; -------------------------------
        movlw   0x00
        movwf   dac_mode, A          ; 0=sine, 1=square, 2=triangle, 3=saw

        movlw   0x01
        movwf   dac_step, A          ; bigger = faster output freq (0xFF is -1, same speed as 0x01)

main_loop:
        goto    main_loop

        end     rst