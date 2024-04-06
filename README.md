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
* Load/Store from/to register rD from/to rM with 16 bit displacement, 3 bit transfer type
* No stacking opcodes
* ALU: r1<-r2,r3 or r1<-r2 or r1<-r2,imm
  * imm is 12+3 bits
  * Condition codes modified only by ALU
* Branch on 4 bit test, source PC with 16 bit displacement, saving PC in rPC
* Branch on 4 bit test, source PC with 16 bit displacement
* Jump on 4 bit test to rS

# Random open questions

* IO access: Will likely be via a top of table register with offsets. Seems adequate.
* Use cases for r0 = 0
  * Branch is just saving PC to r0
  * Compare, though imm=0 will be the same
  * Clear is AND 0, but see above
* Need a mechanism for moving condition codes in and out of a register, as this was missing from both of the previous designs
* Should duplicate opcodes be gutted? Eg inc vs add rD,1

## Example code

Generally, r15 is the stack pointer and r14 is the return address.

```
loadiwu r0,0x123
```

(r0 is now 0x00000123)

```
loadiws r0,-1
```

(r0 is now 0xffffffff)


```
loadit r0,#0x1234
loadib r0 #0x5678
```

(r0 is now 0x12345678)

```
loadil r0,0x12345678
```

(This is identical to the above, but the assembler will provide this extra mnemonic for
loading a long in two instructions)

```
loadi r1,#0x21
store.b 666(r0),r1
```

(memory 0x12345678+666 is now 0x21)

## strlen example (convoluted)

```
main:         loadil r15,#stack
              loadil r1,#string

              callbranch strlen,r14
              halt

string:       #d "Hello, world\0"
stack:        #res 100

; strlen: r1 is string, returns length in r2, r1 not preserved
strlen:       sub r15,8                   ; make room on stack for two longs
              ; data hazard
              store.l 0(r15),r14          ; save our return address as we callbranch
              store.l 4(r15),r3           ; save the temp
              copy r3,r1                  ; save original pointer
.l1:          load.b r3,(r1)              ; get this byte
              callbranch checkfornull,r14 ; do the null check
              ; branch hazard
              branch.z .out               ; on zero we are done
              inc r1                      ; inc pointer
              ; branch hazard
              branch .l1                  ; back for more
.out:         sub r2,r3,r1                ; calculate length
              load.l r14.0(r15)           ; restore temp
              load.l r3,4(r15)            ; restore return address
              add r15,8                   ; shrink stack back
              jump r14                    ; return

; check for null - just does a test of r3
checkfornull: test r3                     ; comparing with zero
              jump r14
```

## Overview of stages

0. Fetch

Current PC is placed on memory bus and instruction is latched into Instruction Register-Stage 0. PC is inc'd by 4. IR-S0 is clocked into IR-S1.

May be delayed (turned into NOP with no increment) by stage 1.

1. Read/Write memory rA with rD

For opcode==LOAD rA is placed on the memory bus and the data latched into rD.

For opcode==STORE rA is placed on the memory bus along with the data from rD.

IR-S1 is clocked into IR-S2.

Structural hazard: if this stage is needed, then the fetch that will happen on the same clock needs to be replaced with a NOP, and the PC increment suppressed.

2. Register update

For opcode==LOAD* or ALU* the data from either the external data bus or the ALU data output or the instruction immediate slice will be written into rD. Write may be: long, top half, bottom half, word zero extended or word sign extended.

IR-S2 is clocked into IR-S3.


## Common layout positions

- 31:27 - opcode
- 23:20 - reg for destination data (rD) (1)
- 19:16 - reg for operand 1 (rA) (2)
- 11:8 - reg for operand 2 (rO) (3)

## load immediate, top and bottom

### Encoding

- 31:27 - opcode (5)
- 25:24 - immediate type (2)
- 23:20 - reg to use for data (4)
- 15:0 - data (16)

### Stages

0. fetch
1. empty
2. write value into reg rD
3. empty

## load/store

### Encoding

- 31:27 - opcode (load/store)
- 26:24 - transfer size (3)
- 23:20 - reg to use for data (4) [write or read]
- 19:16 - reg to use for address (4) [read]
- 15:0 - offset (16)

### Stages

0. fetch
1. read or write memory rA with displacement
2. optional: write value into rD
3. empty

## ALU

### Encoding

- 31:27 - opcode
- 23:20 - reg for destination data (rD) [write]
- 19:16 - reg for operand 1 (rA) [read]
- 15:12 - operation (low 4 bits)
- 11:8 - reg for operand 2 (rO) [read]

### Stages

0. fetch
1. setup ALU
2. write result into rD
3. empty

## Encoding for ALUI

- 31:27 - opcode
- 26:24 - top 3 bits of immediate
- 23:20 - reg for destination data (rD) [write]
- 19:16 - reg for operand 1 (rA) [read]
- 15:12 - operation (low 4 bits)
- 11:0 - low 12 bits of immediate

### Stages

Same as above

## Branch/CallBranch

- 31:27 - opcode
- 23:20 - reg for old pc (rD) [write]
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

## Wiring

### register_File

* input   clear
  * unused
* input   write
  * stage 2 on OPCODE_LOADI*
* input   inc
  * unused
* input   dec
  * unused
* input   t_reg_index write_index
  * fixed at [23:20] from IR-S2 (reg rD)
* input   t_reg_index incdec_index
  * unused
* input   t_reg write_data
  * Switched via mux between: IR-S2
    * [15:0] from instruction for OPCODE_LOADI
    * ALU result (OPCODE_ALU*)
    * PC (OPCODE_CALLBRANCH)
* input   t_reg_index read_reg1_index, read_reg2_index, read_reg3_index
  * fixed at [...] from IR-S1
    * 23:20 (rD)
    * 19:16 (rA)
    * 11:8 (rO)
* output  t_reg read_reg1_data IR-S1
  * Switched via mux between:
    * ALU rD input
* output  t_reg read_reg2_data
  * Switched via mux between: IR-S1
    * Processor address bus
    * ALU rA input
* output  t_reg read_reg3_data IR-S1
  * fixed at rO input