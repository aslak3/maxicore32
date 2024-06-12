# MaxiCore32

This document is for the processor core only. The VGA and specific board level integration bits will be documented in their own documents.

# Two stage pipeline

This processor features a two stage pipelined design. The first stage is used for setting up memory operations and setting up the (clocked) ALU (including when branching), and the second stage is used for register writes and control flow.

In the current implementation, NOPs must be inserted by the programmer if a register write or condition register write needs to be completed before that value is used, for example a decrement to zero style loop requires a NOP or other instruction before the conditional branch. Branch delay slots are automatically inserted in order to improve code density. Two are currently required.

# ISA design

* 5 bit opcode field, 32 top level opcodes
* 16 by 32 bit registers
* All instructions are one 32 bit word - no trailing words
* NOP (0x00000000)
* Halt
* Load immediate 16 bit quantity into 32 bit sign extended, zero extended, 16 bit load into bottom half or top half
* Load/Store from/to register rD from/to rM with 16 bit displacement, 3 bit transfer type
  * Transfer type: long, word or byte with loads being optionally sign exteded
* Same as above but with a register as the displacement
* No stacking opcodes
* ALU: r1<-r2,r3 or r1<-r2 or r1<-r2,imm
  * imm is 12+3 bits sign extended to 32 bits
  * Condition codes modified only by ALU
* Branch on 4 bit test, source PC with 16 bit displacement, saving PC in rPC
* Branch on 4 bit test, source PC with 16 bit displacement
* Jump on 4 bit test to rS

# Modules

## Register File

This is fairly standard stuff with continuous assignment for the read-out of the 3 registers. The regular 32 bit write operation is joined by a 16 bit write that carries out signed extension etc as selected. There is no reset signal on this module since in hardware it is expensive to reset the register file.

## Program Counter

Predictable again. Supports jump and increment (+4).

## Status Register

(Should probably be renamed to Condition Code Register) This is the holder of the carry, zero, negative and overlfow flags. All are treated as individual signals but with one write signal.

## Bus Interface

The external bus connections route through here. It will map byte, word and long operations onto the 32bit external bus, for in and out data paths. It does not handle unaligned access and will generate a bus error signal if this is attempted. The 32 bit byte-addressable address space is turned into a 30 bit long addressable space here.

## ALU

The ALU is totally predicatable except that it is (currently) a clocked process. This was done to try to increase the fMax on the iCE40 FPGA I'm using. It may yet change (back) to being a combinational part.

## AGU

This calculates the final address as needed by the load/store/loadr/storer instructions. It will sign extend a 16 bit
offset, or use a 32 bit register's value directly.

## MemoryStage1

TBD

## RegisterStage2

TBD

## Maxicore32

The top level that brings everything together. Critically it contains the muxes that route the internal datapaths, based on what each part requires for each particular instruction.

# Random open questions and TODO

* IO access: Will likely be via a top of table register with offsets. Seems adequate.
* Need a mechanism for moving condition codes in and out of a register, as this was missing from both of the previous designs.
* The AGU should (probably) be used for branch (and jump) address calculations. This would remove one of the delays from branching/jumping.
* Code move: The memory and LED implementations should be moved out of the same dir the processor modules are in.
* Makefiles need love.
* Tests are lacking for the pipeline stages, AGU, ....

## Example code

Generally, r15 is the stack pointer and r14 is the return address.

```
loadi.u r0,0x1234
```

(r0 is now 0x00001234)

```
loadi.s r0,-1
```

(r0 is now 0xffffffff)

```
loadi.t r0,0x1234
loadi.b r0,0x5678
```

(r0 is now 0x12345678)

```
loadil. r0,0x12345678
```

(This is identical to the above, but the assembler will provide this extra macro for
loading a long in two instructions)

```
loadi.u r1,0x21
store.bu 666(r0),r1
```

(memory 0x12345678+666 is now 0x21)

## strlen example (convoluted)

