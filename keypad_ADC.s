#include <xc.inc>

global  ADC_Setup, ADC_Read, ADC_GetResult12, ADC_Print_Dec4
extrn   LCD_Write_Char

psect   udata_acs
adc_valL:   ds 1
adc_valH:   ds 1
adc_digit:  ds 1
psect   adc_code, class=CODE

;-----------------------------------------
; ADC_Setup
; - RA0/AN0 as analog input
; - Vref+ = 4.096V (internal), Vref- = 0V
; - Right-justified result in ADRESH:ADRESL
;-----------------------------------------
ADC_Setup:
        bsf     TRISA, PORTA_RA0_POSN, A     ; RA0 input

        banksel ANCON0                        ; ANCON0 not in access RAM
        bsf     ANSEL0                        ; AN0 enabled as analog
        movlb   0                             ; restore BSR (good practice)

        movlw   0x01
        movwf   ADCON0, A                     ; select AN0 + ADC on

        movlw   0x00
        movwf   ADCON1, A                     ; 4.096V Vref+, 0V Vref-, negative input = Vss

        movlw   0xF6
        movwf   ADCON2, A                     ; right justified, Tad = Fosc/64, acquisition etc.
        return

;-----------------------------------------
; ADC_Read
; - start conversion (GO=1)
; - wait until complete (GO clears)
; - result now in ADRESH:ADRESL
;-----------------------------------------
ADC_Read:
        bsf     GO                            ; start conversion
adc_loop:
        btfsc   GO                            ; wait while GO still set
        bra     adc_loop
        return

;-----------------------------------------
; ADC_GetResult12
; - convenience: returns 12-bit result split:
;   W = low byte (ADRESL)
;   and leaves ADRESH unchanged
; (Useful if you want to pass low byte around)
;-----------------------------------------
ADC_GetResult12:
        movf    ADRESL, W, A
        return
;-----------------------------------------
; ADC_Print_Dec4
; Prints ADRESH:ADRESL as 4 digits 0000..4095
; Uses LCD_Write_Char (W = ASCII)
;-----------------------------------------
ADC_Print_Dec4:
        movlb   0                      ; keep BSR sane

        ; copy ADC result
        movff   ADRESL, adc_valL
        movff   ADRESH, adc_valH

        ; ---- thousands (1000 = 0x03E8) ----
        clrf    adc_digit, A
t_loop:
        movlw   0xE8
        subwf   adc_valL, F, A
        movlw   0x03
        subwfb  adc_valH, F, A
        bc      t_ok
        ; undo
        movlw   0xE8
        addwf   adc_valL, F, A
        movlw   0x03
        addwfc  adc_valH, F, A
        bra     t_done
t_ok:
        incf    adc_digit, F, A
        bra     t_loop
t_done:
        movf    adc_digit, W, A
        addlw   '0'
        call    LCD_Write_Char

        ; ---- hundreds (100 = 0x0064) ----
        clrf    adc_digit, A
h_loop:
        movlw   0x64
        subwf   adc_valL, F, A
        movlw   0x00
        subwfb  adc_valH, F, A
        bc      h_ok
        movlw   0x64
        addwf   adc_valL, F, A
        movlw   0x00
        addwfc  adc_valH, F, A
        bra     h_done
h_ok:
        incf    adc_digit, F, A
        bra     h_loop
h_done:
        movf    adc_digit, W, A
        addlw   '0'
        call    LCD_Write_Char

        ; ---- tens (10 = 0x000A) ----
        clrf    adc_digit, A
d_loop:
        movlw   0x0A
        subwf   adc_valL, F, A
        movlw   0x00
        subwfb  adc_valH, F, A
        bc      d_ok
        movlw   0x0A
        addwf   adc_valL, F, A
        movlw   0x00
        addwfc  adc_valH, F, A
        bra     d_done
d_ok:
        incf    adc_digit, F, A
        bra     d_loop
d_done:
        movf    adc_digit, W, A
        addlw   '0'
        call    LCD_Write_Char

        ; ---- ones (0..9 remaining in adc_valL) ----
        movf    adc_valL, W, A
        addlw   '0'
        call    LCD_Write_Char

        return
end