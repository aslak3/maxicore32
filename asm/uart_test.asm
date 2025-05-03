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
UART_STATUS_OF=0x2c
UART_DATA_OF=0x30

; fixed register usage: all other register usage is fairly adhoc
;   r15=stack, r14=return address, r13=vars pointer, r11=io base address

start:          loadi.u r15,stack                                   ; setup stack pointer
                loadi.u r14,0                                       ; return address
                loadi.l r11,IO_BASE

.loop:          loadi.u r0,prompt
                callbranch r14,putstring
                loadi.u r0,buffer
                callbranch r14,getstring
                loadi.u r0,youtyped
                callbranch r14,putstring
                loadi.u r0,buffer
                callbranch r14,putstring

                branch .loop

                halt

; outputs the null terminated at r0 to the terminal
putstring:      sub r15,r15,4
                nop
                store.l 0(r15),r14                                  ; save current return address
                copy r2,r0                                          ; r2 is now the string pointer
                nop
.loop:          load.bu r0,(r2)
                add r2,r2,1
                test r0,r0
                nop
                branch.eq .out
                callbranch r14,putchar
                branch .loop
.out:           load.l r14,0(r15)
                add r15,r15,4
                jump r14

; inputs a cr or lf temrminated line into r0, which is moved to the end
getstring:      sub r15,r15,4
                nop
                store.l 0(r15),r14                                  ; save current return address
                copy r2,r0
.loop:          callbranch r14,getchar
                compare r0,r0,0x0d
                nop
                branch.eq .eol
                compare r0,r0,0x0a
                nop
                branch.eq .eol
                callbranch r14,putchar
                store.b (r2),r0
                add r2,r2,1
                branch .loop
.eol:           loadi.u r0,0                                        ; addding a null
                nop
                store.b (r2),r0
                load.l r14,0(r15)
                add r15,r15,4
                jump r14

; outputs the byte in r0
putchar:        load.bu r1,UART_STATUS_OF(r11)                      ; get the current status
                nop
                bit r1,r1,0b00100000
                nop
                branch.eq putchar                                   ; loop back if not ready
                store.b UART_DATA_OF(r11),r0
                jump r14

; inputs the byte in r0
getchar:        load.bu r1,UART_STATUS_OF(r11)                      ; get the current status
                nop
                bit r1,r1,0b10000000
                nop
                branch.eq getchar                                   ; loop back if not read
                load.bu r0,UART_DATA_OF(r11)
                jump r14

                #res 32
stack:

prompt:         #d "\r\n\r\nHello! Type a message: \0"
buffer:         #res 80
youtyped:       #d "\r\nYou typed: \0"
