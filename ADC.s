;========================
; ADC.s
;========================
#include <xc.inc>

; ========================
; exported
; ========================
global  ADC_Setup
global  ADC_ReadCounts
global  LCD_display_ADC_mV

global  ADC_CountsTo_mV_16x16
global  ADC_CountsTo_mV_8x24

global  Mul16x16_U
global  Mul8x24_U
    
global	ADC_Read_mV


; needs LCD_Write_Char (W = ASCII)
extrn   LCD_Write_Char

; ========================
; constants
; ========================
; Nominal reference in mV for conversion.
; If your actual reference is different, adjust this.
VREF_MV_L   equ 0x00        ; 4096 = 0x1000
VREF_MV_H   equ 0x10

; ========================
; RAM (access bank)
; ========================
psect   udata_acs
; shared value buffer (what LCD_display_ADC_mv prints)
adc_rawL:   ds 1
adc_rawH:   ds 1
adc_digit:  ds 1

; scratch for 8x24 method (first partial product)
prod0:      ds 1
prod1:      ds 1
prod2:      ds 1
prod3:      ds 1

; temps for multiply helpers
mul_AL:     ds 1
mul_AH:     ds 1
mul_BL:     ds 1
mul_BH:     ds 1
mul_R0:     ds 1
mul_R1:     ds 1
mul_R2:     ds 1
mul_R3:     ds 1

mul_X:      ds 1
mul_Y0:     ds 1
mul_Y1:     ds 1
mul_Y2:     ds 1

psect   adc_code, class=CODE

;-----------------------------------------
; ADC_Setup
; - RA0/AN0 as analog input
; - Channel AN0, ADC on
; - Reference + formatting + timing
;-----------------------------------------
ADC_Setup:
        ; RA0 input
        bsf     TRISA, PORTA_RA0_POSN, A

        ; AN0 analog (disable digital input buffer)
        banksel ANCON0
        bsf     ANSEL0
        movlb   0

        ; ADCON0: select AN0 + ADC on
        movlw   0x01
        movwf   ADCON0, A

        ; ADCON1: reference selection
        ; If your lab really uses the 4.096V reference option, keep this.
        ; If you use VDD/VSS instead, use 0x00.
        movlw   0x30
        movwf   ADCON1, A

        ; ADCON2: right justify + timing
        movlw   0xF6
        movwf   ADCON2, A

        return

;-----------------------------------------
; ADC_ReadCounts
; - start conversion (GO=1)
; - wait until complete (GO clears)
;-----------------------------------------
ADC_ReadCounts:
        bsf     GO
_wait_go:
        btfsc   GO
        bra     _wait_go
        return


;======================================================================
; ADC_CountsTo_mV_16x16
; Computes: mV = counts * VREF_MV / 4095
; Input:  ADRESH:ADRESL (counts)
; Output: adc_rawH:adc_rawL = mV (integer, truncated)
; Uses:   Mul16x16_U + DIV32_BY_0x0FFF_TO16
;======================================================================
ADC_CountsTo_mV_16x16:
        ; A = counts (16-bit, though only 12-bit used)
        movff   ADRESL, mul_AL
        movff   ADRESH, mul_AH

        ; B = VREF_MV (16-bit)
        movlw   VREF_MV_L
        movwf   mul_BL, A
        movlw   VREF_MV_H
        movwf   mul_BH, A

        ; product -> mul_R3:mul_R0
        call    Mul16x16_U

        ; divide by 4095 -> adc_rawH:adc_rawL
        call    DIV32_BY_0x0FFF_TO16
        return