```
main:           loadi.u r15,stack
                loadi.u r1,string
                loadi.u r10,0               ; loadi.t will not clear bottom
                loadi.t r10,0xff00          ; address of output device
                loadi.u r3,0                ; will store this soon, so clear it

                callbranch r14,my_strlen    ; calculate length of string
                store.l (r10),r2            ; save it at the output device
                halt

string:         #d "Hello, World!\0"

#align 32

                #res 128
stack:

; strlen: r1 is string, returns length in r2, r1 not preserved
my_strlen:      sub r15,r15,8               ; make room on stack for two longs
                copy r2,r1                  ; save original pointer
                store.l 0(r15),r14          ; save our return address as we callbranch
                store.l 4(r15),r3           ; save the temp
.l1:            load.bu r3,(r1)             ; get this byte
                callbranch r14,checkfornull ; do the null check
                branch.eq .out              ; on zero we are done
                add r1,r1,1                 ; inc pointer
                branch .l1                  ; back for more
.out:           sub r2,r1,r2                ; calculate length
                load.l r14,0(r15)           ; restore return address
                load.l r3,4(r15)            ; restore temp
                add r15,r15,8               ; shrink stack back
                jump r14                    ; return

; check for null - just does a test of r3
checkfornull:   test r3,r3                  ; comparing with zero
                jump r14

```

## Overview of stages

TBD when design is stable.

## Common layout positions

- 31:27 - opcode
- 23:20 - reg for destination data (rD) (1)
- 19:16 - reg for operand 1 (rA) (2)
- 11:8 - reg for operand 2 (rO) (3)

## nop

Opcode 5'b00000.

## halt

Self explanatory. An external signal is asserted to indicate when the preceding instructions in the pipeline have completed.

## load immediate, top and bottom

### Encoding

- 31:27 - opcode (5)
- 26:25 - immediate type (2)
- 23:20 - reg to use for data (4)
- 15:0 - data (16)

Immediate types:

```
localparam  IT_TOP = 2'b00,
            IT_BOTTOM = 2'b01,
            IT_UNSIGNED = 2'b10,
            IT_SIGNED = 2'b11;
```

Top and Bottom will leave the other portion intact.

## load/store

### Encoding

- 31:27 - opcode (load/store)
- 26:25 - cycle width (2)
- 24 - signed (1)
- 23:20 - reg to use for data (4) [write or read]
- 19:16 - reg to use for address (4) [read]
- 15:0 - offset (16)

Cycle widths:

```
localparam  CW_LONG = 2'b00,
            CW_WORD = 2'b01,
            CW_BYTE = 2'b10,
            CW_NULL = 2'b11;
```

## loadr/storer

### Encoding

- 31:27 - opcode (loadr/storer)
- 26:25 - cycle width (2)
- 24 - signed (1)
- 23:20 - reg to use for data (4) [write or read]
- 19:16 - reg to use for address (4) [read]
- 11:8 - reg for offset [read]

## ALU

### Encoding

- 31:27 - opcode
- 23:20 - reg for destination data (rD) [write]
- 19:16 - reg for operand 1 (rA) [read]
- 15:12 - operation (low 4 bits)
- 11:8 - reg for operand 2 (rO) [read]

Operations:

TBC when finalised.

## Encoding for ALUI

- 31:27 - opcode
- 26:24 - top 3 bits of immediate
- 23:20 - reg for destination data (rD) [write]
- 19:16 - reg for operand 1 (rA) [read]
- 15:12 - operation (low 4 bits)
- 11:0 - low 12 bits of immediate

## Branch/CallBranch

- 31:27 - opcode
- 26 - call flag
- 23:20 - reg for old pc (rD) [write]
- 19:16 - top 4 bits of offset
- 15:12 - condition
- 11:0 - bottom 12 bits of offset

Notes:

rD is only updated if the call flag is set.

Conditions:

```
localparam [3:0]    COND_AL = 4'h0, // always
                    COND_EQ = 4'h1, // equal AKA zero set
                    COND_NE = 4'h2, // not equal AKA zero clear
                    COND_CS = 4'h3, // carry set
                    COND_CC = 4'h4, // carry clear
                    COND_MI = 4'h5, // minus
                    COND_PL = 4'h6, // plus
                    COND_VS = 4'h7, // overflow set
                    COND_VC = 4'h8, // overflow clear
                    COND_HI = 4'h9, // unsigned higher
                    COND_LS = 4'ha, // unsigned lower than or same
                    COND_GE = 4'hb, // signed greater than or equal
                    COND_LT = 4'hc, // signed less than
                    COND_GT = 4'hd, // signed greater than
                    COND_LE = 4'he; // signed less than or equal
```

## Jump/CallJump

- 31:27 - opcode
- 26 - call flag
- 23:20 - reg for old pc (rD) [write]
- 19:16 - reg to use for new PC
- 15:12 - condition
