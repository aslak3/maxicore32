LEVELS_MEM_BASE=0x03000000
IO_BASE=0x0f000000

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

DEVICE_ADDRESS=0x50

                loadi.u r15,stack
                loadi.u r14,0                                       ; return address
                loadi.u r13,vars                                    ; base of global variables
                loadi.l r12,LEVELS_MEM_BASE
                loadi.l r11,IO_BASE

main:           loadi.u r1,0
.levelloop:     loadi.u r5,32
                loadi.u r2,0
.pageloop:      callbranch r14,writepage
                add r2,r2,32
                sub r5,r5,1
                nop
                branch.ne .pageloop
                add r1,r1,1
                nop
                compare r1,r1,8
                nop
                branch.ne .levelloop
                loadi.s r0,-1
                nop
                store.l LED_OF(r11),r0
.hop:           branch .hop
                ; not reached
                halt

; inputs: r1=level number (1KB each), r2=start of page into level, temps: r0=short lived temp, r3=memory address, r4=down counter from 31,
writepage:      sub r15,r15,4
                loadi.u r0,0
                store.l 0(r15),r14
                store.b I2C_CONTROL_OF(r11),r0                      ; clear last byte
                loadi.u r0,DEVICE_ADDRESS
                nop
                store.b I2C_ADDRESS_OF(r11),r0
                callbranch r14,waitnotbusy
                branch.ne nack
                copy r3,r1
                nop
                mulu r3,r3,1024
                nop
                add r3,r3,r2
                nop
                byteright r0,r3                                     ; take bits 15:8
                nop
                store.b I2C_WRITE_OF(r11),r0
                callbranch r14,waitnotbusy
                branch.ne nack
                store.b I2C_WRITE_OF(r11),r3
                callbranch r14,waitnotbusy
                branch.ne nack
                and r3,r3,0b1111111111                              ; mask away the level bits
                loadi.u r4,32-1
                mulu r3,r3,4                                        ; each tile is in a long
                nop
.writeloop:     load.bu r0,r3(r12)                                  ; get the byte
                add r3,r3,4                                         ; next tile
                store.b I2C_WRITE_OF(r11),r0                        ; write the byte to the eeprom
                callbranch r14,waitnotbusy                          ; wait for it to bye pulsed out
                branch.ne nack
                sub r4,r4,1
                nop
                branch.ne .writeloop
                loadi.u r0,0x80                                     ; last byte
                nop
                store.b I2C_CONTROL_OF(r11),r0                      ; set last byte
                load.bu r0,r3(r12)                                  ; get the byte from video memory
                nop
                store.b I2C_WRITE_OF(r11),r0                        ; write the byte to the eeprom
                callbranch r14,waitnotbusy                          ; wait for it to bye pulsed out
                branch.ne nack
.writepoll:     loadi.u r0,DEVICE_ADDRESS
                nop
                store.b I2C_ADDRESS_OF(r11),r0
                callbranch r14,waitnotbusy                          ; wait for it to bye pulsed out
                branch.ne .writepoll
                load.l r14,0(r15)                                   ; get return address from stack
                add r15,r15,4                                       ; shrink stack back
                jump r14

; returns with zero clear if nack'd
waitnotbusy:    load.bs r0,I2C_STATUS_OF(r11)                       ; get the current status
                nop
                test r0,r0
                nop
                branch.mi waitnotbusy                               ; loop back if busy is set
                and r0,r0,0x40                                      ; test the ack status while here
                jump r14

nack:           halt

                #res 128
stack:

vars:
