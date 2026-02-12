	#include <xc.inc>

	psect code, abs

	org 0x0
	goto start

	org 0x100

	start:
		; PORTD all outputs
		clrf TRISD, A
		bsf LATD, 0, A ; RD0 low
		; PORTC all outputs
		clrf TRISC, A
		clrf LATC, A
		; Use file register 0x06 as counter
		clrf 0x06, A
	loop:
		; Output value
		movff 0x06, LATC
		bcf LATD, 0, A ; RD0 low
		nop
		nop
		bsf LATD, 0 ,A
		call delay
		incf 0x06, F, A
		bra loop

	delay:
		movlw 0xFF
		movwf 0x22, A
	d1:
		movlw 0xFF
		movwf 0x23, A
	d2:
		decfsz 0x23, F, A
		bra d2
		decfsz 0x22, F, A
		bra d1
	
	return

	end