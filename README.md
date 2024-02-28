# ISA design

* 16 by 32bit registers, r0 is fixed at 0
* All instructions are one 32 bit word
* NOP (0)
* Load immediate 16 bit quantity into low half, typically followed by swap and another load
* Load/Store from/to register rD from/to rM with 16 bit displacement, 3 bit transfer type, optional adjustment of rM
* ALU: r1<-r2,r3 or r1<-r2 or r1<-r2,imm
* Branch on 4 bit test, source PC with 16 or 12 bit displacement, saving PC in rPC
* Branch on 4 bit test, source PC with 16 or 12 bit displacement
* Jump on 4 bit test to rS

## Example code

loadi r0,#0x1234
swap r0
loadi r0 #0x5678

(r0 is now 0x12345678)

loadi r1,#0x21
store.b (r0+666),r1

(memory 0x12345678+666 is now 0x21)

push.b (r0+666),r1

(Same as above but r0 is now decreased by 4. In reality displacements with push would never be used)

callbranch.z -123,r2
push.l (r3),r2

(If zero, Old PC is copied into r2 and PC decremented by 123. r2 is then pushed onto stack at r3)

pull.l r2,(r3)
jump r2

(Old PC is then restored into r2, and jumped to (return))

## Encoding for load immediate

31:27 - opcode (5)
23:20 - reg to use for data (4)
15:0 - data (16)

### Stages

0: fetch
1: empty
2: write value into reg rD
3: empty

## Encoding for load/store/push/pop

31:29 - main op type (3)
28:27 - load/store/push/pop sub op type (2)
26:24 - transfer size (3)
23:20 - reg to use for data (4)
19:16 - reg to use for address (4)
15:0 - offset (16)

### Stages

0: fetch
1: read or write memory rA with displacement
2: optional: write value into rD and adjust rA based on stacking
3: empty

## Encoding for ALU

31:27 - opcode
23:20 - reg for destination data
19:16 - reg for operand 1
15:12 - reg for operation (low 4 bits)
11:8 - reg for operand 2

### Stages

0: fetch
1: setup ALU
2: write result into rD
3: empty

## Encoding for ALUI

31:27 - opcode
26:24 - top 3 bits of immediate
23:20 - reg for destination data
19:16 - reg for operand 1
15:12 - reg for operation (low 4 bits)
11:0 - low 12 bits of immediate

### Stages

Same as above

## Branch/CallBranch

31:27 - opcode
23:20 - reg for old pc
19:16 - top 4 bits of offset
15:12 - condition
11:0 - bottom 12 bits of offset

### Stages

0: fetch
1: empty
2: write old PC to rPC if condition met
3: branch to new PC if condition met

## Jump

31:27 - opcode
19:16 - reg to use for new PC
15:12 - condition

### Stages

0: fetch
1: empty
2: empty
3: jump to new PC is condition met

# Next iteration

* Load/Store from/to register rD from/to PC with 16 of 12 bit displacement, 3 bit transfer type
* Branch on 4 bit test, source rD with 16 or 12 bit displacement, saving PC in rPC