;======================================================================
; ADC_CountsTo_mV_8x24
; Same result, but uses the 8x24 helper.
;
; We multiply counts (AH:AL) by a 24-bit Vref constant:
;   Vref24 = 0x00:VREF_MV_H:VREF_MV_L   (here 0x001000 for 4096)
;
; product = (AL*Vref24) + ((AH*Vref24) << 8)
;======================================================================
ADC_CountsTo_mV_8x24:
        ; Y = Vref (24-bit) = 0x00:VREF_MV_H:VREF_MV_L
        movlw   VREF_MV_L
        movwf   mul_Y0, A
        movlw   VREF_MV_H
        movwf   mul_Y1, A
        clrf    mul_Y2, A

        ; ---- partial0 = AL * Y ----
        movff   ADRESL, mul_X
        call    Mul8x24_U                 ; mul_R = partial0

        movff   mul_R0, prod0
        movff   mul_R1, prod1
        movff   mul_R2, prod2
        movff   mul_R3, prod3

        ; ---- partial1 = AH * Y ----
        movff   ADRESH, mul_X
        call    Mul8x24_U                 ; mul_R = partial1

        ; prod += (partial1 << 8)
        movf    mul_R0, W, A
        addwf   prod1, F, A
        movf    mul_R1, W, A
        addwfc  prod2, F, A
        movf    mul_R2, W, A
        addwfc  prod3, F, A
        ; mul_R3 would go into a 5th byte; not needed for our range

        ; move combined product back into mul_R for division
        movff   prod0, mul_R0
        movff   prod1, mul_R1
        movff   prod2, mul_R2
        movff   prod3, mul_R3

        call    DIV32_BY_0x0FFF_TO16
        return


;======================================================================
; LCD_display_ADC_mV
; Prints adc_rawH:adc_rawL as 4 digits 0000..9999
; (Repeated subtraction via helper.)
;======================================================================
LCD_display_ADC_mV:
        ; thousands (1000 = 0x03E8)
        movlw   0xE8
        movwf   PRODL, A
        movlw   0x03
        movwf   PRODH, A
        call    ADC_ExtractDigit16
        movf    adc_digit, W, A
        addlw   '0'
        call    LCD_Write_Char

        ; hundreds (100 = 0x0064)
        movlw   0x64
        movwf   PRODL, A
        clrf    PRODH, A
        call    ADC_ExtractDigit16
        movf    adc_digit, W, A
        addlw   '0'
        call    LCD_Write_Char

        ; tens (10 = 0x000A)
        movlw   0x0A
        movwf   PRODL, A
        clrf    PRODH, A
        call    ADC_ExtractDigit16
        movf    adc_digit, W, A
        addlw   '0'
        call    LCD_Write_Char

        ; ones
        movf    adc_rawL, W, A
        addlw   '0'
        call    LCD_Write_Char

        return


;-----------------------------------------
; ADC_ExtractDigit16 (private)
;
; Inputs:
;   adc_rawH:adc_rawL  unsigned remainder
;   PRODH:PRODL        unsigned constant
; Output:
;   adc_digit          count (0..9)
;   adc_rawH:adc_rawL  updated remainder
;-----------------------------------------
ADC_ExtractDigit16:
        clrf    adc_digit, A

_aed_loop:
        movf    PRODL, W, A
        subwf   adc_rawL, F, A
        movf    PRODH, W, A
        subwfb  adc_rawH, F, A

        bc      _aed_ok

        ; undo and finish
        movf    PRODL, W, A
        addwf   adc_rawL, F, A
        movf    PRODH, W, A
        addwfc  adc_rawH, F, A
        return

_aed_ok:
        incf    adc_digit, F, A
        bra     _aed_loop


;======================================================================
; DIV32_BY_0x0FFF_TO16  (private)
; Dividend: mul_R3:mul_R0
; Divisor : 4095 = 0x00000FFF
; Quotient: adc_rawH:adc_rawL
;
; Clear, reliable integer division by repeated subtraction.
;======================================================================
DIV32_BY_0x0FFF_TO16:
        clrf    adc_rawL, A
        clrf    adc_rawH, A

