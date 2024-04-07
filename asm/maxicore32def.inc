#bankdef bank
{
    #outp 0
    #addr 0
    #size 0x8000
    #bits 8
}


R0  = 0b0000000000000001
R1  = 0b0000000000000010
R2  = 0b0000000000000100
R3  = 0b0000000000001000
R4  = 0b0000000000010000
R5  = 0b0000000000100000
R6  = 0b0000000001000000
R7  = 0b0000000010000000
R8  = 0b0000000100000000
R9  = 0b0000001000000000
R10 = 0b0000010000000000
R11 = 0b0000100000000000
R12 = 0b0001000000000000
R13 = 0b0010000000000000
R14 = 0b0100000000000000
R15 = 0b1000000000000000

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
    al => 0xf
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
    copy    => 0x7
    compare => 0x8
    bit     => 0x9
    mulu    => 0xa
    muls    => 0xb
}
#subruledef oneargalu
{
    inc        => 0x0
    dec        => 0x1
    not        => 0x2
    logicleft  => 0x3
    logicright => 0x4
    arithleft  => 0x5
    arithright => 0x6
    negate     => 0x7
    swap       => 0x8
    test       => 0x9
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

    loadi.{type:loaditype} {dst:reg}, {value} =>
        0b00010 @ type[2:0] @ dst[3:0] @ 0x0 @ value[15:0]

    load.{type:loadtype} {dst:reg}, {offset}({src:reg}) =>
        0b00011 @ type[2:0] @ dst[3:0] @ src[3:0] @ offset[15:0]
    store.{type:storetype} {offset}({dst:reg}), {src:reg} =>
        0b00100 @ type[2:0] @ src[3:0] @ dst[3:0] @ offset[15:0]
    load.{type:loadtype} {dst:reg}, ({src:reg}) =>
        0b00011 @ type[2:0] @ dst[3:0] @ src[3:0] @ 0x0000
    store.{type:storetype} ({dst:reg}), {src:reg} =>
        0b00100 @ type[2:0] @ src[3:0] @ dst[3:0] @ 0x0000

    ; long form ALU operations, ie. dest := op2 operation op3
    {aluop:twoargalu} {dst:reg}, {operand2:reg}, {operand3:reg} =>
        0b00101 @ 0b000 @ dst[3:0] @ operand2[3:0] @ aluop[3:0] @ operand3[3:0] @ 0x00
	{aluop:twoargalu} {dst:reg}, {operand2:reg}, {value} =>
		0b00110 @ value[14:12] @ dst[3:0] @ operand2[3:0] @ aluop[3:0] @ value[11:0]
    ; same but one operand, ie. dst := operantion op2
    {aluop:oneargalu} {dst:reg}, {operand2:reg} =>
        0b00111 @ 0b000 @ dst[3:0] @ operand2[3:0] @ aluop[3:0] @ 0x0 @ 0x00
}
