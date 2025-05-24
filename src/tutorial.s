.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
; Player position
player_x: .res 1
player_y: .res 1

; Scroll information
scroll: .res 1
ppuctrl_settings: .res 1

; Input
pad1: .res 1
pressed_buttons: .res 1
released_buttons: .res 1
last_frame_pad1: .res 1

; Game state
game_state: .res 1
sleeping: .res 1

NUM_ENEMIES = 5

; enemy object pool
enemy_x_pos: .res NUM_ENEMIES
enemy_y_pos: .res NUM_ENEMIES
enemy_x_vels: .res NUM_ENEMIES
enemy_y_vels: .res NUM_ENEMIES
enemy_flags: .res NUM_ENEMIES
current_enemy: .res 1
current_enemy_type: .res 1

; timer for spawning enemies
enemy_timer: .res 1

; player bullet pool
bullet_xs: .res 3
bullet_ys: .res 3

; export all of this
.exportzp enemy_x_pos, enemy_y_pos
.exportzp enemy_x_vels, enemy_y_vels
.exportzp enemy_flags

.exportzp player_x, player_y, game_state
.exportzp game_state
.exportzp pad1, pressed_buttons, released_buttons, last_frame_pad1

.segment "CODE" ; Game logic code

; Import the states
.include "state/Player.s"
.include "state/Scroll.s"
.include "state/Enemy.s"

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

  ; set PPUCTRL
  LDA ppuctrl_settings
  STA PPUCTRL

  ; set the scroll values
  LDA #$00 ; X scroll first
  STA PPUSCROLL
  LDA scroll ; then Y scroll
  STA PPUSCROLL
  
  ; all done
  LDA #$00
  STA sleeping

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
  JSR Enemy::init
  JSR BackgroundScroll::init
  LDA #$00
  STA last_frame_pad1

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

mainloop:
  ; Read the controller input
  JSR read_controller1

  ; Check pausing and unpausing of the game
  JSR check_pause_game
  LDA game_state
  CMP #STATEPLAYING 
  BNE draw_sprites

  JSR Player::update
  JSR Enemy::process

  ; Scroll
  JSR BackgroundScroll::update

draw_sprites:
  JSR Player::draw

  ; Draw all enemies
  LDA #$00
  STA current_enemy
enemy_drawing:
  JSR Enemy::draw
  INC current_enemy
  LDA current_enemy
  CMP #NUM_ENEMIES
  BNE enemy_drawing

  ; Store pad1 to previous pad1
  LDA pad1
  STA last_frame_pad1

INC sleeping
sleep:
  LDA sleeping
  BNE sleep

  JMP mainloop
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

enemy_top_lefts:
.byte $09, $0d
enemy_top_rights:
.byte $0b, $0e
enemy_bottom_lefts:
.byte $0a, $0f
enemy_bottom_rights:
.byte $0c, $10

enemy_palettes:
.byte $01, $02

.segment "CHR" ; Represents the entire contents of the CHR-ROM
.incbin "../chr/objectpools.chr"
