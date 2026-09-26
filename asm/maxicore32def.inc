; General description of the ISA.

; 32 bit instructions, where an instruction always fits in a single 32 bit word.
; Memory is byte addressable, and all instructions are aligned to 4 bytes. Unaligned
; accesses are not allowed and will cause a fault.
;
; The current microarchitecture is a 2 stage pipeline. A nop instruction must be inserted
; in the following two cases:
; - between an ALU instruction and a conditional branch or jump instructure.
; - between a load instruction and any instruction that uses the loaded value.

; The registers available. No registers are special, but r15 is usually the stack
; pinter and r14 is usually a return address.
#subruledef reg
{
    r0  => 0
    r1  => 1
    r2  => 2
    r3  => 3
    r4  => 4
    r5  => 5
    r6  => 6
    r7  => 7
    r8  => 8
    r9  => 9
    r10 => 10
    r11 => 11
    r12 => 12
    r13 => 13
    r14 => 14
    r15 => 15
}

; The types used by load immediate.
#subruledef loaditype
{
    t => 0b000 ; top 16 bits of the value are loaded, bottom 16 are left alone
    b => 0b010 ; bottom 16 bits of the value are loaded, top 16 are left alone
    u => 0b100 ; the value is zero extended to 32 bits and loaded
    s => 0b110 ; the value is sign extended to 32 bits and loaded
}

; Ordinary loads.
#subruledef loadtype
{
    l =>    0b000 ; value is loaded as a 32 bit word
    wu =>   0b010 ; value is loaded as a 16 bit word and zero extended to 32 bits
    ws =>   0b011 ; value is loaded as a 16 bit word and sign extended to 32 bits
    bu =>   0b100 ; value is loaded as an 8 bit byte and zero extended to 32 bits
    bs =>   0b101 ; value is loaded as an 8 bit byte and sign extended to 32 bits
}

; Ordinary stores.
#subruledef storetype
{
    l => 0b000 ; value is stored as a 32 bit word
    w => 0b010 ; value is stored as a 16 bit word
    b => 0b100 ; value is stored as an 8 bit byte
}

; Condition codes are basically ARM style but always is 0.
#subruledef condition
{
    al => 0x0
    eq => 0x1
    zs => 0x1
    ne => 0x2
    zc => 0x2
    cs => 0x3
    cc => 0x4
    mi => 0x5
    pl => 0x6
    vs => 0x7
    vc => 0x8
    hi => 0x9
    ls => 0xa
    ge => 0xb
    lt => 0xc
    gt => 0xd
    le => 0xe
}

; Two operand ALU operations, where the destination is the first argument. One operand
; must be a register. The second can be either a register or an immediate value.
#subruledef twooperalu
{
    add         => 0x0
    addc        => 0x1
    sub         => 0x2
    subc        => 0x3
    and         => 0x4
    or          => 0x5
    xor         => 0x6
    compare     => 0x7
    bit         => 0x8
    mulu        => 0x9
    muls        => 0xa
    logicleft   => 0xb
    logicright  => 0xc
    arithleft   => 0xd
    arithright  => 0xe
}

; One operand ALU operations, where the destination is the first argument.
; The operand must be a register.
#subruledef oneoperalu
{
    not        => 0x0
    negate     => 0x1
    swap       => 0x2
    test       => 0x3
    signextb   => 0x4
    signextw   => 0x5
    unsignextb => 0x6
    unsignextw => 0x7
    copy       => 0x8
}

; This is only a partial list of the bit positions for a typical instruction and
; glosses over details like immediate values and branch offsets, but it gives a general
; view.
; - 31:27 - opcode
; - 26:25 - type
; - 24 - signed
; - 23:20 - reg for destination data (rD) (1)
; - 19:16 - reg for operand 1 (rA) (2)
; - 11:8 - reg for operand 2 (rO) (3)

