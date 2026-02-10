;===========================================================
; GPT generated code as a placeholder for our own
; Creates a triangle function on port C and leaves pin RD0 for WR on converter
;===========================================================
#include <xc.inc>

psect code, abs

org 0x0000
goto main

org 0x0100

count equ 0x20 ; DAC value
dir equ 0x21 ; 0 = up, 1 = down

;===========================================================
; MAIN
;===========================================================
main:
; ----------- I/O setup -----------
clrf TRISC, A ; PORTC all outputs (DAC data bus)
clrf LATC, A ; start data at 0

; PORTD: only RD0 is output (WR*). Keep other RD pins as inputs if you like.
bcf TRISD, 0, A ; RD0 output
bsf TRISD, 1, A ; RD1 input
bsf TRISD, 2, A
bsf TRISD, 3, A
bsf TRISD, 4, A
bsf TRISD, 5, A
bsf TRISD, 6, A
bsf TRISD, 7, A

bsf LATD, 0, A ; WR* HIGH

; ----------- init waveform state -----------
clrf count, A ; start at 0x00
clrf dir, A ; start going "up"

;===========================================================
; WAVEFORM LOOP
;===========================================================
wave_loop:
; Write current sample to DAC
movf count, W, A
call dac_write_w

; Delay controls output frequency
call delay

; Update count for triangle wave
movf dir, W, A
bz going_up ; if dir==0 -> going up

;-----------------------------
; going DOWN
;-----------------------------
going_down:
decf count, F, A
movf count, W, A
bnz wave_loop ; if not yet 0, keep going down

; hit 0x00 -> switch direction to UP
clrf dir, A
bra wave_loop

;-----------------------------
; going UP
;-----------------------------
going_up:
incf count, F, A
movf count, W, A
xorlw 0xFF ; W = (count XOR 0xFF)
bnz wave_loop ; if count != 0xFF keep going up

; hit 0xFF -> switch direction to DOWN
movlw 0x01
movwf dir, A
bra wave_loop

;===========================================================
; dac_write_w
; Input: WREG = byte to output
; Action:
; - Put W on LATC (data bus)
; - Pulse WR* low -> high (DAC latches on rising edge)
;===========================================================
dac_write_w:
movwf LATC, A ; present data on bus (PORTC outputs)

; WR* pulse (active low)
bcf LATD, 0, A ; WR* low: "writing"
nop
nop
bsf LATD, 0, A ; WR* rising edge: latches into DAC

return

;===========================================================
; delay
; Simple nested delay.
; Tweak the literals to change speed.
;===========================================================
delay:
movlw 0x20 ; outer loop count (increase = slower)
movwf 0x22, A

dly_outer:
movlw 0xFF ; inner loop count (increase = slower)
movwf 0x23, A

dly_inner:
decfsz 0x23, F, A
bra dly_inner

decfsz 0x22, F, A
bra dly_outer

return

end