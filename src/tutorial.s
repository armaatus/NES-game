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

; Import the states
.include "state/Player.s"
.include "state/Scroll.s"

; IRQ interupt => interupt request
.proc irq_handler 
  RTI ; return from interupt
.endproc

.import read_controller1, check_pause_game
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

  ; player logic
  JSR Player::update
  JSR Player::draw

  ; Scroll
  JSR BackgroundScroll::update
  
finish_nmi:
  ; Restore registers
  PLA
  TAY
  PLA
  TAX
  PLA

  RTI
.endproc

; Reset function
.import reset_handler

.export main
.proc main
  JSR BackgroundScroll::init

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
