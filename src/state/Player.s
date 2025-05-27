.scope Player
  ; Movement constants
  MOVE_SPEED = 3          ; Normal movement speed
  DASH_SPEED = 8          ; Dash burst speed
  DASH_DURATION = 12      ; Frames dash lasts
  DASH_COOLDOWN = 30      ; Frames before can dash again
  FRICTION = 1            ; How quickly we slow down
  
  ; Diagonal movement factor (roughly 0.707 * 256 = 181)
  DIAGONAL_FACTOR = 181
  
  .proc init
    JSR init_x
    JSR init_y
    
    ; Initialize dash and momentum
    LDA #$00
    STA dash_timer
    STA dash_cooldown
    STA dash_dir_x
    STA dash_dir_y
    STA momentum_x
    STA momentum_y
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

    ; Velocity
    LDA #$00
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

    ; Velocity
    LDA #$00
    STA velocity_y
    RTS
  .endproc

  .scope Movement
    .proc update
      JSR handle_dash
      JSR handle_movement
      JSR apply_momentum
      JSR apply_velocity
      JSR bound_position
      JSR update_timers
      RTS
    .endproc
    
    .proc handle_dash
      ; Check if we're already dashing
      LDA dash_timer
      BNE @done  ; Still dashing, skip input check
      
      ; Check if dash is on cooldown
      LDA dash_cooldown
      BNE @done
      
      ; Check if B button pressed (dash button)
      LDA pressed_buttons
      AND #BTN_B
      BEQ @done
      
      ; Start dash! First get current direction
      LDA #$00
      STA dash_dir_x
      STA dash_dir_y
      
      ; Check X direction
      LDA pad1
      AND #BTN_RIGHT
      BEQ @check_left
      LDA #$01
      STA dash_dir_x
      JMP @check_y_dir
      
    @check_left:
      LDA pad1
      AND #BTN_LEFT
      BEQ @check_y_dir
      LDA #$FF  ; -1
      STA dash_dir_x
      
    @check_y_dir:
      LDA pad1
      AND #BTN_DOWN
      BEQ @check_up
      LDA #$01
      STA dash_dir_y
      JMP @validate_dash
      
    @check_up:
      LDA pad1
      AND #BTN_UP
      BEQ @validate_dash
      LDA #$FF  ; -1
      STA dash_dir_y
      
    @validate_dash:
      ; Make sure we have a direction
      LDA dash_dir_x
      BNE @start_dash
      LDA dash_dir_y
      BNE @start_dash
      
      ; No direction, dash forward based on last velocity
      LDA velocity_x
      BEQ @check_last_y
      BMI @dash_left
      LDA #$01
      STA dash_dir_x
      JMP @start_dash
    @dash_left:
      LDA #$FF
      STA dash_dir_x
      JMP @start_dash
      
    @check_last_y:
      LDA velocity_y
      BEQ @done  ; No movement at all, don't dash
      BMI @dash_up
      LDA #$01
      STA dash_dir_y
      JMP @start_dash
    @dash_up:
      LDA #$FF
      STA dash_dir_y
      
    @start_dash:
      ; Initialize dash
      LDA #DASH_DURATION
      STA dash_timer
      LDA #DASH_COOLDOWN
      STA dash_cooldown
      
    @done:
      RTS
    .endproc
    
    .proc handle_movement
      ; If dashing, apply dash velocity
      LDA dash_timer
      BEQ @normal_movement
      
      ; Calculate dash velocity
      LDA dash_dir_x
      BEQ @dash_y
      BMI @dash_left
      
      ; Dash right
      LDA #DASH_SPEED
      JMP @store_x_vel
    @dash_left:
      LDA #$00
      SEC
      SBC #DASH_SPEED
      
    @store_x_vel:
      STA velocity_x
      
    @dash_y:
      LDA dash_dir_y
      BEQ @check_diagonal_dash
      BMI @dash_up
      
      ; Dash down
      LDA #DASH_SPEED
      JMP @store_y_vel
    @dash_up:
      LDA #$00
      SEC
      SBC #DASH_SPEED
      
    @store_y_vel:
      STA velocity_y
      
    @check_diagonal_dash:
      ; If moving diagonally, normalize speed
      LDA dash_dir_x
      BEQ @done
      LDA dash_dir_y
      BEQ @done
      
      ; Apply diagonal factor (multiply by ~0.707)
      JSR normalize_diagonal_velocity
      RTS
      
    @normal_movement:
      ; Regular movement input
      LDA #$00
      STA velocity_x
      STA velocity_y
      
      ; Check X input
      LDA pad1
      AND #BTN_RIGHT
      BEQ @check_left
      LDA #MOVE_SPEED
      STA velocity_x
      STA momentum_x  ; Set momentum
      JMP @check_y_input
      
    @check_left:
      LDA pad1
      AND #BTN_LEFT
      BEQ @check_y_input
      LDA #$00
      SEC
      SBC #MOVE_SPEED
      STA velocity_x
      STA momentum_x  ; Set momentum
      
    @check_y_input:
      LDA pad1
      AND #BTN_DOWN
      BEQ @check_up
      LDA #MOVE_SPEED
      STA velocity_y
      STA momentum_y  ; Set momentum
      JMP @check_diagonal
      
    @check_up:
      LDA pad1
      AND #BTN_UP
      BEQ @check_diagonal
      LDA #$00
      SEC
      SBC #MOVE_SPEED
      STA velocity_y
      STA momentum_y  ; Set momentum
      
    @check_diagonal:
      ; If moving diagonally, normalize speed
      LDA velocity_x
      BEQ @done
      LDA velocity_y
      BEQ @done
      
      JSR normalize_diagonal_velocity
      
    @done:
      RTS
    .endproc
    
    .proc normalize_diagonal_velocity
      ; Multiply velocities by diagonal factor (~0.707)
      ; For X velocity
      LDA velocity_x
      BPL @positive_x
      
      ; Negative X
      EOR #$FF
      CLC
      ADC #$01  ; Get absolute value
      TAX
      LDA #$00
      SEC
      SBC diagonal_table,X
      STA velocity_x
      JMP @normalize_y
      
    @positive_x:
      TAX
      LDA diagonal_table,X
      STA velocity_x
      
    @normalize_y:
      ; For Y velocity
      LDA velocity_y
      BPL @positive_y
      
      ; Negative Y
      EOR #$FF
      CLC
      ADC #$01  ; Get absolute value
      TAX
      LDA #$00
      SEC
      SBC diagonal_table,X
      STA velocity_y
      RTS
      
    @positive_y:
      TAX
      LDA diagonal_table,X
      STA velocity_y
      RTS
      
    ; Lookup table for diagonal speeds (speed * 0.707)
    diagonal_table:
      .byte 0, 1, 1, 2, 3, 4, 4, 5, 6  ; 0-8 mapped to diagonal equivalents
    .endproc
    
    .proc apply_momentum
      ; Only apply momentum if not actively moving
      LDA dash_timer
      BNE @done  ; Don't apply momentum during dash
      
      ; Check X momentum
      LDA velocity_x
      BNE @check_y_momentum  ; Player is actively moving X
      
      LDA momentum_x
      BEQ @check_y_momentum
      BPL @positive_momentum_x
      
      ; Negative momentum
      CLC
      ADC #FRICTION
      STA momentum_x
      STA velocity_x
      JMP @check_y_momentum
      
    @positive_momentum_x:
      SEC
      SBC #FRICTION
      STA momentum_x
      STA velocity_x
      
    @check_y_momentum:
      LDA velocity_y
      BNE @done  ; Player is actively moving Y
      
      LDA momentum_y
      BEQ @done
      BPL @positive_momentum_y
      
      ; Negative momentum
      CLC
      ADC #FRICTION
      STA momentum_y
      STA velocity_y
      RTS
      
    @positive_momentum_y:
      SEC
      SBC #FRICTION
      STA momentum_y
      STA velocity_y
      
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
    
    .proc update_timers
      ; Update dash timer
      LDA dash_timer
      BEQ @check_cooldown
      DEC dash_timer
      
    @check_cooldown:
      ; Update dash cooldown
      LDA dash_cooldown
      BEQ @done
      DEC dash_cooldown
      
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
      STA momentum_x  ; Stop momentum
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
      STA momentum_x  ; Stop momentum
      
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
      STA momentum_y  ; Stop momentum
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
      STA momentum_y  ; Stop momentum
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
