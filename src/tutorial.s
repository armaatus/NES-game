.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
scroll: .res 1
ppuctrl_settings: .res 1
pad1: .res 1
game_state: .res 1
.exportzp player_x, player_y, pad1, game_state

.segment "CODE" ; Game logic code
.proc irq_handler ; IRQ interupt => interupt request
  RTI ; return from interupt
.endproc

.import read_controller1, check_pause_toggle
.proc nmi_handler ; nmi interupt => Non-Maskable Interupt => occurs when ppu start preparing the next frame of graphics
  ; Save the registers
  PHA
  TXA
  PHA
  TYA
  PHA

  ; DMA transfer
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  LDA #$00

  ; Read the controller input
  JSR read_controller1

  ; update tiles *after* DMA transfer
  JSR update_player
  JSR draw_player
  
  LDA scroll
  CMP #$00 ; did we scroll to the end of a nametable?
  BNE set_scroll_positions
  ; if yes,
  ; Update base nametable
  LDA ppuctrl_settings
  EOR #%00000010 ; flip bit 1 to its opposite
  STA ppuctrl_settings
  STA PPUCTRL
  LDA #240
  STA scroll

set_scroll_positions:
  LDA #$00 ; X scroll first
  STA PPUSCROLL
  DEC scroll
  LDA scroll ; then Y scroll
  STA PPUSCROLL
  JMP finish_nmi

finish_nmi:
  ; Restore registers
  PLA
  TAY
  PLA
  TAX
  PLA

  RTI
.endproc

.import reset_handler

.export main
.proc main
  LDA #239
  STA scroll

  ; Write a pallete
  LDX PPUSTATUS 
  LDX #$3f ; Load first byte for PPUADDR
  STX PPUADDR ; Set first byte for PPUADDR
  LDX #$00 ; Load second byte for PPUADDR => becomes $3f00, which is the address of the first color of the pallete
  STX PPUADDR ; Set second byte for PPUADDR

; Write the pallete data
load_palletes:
  LDA palletes,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palletes

.import draw_starfield
.import draw_objects

  LDX #$20
  JSR draw_starfield

  LDX #$28
  JSR draw_starfield

  JSR draw_objects

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA ppuctrl_settings
  STA PPUCTRL

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

.proc draw_player
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

.proc update_player
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

.segment "VECTORS" ; Code that should appear at the very end of the PRG-ROM block
.addr nmi_handler, reset_handler, irq_handler ; Converts the addresses when assembling

.segment "RODATA"
palletes:
.byte $0f, $12, $23, $27
.byte $0f, $2b, $3c, $39
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $2d, $10, $15
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

.segment "CHR" ; Represents the entire contents of the CHR-ROM
.incbin "../chr/scrolling.chr"
