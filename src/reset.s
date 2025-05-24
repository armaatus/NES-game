.include "constants.inc"

.segment "ZEROPAGE"
.importzp player_x, player_y, game_state

.segment "CODE"
.import main
.export reset_handler
.proc reset_handler
  SEI ; Set interupt ignore bit. Anything that would trigger a interupt gets ignored
  CLD ; Clear Decimal mode bit. disabling binary coded decimal mode on 6502 => best practice because the NES cannot handle the mode anyway
  LDX #$40 ; this, and three next are just to disable sound interupts
  STX $4017 ; sound
  LDX #$FF ; sound
  TXS ; sound
  INX
  STX PPUCTRL 
  STX PPUMASK
  STX $4010
  BIT PPUSTATUS
vblankwait:
  BIT PPUSTATUS
  BPL vblankwait
    
    LDX #$00
    LDA #$FF
  clear_oam:
    STA $0200,X ; set sprite y-positions off the screen
    INX
    INX
    INX
    INX
    BNE clear_oam

vblankwait2:
  BIT PPUSTATUS 
  BPL vblankwait2

  ; Initialize zero-page values
  LDA #$80
  STA player_x
  LDA #$a0
  STA player_y
  LDA #STATEPLAYING
  STA game_state

  JMP main
.endproc
