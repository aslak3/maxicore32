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

TFP410_DEVICE_ADDRESS=0x38

; fixed register usage: all other register usage is fairly adhoc
;   r15=stack, r14=return address, r13=vars pointer, r12=video memory, r11=io base address, r10=status line
;   r5=boulder sliding direction (TODO: this should be a variable instead)

startnewgame:   loadi.u r15,stack                                   ; setup stack pointer
                loadi.u r14,0                                       ; return address
                loadi.l r11,IO_BASE
                loadi.s r5,4                                        ; direction boulder will slide

                callbranch r14,tfp410_init

nack:           halt

tfp410_init:    sub r15,r15,4
                nop
                store.l 0(r15),r14                                  ; save current return address

                loadi.u r1,tfp_reg_start
                loadi.u r2,tfp_reg_end-tfp_reg_start

.loop:          loadi.u r0,0
                nop
                store.b I2C_CONTROL_OF(r11),r0                      ; clear last byte
                loadi.u r0,TFP410_DEVICE_ADDRESS
                nop
                store.b I2C_ADDRESS_OF(r11),r0
                callbranch r14,i2cwaitnotbusy
                branch.ne nack
                load.bu r0,(r1)
                add r1,r1,1
                store.b I2C_WRITE_OF(r11),r0
                callbranch r14,i2cwaitnotbusy
                branch.ne nack
                loadi.u r0,0x80
                store.b I2C_CONTROL_OF(r11),r0                     ; set last byte
                load.bu r0,(r1)
                add r1,r1,1
                store.b I2C_WRITE_OF(r11),r0
                callbranch r14,i2cwaitnotbusy
                branch.ne nack

                sub r2,r2,2
                nop
                branch.ne .loop

                load.l r14,0(r15)
                add r15,r15,4
                jump r14

; returns with zero clear if nack'd
i2cwaitnotbusy: load.bs r0,I2C_STATUS_OF(r11)                       ; get the current status
                nop
                test r0,r0
                nop
                branch.mi i2cwaitnotbusy                            ; loop back if busy is set
                and r0,r0,0x40                                      ; test the ack status while here
                jump r14


                #res 32
stack:

vars:

tfp_reg_start:
                #d8 0x08
                #d8 0b00110101                                      ; ctl_1_mode
                #d8 0x09
                #d8 0b00111000                                      ; ctl_2_mode
                #d8 0x0a
                #d8 0b10000000                                      ; ctl_3_mode
                #d8 0x32
                #d8 0b00000000                                     ; de_dly
                #d8 0x33
                #d8 0b00000000                                     ; de_ctl
tfp_reg_end:
