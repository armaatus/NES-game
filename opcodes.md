- INX => Increase register X by one
- INY => Increase register Y by one
- INC => Increase accumilator by one
- DEX => Decrease register X by one
- DEY => Decrease register Y by one
- DEC => Decrease accumilator by one
- BNE => branch if not equal to zero
- BEQ => Branch if equal to zero
- BCC => Branch if carry is cleared
- BCS => Branch if carry is set
- CMP => Compare to the accumilator register
- CPX => Compare to X register
- CPY => Compare to Y register

## Compare

1. Register is larger than comparison value => carry is set, zero flag cleared
2. Register is equal to comparison value => carry is set, zero flag is set
3. Register is smaller than comparison value -> carry cleared, zero flag cleared

```asm
LDA $06
  CMP #$80
  BEQ reg_was_80
  BCS reg_gt_80
  ; neither branch taken; register less than $80
  ; do something here
  JMP done_with_comparison ; jump to skip branch-specific code
reg_was_80:
  ; register equalled $80
  ; do something here
  JMP done_with_comparison ; skip the following branch
reg_gt_80:
  ; register was greater than $80
  ; do something here
  ; no need to jump because done_With_comparison is next
done_with_comparison:
  ; continue with rest of the program
```

```asm
LDX #$00
loop_start:
  ; do something
  INX
  CPX #$08
  BNE loop_start
  ; loop is finished here
```
