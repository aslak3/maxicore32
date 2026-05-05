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
I2S_DATA_OF=0x34
I2S_STATUS_OF=0x38

start:          loadi.u r15,stack                                   ; setup stack pointer
                loadi.l r11,IO_BASE

                loadi.u r0,0x0
                nop
                store.b LED_OF(r11),r0

again:          loadi.l r1,SAMPLES_MEM_BASE                         ; start of table
                loadi.u r2,8*1024                                   ; length of table
mainloop:       load.bu r0,(r1)                                     ; get value we are playing
                loadi.u r3,0
                arithleft r0,r0,8
                nop
                copy r3,r0
                nop
                logicleft r3,r3,16
                nop
                add r0,r0,r3
                nop
                store.l I2S_DATA_OF(r11),r0                         ; write it to i2s sender
.poll:          load.bs r0,I2S_STATUS_OF(r11)                       ; get status bit
                nop
                test r0,r0                                          ; we are looking for zero
                nop
                branch.mi .poll                                     ; wait for not busy
                add r1,r1,4                                         ; get the next dataum
                sub r2,r2,1
                nop
                branch.ne mainloop
                branch again

stack:
                #res 32

