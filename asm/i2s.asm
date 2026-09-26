SAMPLES_MEM_BASE=0x01000000
IO_BASE=0x0f000000

LED_OF=0x00
PS2_STATUS_OF=0x04
PS2_SCANCODE_OF=0x08
TONEGEN_DURATION_OF=0x0c
TONEGEN_PERIOD_OF=0x10
TONEGEN_STATUS_OF=0x14
SCROLL_OF=0x18
I2C_ADDRESS_OF=0x1c
I2C_READ_OF=0x20
I2C_WRITE_OF=0x24
I2C_CONTROL_OF=0x28
I2C_STATUS_OF=I2C_CONTROL_OF
I2S_STATUS_OF=0x34
I2S_DATA0_OF=0x38
I2S_DATA1_OF=0x3c
I2S_DATA2_OF=0x40
I2S_DATA3_OF=0x44
I2S_RATE0_OF=0x48
I2S_RATE1_OF=0x4c
I2S_RATE2_OF=0x50
I2S_RATE3_OF=0x54

start:          loadi.u r15,stack                                   ; setup stack pointer
                loadi.l r11,IO_BASE

                loadi.u r0,0x0
                nop
                store.b LED_OF(r11),r0

                loadi.u r0,0x1
                nop
                store.w I2S_RATE0_OF(r11),r0
                loadi.u r0,0x1
                nop
                store.w I2S_RATE1_OF(r11),r0

                loadi.u r0,0x0
                loadi.u r1,4096
                loadi.u r2,0x0
                loadi.u r3,1024
                loadi.u r4,0xffff

mainloop:       store.w I2S_DATA0_OF(r11),r0                         ; write it to i2s sender
                add r0,r0,r1
                nop
                and r0,r0,r4
                store.w I2S_DATA1_OF(r11),r2
                sub r2,r2,r3
.poll:          load.bu r10,I2S_STATUS_OF(r11)                       ; get status bit
                nop
                bit r10,r10,0x80                                      ; we are looking for zero
                nop
                branch.eq .poll                                     ; wait for not busy
                branch mainloop

stack:
                #res 32

