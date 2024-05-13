#bankdef bank
{
    #outp 0
    #addr 0
    #size 0x8000
    #bits 8
}

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

#subruledef loaditype
{
    t => 0b000
    b => 0b010
    u => 0b100
    s => 0b110
}
#subruledef loadtype
{
    l =>    0b000
    wu =>   0b010
    ws =>   0b011
    bu =>   0b100
    bs =>   0b101
}
#subruledef storetype
{
    l => 0b000
    w => 0b010
    b => 0b100
}

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
#subruledef twoargalu
{
    add     => 0x0
    addc    => 0x1
    sub     => 0x2
    subc    => 0x3
    and     => 0x4
    or      => 0x5
    xor     => 0x6
    compare => 0x7
    bit     => 0x8
    mulu    => 0x9
    muls    => 0xa
}
#subruledef oneargalu
{
    not        => 0x0
    logicleft  => 0x1
    logicright => 0x2
    byteleft   => 0x3
    byteright  => 0x4
    arithleft  => 0x5
    arithright => 0x6
    negate     => 0x7
    swap       => 0x8
    test       => 0x9
    signextb   => 0xa
    signextw   => 0xb
    unsignextb => 0xc
    unsignextw => 0xd
    copy       => 0xe
}

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

    ; load immediate with one of four types: top, bottom, signed and unsigned
    loadi.{type:loaditype} {dst:reg},{value} =>
        0b00010 @ type[2:0] @ dst[3:0] @ 0x0 @ value[15:0]
    ; special: load a 32 bit value using two instructions
    loadi.l {dst:reg},{value} =>
        0b00010 @ 0b000 @ dst[3:0] @ 0x0 @ value[31:16] @
        0b00010 @ 0b010 @ dst[3:0] @ 0x0 @ value[15:0]

    ; load and store, with and without offset
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
    {aluop:twoargalu} {dst:reg},{operand2:reg},{operand3:reg} =>
        0b00111 @ 0b000 @ dst[3:0] @ operand2[3:0] @ aluop[3:0] @ operand3[3:0] @ 0x00
	{aluop:twoargalu} {dst:reg},{operand2:reg},{value} =>
		0b01000 @ value[14:12] @ dst[3:0] @ operand2[3:0] @ aluop[3:0] @ value[11:0]
    ; same but one operand, ie. dst := operation op2
    {aluop:oneargalu} {dst:reg},{operand2:reg} =>
        0b01001 @ 0b000 @ dst[3:0] @ operand2[3:0] @ aluop[3:0] @ 0x0 @ 0x00

    ; branch and jump, with and without condition
	branch {target} =>
		0b01010 @ 0b000 @ 0x0 @ { target - pc - 4}[15:12] @ 0x0 @ { target - pc - 4}[11:0]
	branch.{cond:condition} {target} =>
		0b01010 @ 0b000 @ 0x0 @ { target - pc - 4}[15:12] @ cond[3:0] @ { target - pc - 4}[11:0]
	jump {dst:reg} =>
		0b01011 @ 0b000 @ 0x0 @ dst[3:0] @ 0x0 @ 0x000
	jump.{cond:condition} {dst:reg} =>
		0b01011 @ 0b000 @ 0x0 @ dst[3:0] @ cond[3:0] @ 0x000

    ; branch and jump to subroutine, with and without condition - pc is saved into savepc
	callbranch {savepc:reg},{target} =>
		0b01010 @ 0b001 @ savepc[3:0] @ { target - pc - 4}[15:12] @ 0x0 @ { target - pc - 4}[11:0]
	callbranch.{cond:condition} {savepc:reg},{target} =>
		0b01010 @ 0b001 @ savepc[3:0] @ { target - pc - 4}[15:12] @ cond[3:0] @ { target - pc - 4}[11:0]
	calljump {savepc:reg},{dst:reg} =>
		0b01011 @ 0b001 @ savepc[3:0] @ dst[3:0] @ 0x0 @ 0x000
	calljump.{cond:condition} {savepc:reg},{dst:reg} =>
		0b01011 @ 0b001 @ savepc[3:0] @ dst[3:0] @ cond[3:0] @ 0x000
}
