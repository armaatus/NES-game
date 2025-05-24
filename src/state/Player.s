.scope Player
  .proc update
  check_left:
    LDA pad1
    AND #BTN_LEFT 
    BEQ check_right 
    LDA player_x
    CLC
    SBC #$02
    STA player_x
  check_right:
    LDA pad1
    AND #BTN_RIGHT
    BEQ check_up
    LDA player_x
    CLC
    ADC #$02
    STA player_x
  check_up:
    LDA pad1
    AND #BTN_UP
    BEQ check_down
    LDA player_y
    CLC
    SBC #$02
    STA player_y
  check_down:
    LDA pad1
    AND #BTN_DOWN
    BEQ done_checking
    LDA player_y
    CLC
    ADC #$02
    STA player_y
  done_checking:
    RTS
  .endproc

  .proc draw
    ; write player ship tile numbers
    LDA #$05
    STA $0201
    LDA #$06
    STA $0205
    LDA #$07
    STA $0209
    LDA #$08
    STA $020d

    ; write player ship tile attributes
    ; use palette 0
    LDA #$00
    STA $0202
    STA $0206
    STA $020a
    STA $020e

    ; store tile locations
    ; top left tile:
    LDA player_y
    STA $0200
    LDA player_x
    STA $0203

    ; top right tile (x + 8):
    LDA player_y
    STA $0204
    LDA player_x
    CLC
    ADC #$08
    STA $0207

    ; bottom left tile (y + 8):
    LDA player_y
    CLC
    ADC #$08
    STA $0208
    LDA player_x
    STA $020b

    ; bottom right tile (x + 8, y + 8)
    LDA player_y
    CLC
    ADC #$08
    STA $020c
    LDA player_x
    CLC
    ADC #$08
    STA $020f

    ; return to where the subroutine was called
    RTS
  .endproc
.endscope
