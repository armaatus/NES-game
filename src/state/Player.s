.scope Player
  PLAYER_SPEED = 2
  
  .proc init
    JSR init_x
    JSR init_y
    RTS
  .endproc

  .proc init_x
    ; Player screen position X
    LDA #$80
    STA player_x
  
    ; Player world position X
    LDA #$80
    STA player_world_x_lo
    LDA #$00
    STA player_world_x_hi
    RTS
  .endproc

  .proc init_y
    ; Player screen position Y
    LDA #$a0
    STA player_y

    ; Player world position Y
    LDA #$78
    STA player_world_y_lo
    LDA #$00
    STA player_world_y_hi
    RTS
  .endproc

  .proc update
  check_left:
    LDA pad1
    AND #BTN_LEFT 
    BEQ check_right 
    
    ; Move player left in world space
    LDA player_world_x_lo
    SEC
    SBC #PLAYER_SPEED
    STA player_world_x_lo
    LDA player_world_x_hi
    SBC #$00
    STA player_world_x_hi
    
  check_right:
    LDA pad1
    AND #BTN_RIGHT
    BEQ check_up
    
    LDA player_world_x_lo
    CLC
    ADC #PLAYER_SPEED
    STA player_world_x_lo
    LDA player_world_x_hi
    ADC #$00
    STA player_world_x_hi
    
  check_up:
    LDA pad1
    AND #BTN_UP
    BEQ check_down
    
    LDA player_world_y_lo
    SEC
    SBC #PLAYER_SPEED
    STA player_world_y_lo
    LDA player_world_y_hi
    SBC #$00
    STA player_world_y_hi
    
  check_down:
    LDA pad1
    AND #BTN_DOWN
    BEQ done_checking
    
    LDA player_world_y_lo
    CLC
    ADC #PLAYER_SPEED
    STA player_world_y_lo
    LDA player_world_y_hi
    ADC #$00
    STA player_world_y_hi
    
  done_checking:
    RTS
  .endproc

  .proc draw
    ; Calculate screen position from world position
    ; Screen X = World X - Camera X
    LDA player_world_x_lo
    SEC
    SBC camera_x_lo
    STA player_x
    LDA player_world_x_hi
    SBC camera_x_hi
    ; If high byte is not zero, player is off screen
    BEQ x_on_screen
    JMP off_screen
    
  x_on_screen:
    ; Screen Y = World Y - Camera Y
    LDA player_world_y_lo
    SEC
    SBC camera_y_lo
    STA player_y
    LDA player_world_y_hi
    SBC camera_y_hi
    BEQ y_on_screen
    JMP off_screen
    
  y_on_screen:
    ; Draw player sprite
    ; write player tile numbers
    LDA #$05
    STA $0201
    LDA #$06
    STA $0205
    LDA #$07
    STA $0209
    LDA #$08
    STA $020d

    ; write player tile attributes
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
    
    RTS
    
  off_screen:
    ; Hide sprite off screen
    LDA #$FF
    STA $0200
    STA $0204
    STA $0208
    STA $020c
    RTS
  .endproc
.endscope
