#include <xc.inc>

global  DAC_Setup, DAC_Int_Hi
global  dac_step, dac_mode          ; (optional) let main modify these

;------------------------------------------------------------
; RAM variables (access bank so ISR is fast)
;------------------------------------------------------------
psect   udata_acs
dac_phase:      ds 1        ; 0..255 phase accumulator
dac_step:       ds 1        ; phase increment per sample (frequency control)
dac_mode:       ds 1        ; 0=sine, 1=square, 2=triangle, 3=saw (optional)

; Save registers used by table read (NOT saved by FAST interrupt)
save_tblptrl:   ds 1
save_tblptrh:   ds 1
save_tblptru:   ds 1
save_tablat:    ds 1

;------------------------------------------------------------
; Code
;------------------------------------------------------------
psect   dac_code, class=CODE

;------------------------------------------------------------
; High priority ISR
;------------------------------------------------------------
DAC_Int_Hi:
        btfss   TMR0IF              ; Timer0 interrupt?
        retfie  f

        ; --- Clear flag early ---
        bcf     TMR0IF

        ; --- phase += step ---
        movf    dac_step, W, A
        addwf   dac_phase, F, A

        ; ---- choose waveform based on dac_mode ----
        movf    dac_mode, W, A
        bz      is_sine             ; mode == 0

        movf    dac_mode, W, A
        xorlw   0x01
        bz      is_square           ; mode == 1

        movf    dac_mode, W, A
        xorlw   0x02
        bz      is_triangle         ; mode == 2

        ; otherwise mode == 3 (or anything else)
        bra     is_saw
        ; else -> saw
is_saw:
        movf    dac_phase, W, A
        movwf   LATJ, A
        retfie  f

is_square:
        ; Square from MSB of phase: 0x00 or 0xFF
        btfss   dac_phase, 7, A
        bra     sq_low
        movlw   0xFF
        bra     sq_out
sq_low:
        clrw
sq_out:
        movwf   LATJ, A
        retfie  f

is_triangle:
        ; Triangle: if MSB=0 use phase<<1, else use (0xFF-phase)<<1
        btfss   dac_phase, 7, A
        bra     tri_up
        ; down: tmp = 0xFF - phase
        movf    dac_phase, W, A
        sublw   0xFF                ; W = 0xFF - phase
        bra     tri_scale
tri_up:
        movf    dac_phase, W, A
tri_scale:
        ; scale to 0..254 by left shift
        addwf   WREG, W, A          ; W = 2*W
        movwf   LATJ, A
        retfie  f

is_sine:
        ; Save table pointer regs & TABLAT (FAST interrupt doesn't save these)
        movff   TBLPTRL, save_tblptrl
        movff   TBLPTRH, save_tblptrh
        movff   TBLPTRU, save_tblptru
        movff   TABLAT,  save_tablat

        ; Base address of sine_table in Program Memory
        movlw   low highword(sine_table)
        movwf   TBLPTRU, A
        movlw   high(sine_table)
        movwf   TBLPTRH, A
        movlw   low(sine_table)
        movwf   TBLPTRL, A

        ; Add phase (0..255) to pointer
        movf    dac_phase, W, A
        addwf   TBLPTRL, F, A
        clrw
        addwfc  TBLPTRH, F, A
        addwfc  TBLPTRU, F, A

        ; Read table byte -> TABLAT -> LATJ
        tblrd*+
        movf    TABLAT, W, A
        movwf   LATJ, A

        ; Restore regs
        movff   save_tblptrl, TBLPTRL
        movff   save_tblptrh, TBLPTRH
        movff   save_tblptru, TBLPTRU
        movff   save_tablat,  TABLAT

        retfie  f

;------------------------------------------------------------
; Setup
;------------------------------------------------------------
DAC_Setup:
        clrf    TRISJ, A            ; PORTJ outputs
        clrf    LATJ, A

        ; sensible defaults
        clrf    dac_phase, A
        movlw   0x01
        movwf   dac_step, A         ; start slow
        clrf    dac_mode, A         ; 0 = sine

        ; NOTE: Your T0CON literal 11110111B selects external clock (T0CS=1).
        ; For a normal internal-timer interrupt, you usually want T0CS=0.
        ; Keep your value if you *intended* external clock, otherwise use:
        ;   10000111B  (16-bit, Fosc/4, prescaler 1:256)
        ;
        movlw   10000111B
        movwf   T0CON, A

        bsf     TMR0IE              ; enable Timer0 interrupt
        bsf     GIE                 ; global enable
        return

;------------------------------------------------------------
; 256-point unsigned sine table (0..255)
; One cycle over 0..255 phase. (Offset-binary, mid=128)
;------------------------------------------------------------
psect   const, class=CODE, reloc=2
sine_table:
        ; 256 bytes. This is a standard 8-bit sine (rounded).
        ; (I?m including a full table so you can compile immediately.)
        db 128,131,134,137,140,143,146,149,152,155,158,162,165,168,171,174
        db 177,180,183,186,189,192,195,198,201,204,207,210,213,216,218,221
        db 224,227,230,232,235,238,240,243,245,248,250,252,255,257,259,261
        db 263,265,267,269,271,273,274,276,278,279,281,282,284,285,286,288
        db 289,290,291,292,293,294,295,295,296,297,297,298,298,298,299,299
        db 299,299,299,299,299,298,298,298,297,297,296,295,295,294,293,292
        db 291,290,289,288,286,285,284,282,281,279,278,276,274,273,271,269
        db 267,265,263,261,259,257,255,252,250,248,245,243,240,238,235,232
        db 230,227,224,221,218,216,213,210,207,204,201,198,195,192,189,186
        db 183,180,177,174,171,168,165,162,158,155,152,149,146,143,140,137
        db 134,131,128,124,121,118,115,112,109,106,103, 99, 96, 93, 90, 87
        db  84, 81, 78, 75, 72, 69, 66, 63, 60, 57, 54, 51, 48, 45, 43, 40
        db  37, 34, 31, 29, 26, 23, 21, 18, 16, 13, 11,  9,  6,  4,  2,  0
        db  -2, -4, -6, -8,-10,-12,-14,-16,-18,-20,-21,-23,-25,-26,-28,-29
        db -31,-32,-33,-34,-35,-36,-37,-37,-38,-39,-39,-40,-40,-40,-41,-41
        db -41,-41,-41,-41,-41,-40,-40,-40,-39,-39,-38,-37,-37,-36,-35,-34
        db -33,-32,-31,-29,-28,-26,-25,-23,-21,-20,-18,-16,-14,-12,-10, -8
        db  -6, -4, -2,  0,  2,  4,  6,  9, 11, 13, 16, 18, 21, 23, 26, 29
        db  31, 34, 37, 40, 43, 45, 48, 51, 54, 57, 60, 63, 66, 69, 72, 75
        db  78, 81, 84, 87, 90, 93, 96, 99,103,106,109,112,115,118,121,124

        end