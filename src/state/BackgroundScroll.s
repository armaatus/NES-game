.scope BackgroundScroll
  .proc init_background_scroll
    LDA #239
    STA scroll
    RTS
  .endproc

  .proc update_background_scroll
    LDA scroll 
    BNE update_scroll ; Did we reach the end of a nametable
    ; if yes,
    ; Update base nametable
    LDA ppuctrl_settings
    EOR #%00000010 ; flip bit 1 to its opposite
    STA ppuctrl_settings
    LDA #240 ; Reset scroll to 240
    STA scroll

  update_scroll:
    DEC scroll
    RTS
  .endproc
.endscope
