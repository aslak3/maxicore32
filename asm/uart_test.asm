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

ASCII_a=0x61
ASCII_0=0x30

; fixed register usage: all other register usage is fairly adhoc
;   r15=stack, r14=return address, r13=vars pointer, r11=io base address
;   r8, r9 and r10 are scratch and neither saved or restored

start:          loadi.u r15,stack                                   ; setup stack pointer
                loadi.u r14,0                                       ; return address
                loadi.l r11,IO_BASE

; .loop:          loadi.u r0,prompt
;                 callbranch r14,putstring
;                 loadi.u r0,buffer
;                 callbranch r14,getstring
;                 loadi.u r0,youtyped
;                 callbranch r14,putstring
;                 loadi.u r0,buffer
;                 callbranch r14,putstring
;
;                 branch .loop

                loadi.l r8,0xfffff
.loop:          loadi.u r1,buffer
                copy r0,r8
                callbranch r14,longtoascii
                loadi.u r0,0
                nop
                store.b (r1),r0
                loadi.u r0,buffer
                callbranch r14,putstring
                loadi.u r0,crlf
                callbranch r14,putstring
                test r8,r8
                nop
                branch.eq .done
                sub r8,r8,0x1
                branch .loop

.done:          halt

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

nybbletoascii:  compare r0,r0,10                                    ; <10?
                nop
                branch.lt .lt_10                                    ; yes, only add 0
                add r0,r0,ASCII_a-ASCII_0-10                        ; add past 'a', but less '0'
                nop
.lt_10:         add r0,r0,ASCII_0                                   ; add '0' too
                nop
                store.b (r1),r0                                     ; save that nybble
                add r1,r1,1
                jump r14

; convert the byte in r0 to hex, writing it into r1 and advancing it 2 bytes
bytetoascii:    sub r15,r15,8
                nop
                store.l 0(r15),r8
                store.l 4(r15),r14                                  ; save current return address
                unsignextb r8,r0                                          ; save original
                logicright r0,r0,4                                  ; get the left most nybble
                callbranch r14,nybbletoascii
                and r0,r8,0x0f                                      ; mask off the left nybble
                callbranch r14,nybbletoascii
                copy r0,r8                                    ; restore r0
                load.l r14,4(r15)
                load.l r8,0(r15)
                add r15,r15,8
                jump r14

; convert the word in r0 to hex, writing it into r1 and advancing it 4 bytes
wordtoascii:    sub r15,r15,8
                nop
                store.l 4(r15),r8
                store.l 0(r15),r14                                  ; save current return address
                unsignextw r8,r0
                logicright r0,r0,8                                  ; get the top byte
                callbranch r14,bytetoascii
                unsignextb r0,r8
                callbranch r14,bytetoascii
                copy r0,r8                                          ; restore r0
                load.l r14,0(r15)
                load.l r8,4(r15)
                add r15,r15,8
                jump r14

longtoascii:    sub r15,r15,8
                nop
                store.l 4(r15),r8
                store.l 0(r15),r14                                  ; save current return address
                copy r8,r0
                logicright r0,r0,16
                callbranch r14,wordtoascii
                unsignextw r0,r8
                callbranch r14,wordtoascii
                copy r0,r8                                          ; restore r0
                load.l r14,0(r15)
                load.l r8,4(r15)
                add r15,r15,8
                jump r14

                #res 32
stack:

prompt:         #d "\r\n\r\nHello! Type a message: \0"
buffer:         #res 80
youtyped:       #d "\r\nYou typed: \0"
crlf:           #d "\r\n\0"
