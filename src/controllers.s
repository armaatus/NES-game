.include "constants.inc"

.segment "ZEROPAGE"
.importzp pad1, pressed_buttons, released_buttons, last_frame_pad1
.importzp game_state

.segment "CODE"
.export read_controller1
.proc read_controller1
  PHP
  PHA
  TXA
  PHA

  LDA #$01
  STA CONTROLLER1
  LDA #$00
  STA CONTROLLER1

  ; Initialize pad1
  LDA #%00000001
  STA pad1

get_buttons:
  LDA CONTROLLER1 ; Read next button's state
  LSR A           ; Shift button state right, into carry flag
  ROL pad1        ; Rotate button state from carry flag
                  ; onto right side of pad1
                  ; and leftmost 0 of pad1 into carry flag
  BCC get_buttons ; Continue until original "1" is in carry flag

  ; newly pressed buttons: not held last frame, and held now
  lda last_frame_pad1
  eor #%11111111
  and pad1
  sta pressed_buttons

  ; newly released buttons: not held now, and held last frame
  lda pad1
  eor #%11111111
  and last_frame_pad1
  sta released_buttons

  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.export check_pause_game
.proc check_pause_game
  LDA pressed_buttons
  AND #BTN_START
  BEQ done_checking
  LDA game_state
  EOR #$01
  STA game_state

done_checking:
  RTS
.endproc
