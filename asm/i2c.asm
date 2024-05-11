VIDEO_MEM_BASE=0x01000000
IO_BASE=0x02000000

LED_OF=0x00
PS2_STATUS_OF=0x04
PS2_SCANCODE_OF=0x08
TONEGEN_DURATION_OF=0x0c
TONEGEN_PERIOD_OF=0x10
SCROLL_OF=0x14
I2C_ADDRESS_OF=0x18
I2C_READ_OF=0x1c
I2C_WRITE_OF=0x20
I2C_CONTROL_OF=0x24
I2C_STATUS_OF=I2C_CONTROL_OF

                loadi.u r15,stack
                loadi.u r14,0                                       ; return address
                loadi.u r13,vars                                    ; base of global variables
                loadi.l r12,VIDEO_MEM_BASE
                loadi.l r11,IO_BASE

main:           loadi.u r0,0x68
                nop
                store.b I2C_ADDRESS_OF(r11),r0
                callbranch r14,waitnotbusy
                loadi.u r0,0
                nop
                store.b I2C_WRITE_OF(r11),r0
                callbranch r14,waitnotbusy
                loadi.u r0,0x68 | 0x80
                nop
                store.b I2C_ADDRESS_OF(r11),r0
                callbranch r14,waitnotbusy
                loadi.u r1,7
                loadi.u r2,vars
readloop:       store.b I2C_READ_OF(r11),r0
                callbranch r14,waitnotbusy
                load.bu r0,I2C_READ_OF(r11)
                nop
                store.b (r2),r0
                add r2,r2,1
                sub r1,r1,1
                nop
                branch.ne readloop
                loadi.u r0,0x80
                nop
                store.b I2C_CONTROL_OF(r11),r0
                nop
                store.b I2C_READ_OF(r11),r0
                callbranch r14,waitnotbusy
                load.bu r0,I2C_READ_OF(r11)
                nop
                store.b (r2),r0
                
                halt

waitnotbusy:    load.bs r0,I2C_STATUS_OF(r11)
                nop
                test r0,r0
                nop
                branch.mi waitnotbusy
                jump r14

                #res 128
stack:

vars:
