#include <xc.inc>

; ========================
; exported
; ========================
global  LCD_Setup
global  LCD_Write_Message
global  LCD_Write_PM_Message
global  delay_seconds
global	LCD_delay_ms
global  LCD_clear_display
global  LCD_shift_right
global  LCD_shift_left
global  LCD_first_line
global  LCD_second_line
global  LCD_delay_ms
global  LCD_Write_Char
global  LCD_shift_right_crsr
global  LCD_shift_left_crsr
global  LCD_Send_Byte_D  

; ========================
; RAM (access bank)
; ========================
psect   udata_acs
LCD_cnt_l:               ds 1
LCD_cnt_h:               ds 1
LCD_cnt_ms:              ds 1
LCD_tmp:                 ds 1
LCD_counter:             ds 1
LCD_cnt_S:               ds 1
LCD_n_shift_right_ctn:   ds 1
LCD_n_shift_left_ctn:    ds 1

; Cursor state (0..15, row 0/1)
LCD_col:                 ds 1
LCD_row:                 ds 1

; ========================
; LCD pin definitions on PORTB
; ========================
LCD_E   EQU 5
LCD_RS  EQU 4

psect   lcd_code, class=CODE

; ------------------------------------------------------------
; LCD_Setup
; ------------------------------------------------------------
LCD_Setup:
    clrf    LATB, A
    movlw   11000000B          ; RB0:5 outputs (LCD data+control)
    movwf   TRISB, A

    movlw   40
    call    LCD_delay_ms       ; 40 ms startup

    movlw   00110000B          ; Function set (init)
    call    LCD_Send_Byte_I
    movlw   10
    call    LCD_delay_x4us

    movlw   00101000B          ; 4-bit, 2-line, 5x8
    call    LCD_Send_Byte_I
    movlw   10
    call    LCD_delay_x4us

    movlw   00101000B          ; repeat
    call    LCD_Send_Byte_I
    movlw   10
    call    LCD_delay_x4us

    movlw   00001111B          ; display on, cursor on, blink on
    call    LCD_Send_Byte_I
    movlw   10
    call    LCD_delay_x4us

    movlw   00000001B          ; clear display
    call    LCD_Send_Byte_I
    movlw   2
    call    LCD_delay_ms

    movlw   00000110B          ; entry mode inc, no shift
    call    LCD_Send_Byte_I
    movlw   10
    call    LCD_delay_x4us

    ; init cursor state
    clrf    LCD_col, A
    clrf    LCD_row, A
    return

; ------------------------------------------------------------
; Cursor positioning
; ------------------------------------------------------------
LCD_first_line:
    clrf    LCD_row, A
    clrf    LCD_col, A
    movlw   0x80
    call    LCD_Send_Byte_I
    movlw   10
    call    LCD_delay_x4us
    return

LCD_second_line:
    movlw   1
    movwf   LCD_row, A
    clrf    LCD_col, A
    movlw   0xC0
    call    LCD_Send_Byte_I
    movlw   10
    call    LCD_delay_x4us
    return

; ------------------------------------------------------------
; Write from RAM: FSR2 points to message, W = length
; ------------------------------------------------------------
LCD_Write_Message:
    movwf   LCD_counter, A
LCD_Loop_message:
    movf    POSTINC2, W, A
    call    LCD_Send_Byte_D
    decfsz  LCD_counter, A
    bra     LCD_Loop_message
    return

; ------------------------------------------------------------
; Write from PROGRAM MEMORY: TBLPTR points to message, W = length
; ------------------------------------------------------------
LCD_Write_PM_Message:
    movwf   LCD_counter, A
LCD_PM_Loop:
    tblrd*+                     ; PM -> TABLAT, TBLPTR++
    movf    TABLAT, W, A
    call    LCD_Send_Byte_D
    decfsz  LCD_counter, A
    bra     LCD_PM_Loop
    return

; ------------------------------------------------------------
; Low-level send routines
; ------------------------------------------------------------
LCD_Send_Byte_I:                ; W -> instruction reg
    movwf   LCD_tmp, A
    swapf   LCD_tmp, W, A
    andlw   0x0F
    movwf   LATB, A
    bcf     LATB, LCD_RS, A
    call    LCD_Enable

    movf    LCD_tmp, W, A
    andlw   0x0F
    movwf   LATB, A
    bcf     LATB, LCD_RS, A
    call    LCD_Enable
    return

LCD_Send_Byte_D:                ; W -> data reg
    movwf   LCD_tmp, A
    swapf   LCD_tmp, W, A
    andlw   0x0F
    movwf   LATB, A
    bsf     LATB, LCD_RS, A
    call    LCD_Enable

    movf    LCD_tmp, W, A
    andlw   0x0F
    movwf   LATB, A
    bsf     LATB, LCD_RS, A
    call    LCD_Enable

    movlw   10                  ; ~40us
    call    LCD_delay_x4us
    return

LCD_Enable:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    bsf     LATB, LCD_E, A
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    bcf     LATB, LCD_E, A
    return