_div_loop:
        ; subtract 0x00000FFF from mul_R (32-bit)
        movlw   0xFF
        subwf   mul_R0, F, A
        movlw   0x0F
        subwfb  mul_R1, F, A
        clrf    WREG, A
        subwfb  mul_R2, F, A
        clrf    WREG, A
        subwfb  mul_R3, F, A

        bc      _div_ok           ; no borrow -> subtraction valid

        ; borrow -> undo subtraction and finish
        movlw   0xFF
        addwf   mul_R0, F, A
        movlw   0x0F
        addwfc  mul_R1, F, A
        clrf    WREG, A
        addwfc  mul_R2, F, A
        clrf    WREG, A
        addwfc  mul_R3, F, A
        return

_div_ok:
        ; quotient++
        incf    adc_rawL, F, A
        btfsc   STATUS, 2, A      ; Z set when adc_rawL rolled over to 0
        incf    adc_rawH, F, A
        bra     _div_loop


;======================================================================
; Multiply helpers (unsigned)
;======================================================================

;-----------------------------------------
; Mul16x16_U
; Inputs:
;   mul_AH:mul_AL  (16-bit A)
;   mul_BH:mul_BL  (16-bit B)
; Output:
;   mul_R3:mul_R0  (32-bit product)
;-----------------------------------------
Mul16x16_U:
        ; R = AL*BL
        movf    mul_AL, W, A
        mulwf   mul_BL, A
        movff   PRODL, mul_R0
        movff   PRODH, mul_R1
        clrf    mul_R2, A
        clrf    mul_R3, A

        ; add (AL*BH) << 8
        movf    mul_AL, W, A
        mulwf   mul_BH, A
        movf    PRODL, W, A
        addwf   mul_R1, F, A
        movf    PRODH, W, A
        addwfc  mul_R2, F, A
        clrf    WREG, A
        addwfc  mul_R3, F, A

        ; add (AH*BL) << 8
        movf    mul_AH, W, A
        mulwf   mul_BL, A
        movf    PRODL, W, A
        addwf   mul_R1, F, A
        movf    PRODH, W, A
        addwfc  mul_R2, F, A
        clrf    WREG, A
        addwfc  mul_R3, F, A

        ; add (AH*BH) << 16
        movf    mul_AH, W, A
        mulwf   mul_BH, A
        movf    PRODL, W, A
        addwf   mul_R2, F, A
        movf    PRODH, W, A
        addwfc  mul_R3, F, A

        return


;-----------------------------------------
; Mul8x24_U
; Inputs:
;   mul_X           (8-bit)
;   mul_Y2:mul_Y0   (24-bit)
; Output:
;   mul_R3:mul_R0   (32-bit)
;-----------------------------------------
Mul8x24_U:
        clrf    mul_R0, A
        clrf    mul_R1, A
        clrf    mul_R2, A
        clrf    mul_R3, A

        ; term0: X*Y0
        movf    mul_X, W, A
        mulwf   mul_Y0, A
        movf    PRODL, W, A
        addwf   mul_R0, F, A
        movf    PRODH, W, A
        addwfc  mul_R1, F, A
        clrf    WREG, A
        addwfc  mul_R2, F, A
        addwfc  mul_R3, F, A

        ; term1: (X*Y1)<<8
        movf    mul_X, W, A
        mulwf   mul_Y1, A
        movf    PRODL, W, A
        addwf   mul_R1, F, A
        movf    PRODH, W, A
        addwfc  mul_R2, F, A
        clrf    WREG, A
        addwfc  mul_R3, F, A

        ; term2: (X*Y2)<<16
        movf    mul_X, W, A
        mulwf   mul_Y2, A
        movf    PRODL, W, A
        addwf   mul_R2, F, A
        movf    PRODH, W, A
        addwfc  mul_R3, F, A

        return
    ; WRAPPER
    ADC_Read_mV:
	call    ADC_ReadCounts
	call    ADC_CountsTo_mV_16x16

	return

end