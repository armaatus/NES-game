.scope Player
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

    ; Velocity and target velocity
    LDA #$00
    STA target_velocity_x
    STA velocity_x
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

    ; Velocity and target velocity
    LDA #$00
    STA target_velocity_y
    STA velocity_y
    RTS
  .endproc

  .scope Movement
    .proc update
      JSR set_target_velocity
      JSR accelerate_velocity
      JSR apply_velocity
      JSR bound_position
      RTS
    .endproc
    
    .proc set_target_velocity
      ; Handle X-axis input
      ; Check if the B button is being pressed and save the state in X
      LDX #$00
      LDA pad1
      AND #BTN_B
      BEQ @check_right
      INX
    @check_right:
      ; Check if the right d-pad is down
      LDA pad1
      AND #BTN_RIGHT
      BEQ @check_left
      LDA right_velocity, X
      STA target_velocity_x
      JMP @handle_y
    @check_left:
      ; Check if the left d-pad is down
      LDA pad1
      AND #BTN_LEFT
      BEQ @no_x_direction
      LDA left_velocity, X
      STA target_velocity_x
      JMP @handle_y
    @no_x_direction:
      ; If no X direction is pressed, target velocity is 0
      LDA #$00
      STA target_velocity_x
      
    @handle_y:
      ; Handle Y-axis input
      ; Check if the up d-pad is down
      LDA pad1
      AND #BTN_UP
      BEQ @check_down
      LDA up_velocity, X
      STA target_velocity_y
      RTS
    @check_down:
      ; Check if the down d-pad is down
      LDA pad1
      AND #BTN_DOWN
      BEQ @no_y_direction
      LDA down_velocity, X
      STA target_velocity_y
      RTS
    @no_y_direction:
      ; If no Y direction is pressed, target velocity is 0
      LDA #$00
      STA target_velocity_y
      RTS
      
      ; Fixed velocity values
    right_velocity:
      .byte $03, $05  
    left_velocity:
      .byte $FD, $FB  
    up_velocity:
      .byte $FD, $FB  ; Moving up (negative Y)
    down_velocity:
      .byte $03, $05  ; Moving down (positive Y)
    .endproc

    .proc accelerate_velocity
      ; Handle X-axis acceleration
      LDA velocity_x
      CMP target_velocity_x
      BEQ @handle_y  ; Already at target X, check Y
      
      ; Check if we need to increase or decrease X velocity
      LDA target_velocity_x
      SEC
      SBC velocity_x
      BMI @decrease_x_velocity
      
    @increase_x_velocity:
      INC velocity_x
      JMP @handle_y
      
    @decrease_x_velocity:
      DEC velocity_x
      
    @handle_y:
      ; Handle Y-axis acceleration
      LDA velocity_y
      CMP target_velocity_y
      BEQ @done  ; Already at target Y, done
      
      ; Check if we need to increase or decrease Y velocity
      LDA target_velocity_y
      SEC
      SBC velocity_y
      BMI @decrease_y_velocity
      
    @increase_y_velocity:
      INC velocity_y
      RTS
      
    @decrease_y_velocity:
      DEC velocity_y
      
    @done:
      RTS
    .endproc
    
    .proc apply_velocity
      ; Apply X-axis velocity
      LDA velocity_x
      BEQ @handle_y
      
      ; Check X direction
      BMI @negative_x
      
    @positive_x:
      ; Moving right - add velocity to position
      LDA velocity_x
      CLC
      ADC player_world_x_lo
      STA player_world_x_lo
      BCC @handle_y  ; No carry, check Y
      
      ; Handle carry to high byte
      INC player_world_x_hi
      JMP @handle_y
      
    @negative_x:
      ; Moving left - subtract absolute value of velocity
      ; Convert negative velocity to positive for subtraction
      LDA #$00
      SEC
      SBC velocity_x
      STA $00  ; Store absolute velocity
      
      ; Subtract from position
      LDA player_world_x_lo
      SEC
      SBC $00
      STA player_world_x_lo
      BCS @handle_y  ; No borrow, check Y
      
      ; Handle borrow from high byte
      DEC player_world_x_hi
      
    @handle_y:
      ; Apply Y-axis velocity
      LDA velocity_y
      BEQ @done
      
      ; Check Y direction
      BMI @negative_y
      
    @positive_y:
      ; Moving down - add velocity to position
      LDA velocity_y
      CLC
      ADC player_world_y_lo
      STA player_world_y_lo
      BCC @done  ; No carry, we're done
      
      ; Handle carry to high byte
      INC player_world_y_hi
      RTS
      
    @negative_y:
      ; Moving up - subtract absolute value of velocity
      ; Convert negative velocity to positive for subtraction
      LDA #$00
      SEC
      SBC velocity_y
      STA $00  ; Store absolute velocity
      
      ; Subtract from position
      LDA player_world_y_lo
      SEC
      SBC $00
      STA player_world_y_lo
      BCS @done  ; No borrow, we're done
      
      ; Handle borrow from high byte
      DEC player_world_y_hi
      
    @done:
      RTS
    .endproc

    .proc bound_position
      ; Handle X-axis bounds
      ; Convert 12.4 fixed point X world position to screen coordinates
      LDA player_world_x_lo
      STA $00
      LDA player_world_x_hi
      STA $01
      
      ; Shift right 4 times to convert from 12.4 to integer
      LDX #4
    @x_shift_loop:
      LSR $01
      ROR $00
      DEX
      BNE @x_shift_loop
      
      ; Store screen X position
      LDA $00
      STA player_x
      
      ; Check X bounds
      LDA player_world_x_hi
      BMI @bound_left  ; Negative means we're too far left
      
      ; Check right bound
      LDA $01
      BNE @bound_right  ; High byte non-zero means too far right
      LDA $00
      CMP #240  ; Screen width minus sprite width
      BCS @bound_right
      JMP @handle_y_bounds
      
    @bound_left:
      ; Clamp to left edge
      LDA #$00
      STA player_world_x_lo
      STA player_world_x_hi
      STA player_x
      STA velocity_x  ; Stop X movement
      JMP @handle_y_bounds
      
    @bound_right:
      ; Clamp to right edge
      LDA #$F0  ; 240 * 16 = $0F00 in 12.4 fixed point
      STA player_world_x_lo
      LDA #$0F
      STA player_world_x_hi
      LDA #240
      STA player_x
      LDA #$00
      STA velocity_x  ; Stop X movement
      
    @handle_y_bounds:
      ; Handle Y-axis bounds
      ; Convert 12.4 fixed point Y world position to screen coordinates
      LDA player_world_y_lo
      STA $00
      LDA player_world_y_hi
      STA $01
      
      ; Shift right 4 times to convert from 12.4 to integer
      LDX #4
    @y_shift_loop:
      LSR $01
      ROR $00
      DEX
      BNE @y_shift_loop
      
      ; Store screen Y position
      LDA $00
      STA player_y
      
      ; Check Y bounds
      LDA player_world_y_hi
      BMI @bound_top  ; Negative means we're too far up
      
      ; Check bottom bound
      LDA $01
      BNE @bound_bottom  ; High byte non-zero means too far down
      LDA $00
      CMP #224  ; Screen height minus sprite height
      BCS @bound_bottom
      RTS
      
    @bound_top:
      ; Clamp to top edge
      LDA #$00
      STA player_world_y_lo
      STA player_world_y_hi
      STA player_y
      STA velocity_y  ; Stop Y movement
      RTS
      
    @bound_bottom:
      ; Clamp to bottom edge
      LDA #$E0  ; 224 * 16 = $0E00 in 12.4 fixed point
      STA player_world_y_lo
      LDA #$0E
      STA player_world_y_hi
      LDA #224
      STA player_y
      LDA #$00
      STA velocity_y  ; Stop Y movement
      RTS
    .endproc
  .endscope

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
    ; Draw player sprite (2x2 tiles)
    ; Set tile numbers
    LDA #$05
    STA $0201
    LDA #$06
    STA $0205
    LDA #$07
    STA $0209
    LDA #$08
    STA $020D

    ; Set tile attributes
    LDA #$00
    STA $0202
    STA $0206
    STA $020A
    STA $020E

    ; Set tile positions
    ; Top left tile
    LDA player_y
    STA $0200
    LDA player_x
    STA $0203

    ; Top right tile (x + 8)
    LDA player_y
    STA $0204
    LDA player_x
    CLC
    ADC #$08
    STA $0207

    ; Bottom left tile (y + 8)
    LDA player_y
    CLC
    ADC #$08
    STA $0208
    LDA player_x
    STA $020B

    ; Bottom right tile (x + 8, y + 8)
    LDA player_y
    CLC
    ADC #$08
    STA $020C
    LDA player_x
    CLC
    ADC #$08
    STA $020F
    
    RTS
    
  off_screen:
    ; Hide sprites off screen
    LDA #$FF
    STA $0200
    STA $0204
    STA $0208
    STA $020C
    RTS
  .endproc
.endscope
