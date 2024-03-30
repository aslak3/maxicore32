# Random scribblings, for now

This is a dumping ground, nothing more. Eventually it will become the core's main documentation.

# ISA design

* 5 bit opcode field, 32 top level opcodes
* 16 by 32bit registers
* 3 lots of 4 bits for register indexes in the top level instruction encoding
* All instructions are one 32 bit word
* NOP (0x00000000)
* Halt
* Load immediate 16 bit quantity into bottom half or top half
* Load/Store from/to register rD from/to rM with 16 bit displacement, 3 bit transfer type, optional
  adjustment of rM (for push and pop)
* ALU: r1<-r2,r3 or r1<-r2 or r1<-r2,imm
  * imm is 12+3 bits
  * Condition codes modified only by ALU
* Branch on 4 bit test, source PC with 16 bit displacement, saving PC in rPC
* Branch on 4 bit test, source PC with 16 bit displacement
* Jump on 4 bit test to rS

# Random open questions

* IO access: Will likely be via a top of table register with offsets. Is this adequate?
* Should the stack pointer adjustments cater for anything other then 4 byte wide quantities?
  * Since internally non long reads will always be extended, it seems reasonable to always put
    4 byte quantities on the stack since the stack is just a means to an end copy of registers
  * But on the other hand, this is inconsistent with the other load/store operations
* Use cases for r0 = 0
  * Branch is just saving PC to r0
  * Compare, though imm=0 will be the same
  * Clear is AND 0, but see above
* Need a mechanism for moving condition codes in and out of a register, as this was missing from both of the previous designs

## Example code

Generally, r15 is the stack pointer and r14 is the return address.

```
loadit r0,#0x1234
loadib r0 #0x5678
```

(r0 is now 0x12345678)

```
loadilt r0,0x12345678
loadilb r0,0x12345678
```

(This is identical to the above, but the assembler will provide these extra mnemonics for
loading labels etc)

```
loadil r0,0x12345678
```

(This is identical to the above, but the assembler will provide this extra mnemonic for
loading a long in two instructions)

```
loadi r1,#0x21
store.b (r0+666),r1
```

(memory 0x12345678+666 is now 0x21)

```
push.b (r0+666),r1
```

(Same as above but r0 is now decreased by 1 [or 4?] In reality displacements with push would never be used. push.b being an alias for store.b with a -1 post write change on rM)

```
callbranch.z -123,r2
push.l (r3),r2
```

(If zero, old PC is copied into r2 and PC decremented by 123. r2 is then stored at (r3) with r3 dec'd by 4)

```
pull.l r2,(r3)
jump r2
```

(Old PC is then restored (r3 inc'd by 4) into r2, and jumped to (return))

If this is the inner most sub the stacking can be skipped. Some register will be nominated as the usual return address such that return == jump rN

## strlen example (convoluted)

```
main:         loadil r15,#stack
              loadil r1,#string

              callbranch strlen,r14
              halt

string:       #d "Hello, world\0"
stack:        #res 100

; strlen: r1 is string, returns length in r2, r1 not preserved
strlen:       push.l (r15),r14            ; save our return address as we callbranch
              push.b (r15),r3             ; save the temp
              clear r2                    ; clear the length counter
.l1:          load.b r3,(r1)              ; get this byte
              callbranch checkfornull,r14 ; do the null check
              branch.z .out               ; on zero we are done
              inc r1                      ; inc pointer
              inc r2                      ; inc counter
              branch .l1                  ; back for more
.out:         pull.b r3.(r15)             ; restore temp
              pull.l r14,(r15)            ; restore return address
              jump r14                    ; return

; check for null - just does a test of r3
checkfornull: test r3                     ; comparing with zero
              jump r14
```

## Encoding for load immediate, top and bottom

- 31:27 - opcode (5)
- 23:20 - reg to use for data (4)
- 15:0 - data (16)

### Stages

0. fetch
1. empty
2. write value into reg rD
3. empty

## Encoding for load/store/push/pop

- 31:27 - opcode (load/store/pop/push)
- 26:24 - transfer size (3)
- 23:20 - reg to use for data (4)
- 19:16 - reg to use for address (4)
- 15:0 - offset (16)

### Stages

0. fetch
1. read or write memory rA with displacement
2. optional: write value into rD and adjust rA based on stacking
3. empty

## Encoding for ALU

- 31:27 - opcode
- 23:20 - reg for destination data (rD)
- 19:16 - reg for operand 1 (rA)
- 15:12 - operation (low 4 bits)
- 11:8 - reg for operand 2 (rO)

### Stages

0. fetch
1. setup ALU
2. write result into rD
3. empty

## Encoding for ALUI

- 31:27 - opcode
- 26:24 - top 3 bits of immediate
- 23:20 - reg for destination data (rD)
- 19:16 - reg for operand 1 (rA)
- 15:12 - operation (low 4 bits)
- 11:0 - low 12 bits of immediate

### Stages

Same as above

## Branch/CallBranch

- 31:27 - opcode
- 23:20 - reg for old pc (rD)
- 19:16 - top 4 bits of offset
- 15:12 - condition
- 11:0 - bottom 12 bits of offset

### Stages

0. fetch
1. empty
2. write old PC to rPC if condition met
3. branch to new PC if condition met

## Jump

- 31:27 - opcode
- 19:16 - reg to use for new PC
- 15:12 - condition

### Stages

0. fetch
1. empty
2. empty
3. jump to new PC is condition met

# Next iteration

* Load/Store from/to register rD from/to PC with 16 of 12 bit displacement, 3 bit transfer type
* Branch on 4 bit test, source rD with 16 or 12 bit displacement, saving PC in rPC

## Wiring

### register_File

input   clear
* stage 2 on OPCODE_CLEAR
input   write
* stage 2 on OPCODE_LOADI, OPCODE_LOAD, OPCODE_POP)
input   inc
* stage 2 on OPCODE_PUSH
input   dec
* stage 2 on OPCODE_POP
input   t_reg_index write_index
* fixed at [23:20] from instruction (reg rD)
input   t_reg_index incdec_index
* fixed at [19:16] from instruction (reg rA)
input   t_reg write_data
* Needs to be one of: (Selector set in stage 2)
  * [15:0] from instruction for OPCODE_LOADI
  * ALU result (OPCODE_ALU*)
  * PC (OPCODE_CALLBRANCH)
input   t_reg_index read_reg1_index, read_reg2_index, read_reg3_index
  * Come from
output  t_reg read_reg1_data, read_reg2_data, read_reg3_data
