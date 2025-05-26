.scope Camera
  CAMERA_SPEED = 2
  DEADZONE_X = 64  ; Pixels from center before camera moves
  DEADZONE_Y = 64
  
  .proc init
    ; Initialize camera at (0,0)
    LDA #$00
    STA CAMERA_X_LO
    STA CAMERA_X_HI
    STA CAMERA_Y_LO
    STA CAMERA_Y_HI
    
    ; Initialize player world position at center of first screen
    LDA #$80
    STA PLAYER_WORLD_X_LO
    LDA #$00
    STA PLAYER_WORLD_X_HI
    
    LDA #$78
    STA PLAYER_WORLD_Y_LO
    LDA #$00
    STA PLAYER_WORLD_Y_HI
    
    RTS
  .endproc
  
  .proc update
    ; Calculate where camera should be centered on player
    ; Target X = Player X - 128 (half screen)
    LDA PLAYER_WORLD_X_LO
    SEC
    SBC #$80
    STA $00  ; temp target lo
    LDA PLAYER_WORLD_X_HI
    SBC #$00
    STA $01  ; temp target hi
    
    ; Check if camera needs to move horizontally
    ; Calculate distance from current camera to target
    LDA $00
    SEC
    SBC CAMERA_X_LO
    STA $02  ; distance lo
    LDA $01
    SBC CAMERA_X_HI
    STA $03  ; distance hi
    
    ; Check if we're outside deadzone
    LDA $03
    BMI check_negative_x  ; if high byte negative, we're definitely outside deadzone
    BNE move_camera_right  ; if high byte positive non-zero, move right
    
    ; High byte is zero, check low byte
    LDA $02
    CMP #DEADZONE_X
    BCS move_camera_right
    JMP check_y_axis
    
  check_negative_x:
    ; Check if we need to move left
    LDA $02
    EOR #$FF
    CLC
    ADC #$01  ; negate to get absolute value
    CMP #DEADZONE_X
    BCS move_camera_left
    JMP check_y_axis
    
  move_camera_left:
    LDA CAMERA_X_LO
    SEC
    SBC #CAMERA_SPEED
    STA CAMERA_X_LO
    LDA CAMERA_X_HI
    SBC #$00
    STA CAMERA_X_HI
    JMP check_y_axis
    
  move_camera_right:
    LDA CAMERA_X_LO
    CLC
    ADC #CAMERA_SPEED
    STA CAMERA_X_LO
    LDA CAMERA_X_HI
    ADC #$00
    STA CAMERA_X_HI
    
  check_y_axis:
    ; Target Y = Player Y - 120 (half screen)
    LDA PLAYER_WORLD_Y_LO
    SEC
    SBC #$78
    STA $00
    LDA PLAYER_WORLD_Y_HI
    SBC #$00
    STA $01
    
    ; Calculate distance
    LDA $00
    SEC
    SBC CAMERA_Y_LO
    STA $02
    LDA $01
    SBC CAMERA_Y_HI
    STA $03
    
    ; Check deadzone
    LDA $03
    BMI check_negative_y
    BNE move_camera_down
    
    LDA $02
    CMP #DEADZONE_Y
    BCS move_camera_down
    JMP done
    
  check_negative_y:
    LDA $02
    EOR #$FF
    CLC
    ADC #$01
    CMP #DEADZONE_Y
    BCS move_camera_up
    JMP done
    
  move_camera_up:
    LDA CAMERA_Y_LO
    SEC
    SBC #CAMERA_SPEED
    STA CAMERA_Y_LO
    LDA CAMERA_Y_HI
    SBC #$00
    STA CAMERA_Y_HI
    JMP done
    
  move_camera_down:
    LDA CAMERA_Y_LO
    CLC
    ADC #CAMERA_SPEED
    STA CAMERA_Y_LO
    LDA CAMERA_Y_HI
    ADC #$00
    STA CAMERA_Y_HI
    
  done:
    RTS
  .endproc
  
  ; Set PPU scroll registers based on camera
  .proc set_scroll
    ; Calculate nametable select bits from camera position
    LDA CAMERA_X_HI
    AND #$01
    STA $00  ; X nametable bit
    
    LDA CAMERA_Y_HI
    AND #$01
    ASL A
    ORA $00
    
    ; Update PPUCTRL nametable bits
    ORA #%10010000  ; NMI on, sprites from pattern 0
    STA ppuctrl_settings
    
    RTS
  .endproc
.endscope
