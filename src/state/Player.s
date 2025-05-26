.scope Player
  PLAYER_SPEED = 2
  
  .proc update
  check_left:
    LDA pad1
    AND #BTN_LEFT 
    BEQ check_right 
    
    ; Move player left in world space
    LDA PLAYER_WORLD_X_LO
    SEC
    SBC #PLAYER_SPEED
    STA PLAYER_WORLD_X_LO
    LDA PLAYER_WORLD_X_HI
    SBC #$00
    STA PLAYER_WORLD_X_HI
    
  check_right:
    LDA pad1
    AND #BTN_RIGHT
    BEQ check_up
    
    LDA PLAYER_WORLD_X_LO
    CLC
    ADC #PLAYER_SPEED
    STA PLAYER_WORLD_X_LO
    LDA PLAYER_WORLD_X_HI
    ADC #$00
    STA PLAYER_WORLD_X_HI
    
  check_up:
    LDA pad1
    AND #BTN_UP
    BEQ check_down
    
    LDA PLAYER_WORLD_Y_LO
    SEC
    SBC #PLAYER_SPEED
    STA PLAYER_WORLD_Y_LO
    LDA PLAYER_WORLD_Y_HI
    SBC #$00
    STA PLAYER_WORLD_Y_HI
    
  check_down:
    LDA pad1
    AND #BTN_DOWN
    BEQ done_checking
    
    LDA PLAYER_WORLD_Y_LO
    CLC
    ADC #PLAYER_SPEED
    STA PLAYER_WORLD_Y_LO
    LDA PLAYER_WORLD_Y_HI
    ADC #$00
    STA PLAYER_WORLD_Y_HI
    
  done_checking:
    RTS
  .endproc

  .proc draw
    ; Calculate screen position from world position
    ; Screen X = World X - Camera X
    LDA PLAYER_WORLD_X_LO
    SEC
    SBC CAMERA_X_LO
    STA player_x
    LDA PLAYER_WORLD_X_HI
    SBC CAMERA_X_HI
    ; If high byte is not zero, player is off screen
    BEQ x_on_screen
    JMP off_screen
    
  x_on_screen:
    ; Screen Y = World Y - Camera Y
    LDA PLAYER_WORLD_Y_LO
    SEC
    SBC CAMERA_Y_LO
    STA player_y
    LDA PLAYER_WORLD_Y_HI
    SBC CAMERA_Y_HI
    BEQ y_on_screen
    JMP off_screen
    
  y_on_screen:
    ; Draw player sprite
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
