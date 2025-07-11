PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002 ; this is a read only. also resets the PPUADDR
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007

OAMADDR = $2003
OAMDMA = $4014

CONTROLLER1 = $4016
CONTROLLER2 = $4017

BTN_RIGHT   = %00000001
BTN_LEFT    = %00000010
BTN_DOWN    = %00000100
BTN_UP      = %00001000
BTN_START   = %00010000
BTN_SELECT  = %00100000
BTN_B       = %01000000
BTN_A       = %10000000

STATEPLAYING   = $00  ; move paddles/ball, check for collisions
STATEPAUSE     = $01  ; displaying title screen
STATETITLE     = $02  ; displaying title screen
STATEGAMEOVER  = $03  ; displaying game over screen