; ------------------------------------------------------------
; Delays
; ------------------------------------------------------------
LCD_delay_ms:                   ; W = ms
    movwf   LCD_cnt_ms, A
lcdlp2:
    movlw   250                 ; ~1ms
    call    LCD_delay_x4us
    decfsz  LCD_cnt_ms, A
    bra     lcdlp2
    return

LCD_delay_x4us:                 ; W = 4us chunks
    movwf   LCD_cnt_l, A
    swapf   LCD_cnt_l, F, A
    movlw   0x0F
    andwf   LCD_cnt_l, W, A
    movwf   LCD_cnt_h, A
    movlw   0xF0
    andwf   LCD_cnt_l, F, A
    call    LCD_delay
    return

LCD_delay:
    movlw   0x00
lcdlp1:
    decf    LCD_cnt_l, F, A
    subwfb  LCD_cnt_h, F, A
    bc      lcdlp1
    return

; ------------------------------------------------------------
; Seconds delay (rough): W = seconds
; ------------------------------------------------------------
delay_seconds:
    movwf   LCD_cnt_S, A
    movlw   4
    mulwf   LCD_cnt_S
    movf    PRODL, W, A
    movwf   LCD_cnt_S, A

    movlw   250
    movwf   LCD_cnt_ms, A

delay_outer:
    movf    LCD_cnt_ms, W, A
    call    LCD_delay_ms
    decfsz  LCD_cnt_S, A
    bra     delay_outer
    return

; ------------------------------------------------------------
; Clear display
; ------------------------------------------------------------
LCD_clear_display:
    movlw   00000001B
    call    LCD_Send_Byte_I
    movlw   2
    call    LCD_delay_ms
    clrf    LCD_col, A
    clrf    LCD_row, A
    return

; ------------------------------------------------------------
; LCD_Write_Char
; - Writes char in W
; - Advances cursor
; - Line1 end -> Line2 start
; - Line2 end -> Line1 start
; ------------------------------------------------------------
LCD_Write_Char:
    call    LCD_Send_Byte_D

    movlw   15
    cpfseq  LCD_col, A
    bra     _inc_col

    ; col == 15
    movf    LCD_row, F, A
    bz      _wrap_to_line2

_wrap_to_line1:
    call    LCD_first_line
    return

_wrap_to_line2:
    call    LCD_second_line
    return

_inc_col:
    incf    LCD_col, F, A
    return

; ------------------------------------------------------------
; Shift display
; ------------------------------------------------------------
LCD_shift_left:                 ; W shifts
    movwf   LCD_n_shift_left_ctn, A
LCD_shift_left_inner:
    movlw   0x18
    call    LCD_Send_Byte_I
    movlw   10
    call    LCD_delay_x4us
    decfsz  LCD_n_shift_left_ctn, A
    bra     LCD_shift_left_inner
    return

LCD_shift_right:                ; W shifts
    movwf   LCD_n_shift_right_ctn, A
LCD_shift_right_inner:
    movlw   0x1C
    call    LCD_Send_Byte_I
    movlw   10
    call    LCD_delay_x4us
    decfsz  LCD_n_shift_right_ctn, A
    bra     LCD_shift_right_inner
    return

; ------------------------------------------------------------
; Cursor left with wrap
; ------------------------------------------------------------
LCD_shift_left_crsr:
    movf    LCD_col, F, A
    bnz     _l_normal

    movlw   15
    movwf   LCD_col, A

    movf    LCD_row, F, A
    bz      _l_from_line1

_l_from_line2:
    clrf    LCD_row, A
    movlw   0x8F
    call    LCD_Send_Byte_I
    movlw   10
    call    LCD_delay_x4us
    return

_l_from_line1:
    movlw   1
    movwf   LCD_row, A
    movlw   0xCF
    call    LCD_Send_Byte_I
    movlw   10
    call    LCD_delay_x4us
    return

_l_normal:
    movlw   0x10
    call    LCD_Send_Byte_I
    movlw   10
    call    LCD_delay_x4us
    decf    LCD_col, F, A
    return

; ------------------------------------------------------------
; Cursor right with wrap
; ------------------------------------------------------------
LCD_shift_right_crsr:
    movlw   15
    cpfseq  LCD_col, A
    bra     _r_normal

    clrf    LCD_col, A

    movf    LCD_row, F, A
    bz      _r_from_line1

_r_from_line2:
    clrf    LCD_row, A
    movlw   0x80
    call    LCD_Send_Byte_I
    movlw   10
    call    LCD_delay_x4us
    return

_r_from_line1:
    movlw   1
    movwf   LCD_row, A
    movlw   0xC0
    call    LCD_Send_Byte_I
    movlw   10
    call    LCD_delay_x4us
    return

_r_normal:
    movlw   0x14
    call    LCD_Send_Byte_I
    movlw   10
    call    LCD_delay_x4us
    incf    LCD_col, F, A
    return

end