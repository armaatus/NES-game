.scope Camera
  DEADZONE_X = 64  ; Pixels from center before camera moves
  DEADZONE_Y = 64
  
  .proc init
    ; Initialize camera at (0,0)
    LDA #$00
    STA camera_x_lo
    STA camera_x_hi
    STA camera_y_lo
    STA camera_y_hi

    RTS
  .endproc
  
  .proc update
    ; Calculate where camera should be centered on player
    ; Target X = Player X - 128 (half screen)
    LDA player_world_x_lo
    SEC
    SBC #$80
    STA $00  ; temp target lo
    LDA player_world_x_hi
    SBC #$00
    STA $01  ; temp target hi
    
    ; Check if camera needs to move horizontally
    ; Calculate distance from current camera to target
    LDA $00
    SEC
    SBC camera_x_lo
    STA $02  ; distance lo
    LDA $01
    SBC camera_x_hi
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
    ; Get absolute value of player's X velocity
    LDA velocity_x
    BPL @positive_vel_x
    EOR #$FF
    CLC
    ADC #$01
  @positive_vel_x:
    ; Move camera left by player's speed
    STA $04  ; temp store speed
    LDA camera_x_lo
    SEC
    SBC $04
    STA camera_x_lo
    LDA camera_x_hi
    SBC #$00
    STA camera_x_hi
    JMP check_y_axis
    
  move_camera_right:
    ; Get absolute value of player's X velocity
    LDA velocity_x
    BPL @positive_vel_x2
    EOR #$FF
    CLC
    ADC #$01
  @positive_vel_x2:
    ; Move camera right by player's speed
    STA $04  ; temp store speed
    LDA camera_x_lo
    CLC
    ADC $04
    STA camera_x_lo
    LDA camera_x_hi
    ADC #$00
    STA camera_x_hi
    
  check_y_axis:
    ; Target Y = Player Y - 120 (half screen)
    LDA player_world_y_lo
    SEC
    SBC #$78
    STA $00
    LDA player_world_y_hi
    SBC #$00
    STA $01
    
    ; Calculate distance
    LDA $00
    SEC
    SBC camera_y_lo
    STA $02
    LDA $01
    SBC camera_y_hi
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
    ; Get absolute value of player's Y velocity
    LDA velocity_y
    BPL @positive_vel_y
    EOR #$FF
    CLC
    ADC #$01
  @positive_vel_y:
    ; Move camera up by player's speed
    STA $04  ; temp store speed
    LDA camera_y_lo
    SEC
    SBC $04
    STA camera_y_lo
    LDA camera_y_hi
    SBC #$00
    STA camera_y_hi
    JMP done
    
  move_camera_down:
    ; Get absolute value of player's Y velocity
    LDA velocity_y
    BPL @positive_vel_y2
    EOR #$FF
    CLC
    ADC #$01
  @positive_vel_y2:
    ; Move camera down by player's speed
    STA $04  ; temp store speed
    LDA camera_y_lo
    CLC
    ADC $04
    STA camera_y_lo
    LDA camera_y_hi
    ADC #$00
    STA camera_y_hi
    
  done:
    RTS
  .endproc
  
  ; Set PPU scroll registers based on camera
  .proc set_scroll
    ; Calculate nametable select bits from camera position
    LDA camera_x_hi
    AND #$01
    STA $00  ; X nametable bit
    
    LDA camera_y_hi
    AND #$01
    ASL A
    ORA $00
    
    ; Update PPUCTRL nametable bits
    ORA #%10010000  ; NMI on, sprites from pattern 0
    STA ppuctrl_settings
    
    RTS
  .endproc
.endscope