#ruledef
{
    nop => 0b00000 @ 0b000 @ 0x000000
    halt => 0b00001 @ 0b000 @ 0x000000

    ; load immediate 16 bit value with one of four types: top, bottom, signed and unsigned
    loadi.{type:loaditype} {dst:reg},{value} =>
        0b00010 @ type[2:0] @ dst[3:0] @ 0x0 @ value[15:0]
    ; special: load a 32 bit value using two instructions
    loadi.l {dst:reg},{value} =>
        0b00010 @ 0b000 @ dst[3:0] @ 0x0 @ value[31:16] @
        0b00010 @ 0b010 @ dst[3:0] @ 0x0 @ value[15:0]

    ; load and store, with and without sign extended 16 bit offset
    load.{type:loadtype} {dst:reg},{offset}({src:reg}) =>
        0b00011 @ type[2:0] @ dst[3:0] @ src[3:0] @ offset[15:0]
    store.{type:storetype} {offset}({dst:reg}),{src:reg} =>
        0b00100 @ type[2:0] @ src[3:0] @ dst[3:0] @ offset[15:0]
    load.{type:loadtype} {dst:reg},({src:reg}) =>
        0b00011 @ type[2:0] @ dst[3:0] @ src[3:0] @ 0x0000
    store.{type:storetype} ({dst:reg}),{src:reg} =>
        0b00100 @ type[2:0] @ src[3:0] @ dst[3:0] @ 0x0000

    ; load and store with register offset
    load.{type:loadtype} {dst:reg},{srcoffset:reg}({src:reg}) =>
        0b00101 @ type[2:0] @ dst[3:0] @ src[3:0] @ 0x0 @ srcoffset[3:0] @ 0x00
    store.{type:storetype} {dstoffset:reg}({dst:reg}),{src:reg} =>
        0b00110 @ type[2:0] @ src[3:0] @ dst[3:0] @ 0x0 @ dstoffset[3:0] @ 0x00

    ; ALU operations, ie. dest := op2 operation op3
    {aluop:twooperalu} {dst:reg},{operand2:reg},{operand3:reg} =>
        0b00111 @ 0b000 @ dst[3:0] @ operand2[3:0] @ aluop[3:0] @ operand3[3:0] @ 0x00
    ; same above but with an immediate operand3, which is a 12 bit sign extended value
	{aluop:twooperalu} {dst:reg},{operand2:reg},{value} =>
		0b01000 @ value[14:12] @ dst[3:0] @ operand2[3:0] @ aluop[3:0] @ value[11:0]
    ; same but one operand, ie. dst := operation op2
    {aluop:oneoperalu} {dst:reg},{operand2:reg} =>
        0b01001 @ 0b000 @ dst[3:0] @ operand2[3:0] @ aluop[3:0] @ 0x0 @ 0x00

    ; branch and jump, first always
	branch {target} =>
		0b01010 @ 0b000 @ 0x0 @ { target - $ - 4}[15:12] @ 0x0 @ { target - $ - 4}[11:0]
    ; same as above but with a condition code
	branch.{cond:condition} {target} =>
		0b01010 @ 0b000 @ 0x0 @ { target - $ - 4}[15:12] @ cond[3:0] @ { target - $ - 4}[11:0]
    ; jump to register, first without condition
	jump {dst:reg} =>
		0b01011 @ 0b000 @ 0x0 @ dst[3:0] @ 0x0 @ 0x000
    ; same as above but with a condition code
	jump.{cond:condition} {dst:reg} =>
		0b01011 @ 0b000 @ 0x0 @ dst[3:0] @ cond[3:0] @ 0x000

    ; branch to subroutine - pc is saved into savepc
	callbranch {savepc:reg},{target} =>
		0b01010 @ 0b001 @ savepc[3:0] @ { target - $ - 4}[15:12] @ 0x0 @ { target - pc - 4}[11:0]
    ; branch to subroutine with condition code - pc is saved into savepc
	callbranch.{cond:condition} {savepc:reg},{target} =>
		0b01010 @ 0b001 @ savepc[3:0] @ { target - $ - 4}[15:12] @ cond[3:0] @ { target - pc - 4}[11:0]
    ; jump to subroutine in register - pc is saved into savepc, first without condition
	calljump {savepc:reg},{dst:reg} =>
		0b01011 @ 0b001 @ savepc[3:0] @ dst[3:0] @ 0x0 @ 0x000
    ; same as above but with a condition code - pc is saved into savepc
	calljump.{cond:condition} {savepc:reg},{dst:reg} =>
		0b01011 @ 0b001 @ savepc[3:0] @ dst[3:0] @ cond[3:0] @ 0x000
}
