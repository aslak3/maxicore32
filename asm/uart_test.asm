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

ASCII_SP=0x20
ASCII_EXP=0x21
ASCII_PERIOD=0x2e
ASCII_0=0x30
ASCII_COLON=0x3a
ASCII_A=0x41
ASCII_a=0x61

VARARG=0x80

; fixed register usage: all other register usage is fairly adhoc
;   r15=stack, r14=return address, r13=vars pointer, r11=io base address
; r4, r5 are scracth and are never saved.

start:          loadi.u r15,stack                                   ; setup stack pointer
                loadi.u r14,0                                       ; return address
                loadi.l r11,IO_BASE

mainloop:       loadi.u r8,prompt
                callbranch r14,putstring

                loadi.u r8,inputbuffer
                callbranch r14,getstring

                loadi.u r8,outputbuffer
                loadi.u r9,youtyped
                callbranch r14,concatstr
                loadi.u r9,inputbuffer
                callbranch r14,concatstr
                loadi.u r9,crlf
                callbranch r14,concatstr
                loadi.u r8,outputbuffer
                callbranch r14,putstring

                loadi.u r8,inputbuffer
                loadi.u r9,commandbuffer
.cmd_loop:      load.bu r0,(r8)
                add r8,r8,1
                test r0,r0
                nop
                branch.eq .cmd_done
                compare r0,r0,ASCII_SP
                nop
                branch.eq .cmd_done
                store.b (r9),r0
                add r9,r9,1
                branch .cmd_loop

.cmd_done:      loadi.u r0,0
                loadi.u r10,parsedbuffer
                store.b (r9),r0                             ; add a null to command
                loadi.u r1,0
                loadi.u r0,0
                store.l 0(r10),r1                           ; type
                store.l 4(r10),r0                           ; value

.parse_loop:    load.bu r0,(r8)
                nop
                test r0,r0
                nop
                branch.eq .parse_done
                compare r0,r0,ASCII_SP
                nop
                branch.eq .sp_hop
.sp_hop_cont:   callbranch r14,asciitoint
                test r1,r1
                nop
                branch.eq .parse_done
                store.l 0(r10),r1                           ; type
                store.l 4(r10),r0                           ; value
                add r10,r10,8
                branch .parse_loop
.sp_hop:        add r8,r8,1
                branch .sp_hop_cont

.parse_done:    loadi.u r1,0
                loadi.u r0,0
                store.l 0(r10),r1                           ; type
                store.l 4(r10),r0                           ; value

                loadi.u r8,outputbuffer
                loadi.u r9,command
                callbranch r14,concatstr
                loadi.u r9,commandbuffer
                callbranch r14,concatstr
                loadi.u r9,crlf
                callbranch r14,concatstr
                loadi.u r8,outputbuffer
                callbranch r14,putstring

                loadi.u r10,parsedbuffer
                nop
.print_loop:    load.l r0,0(r10)
                nop
                test r0,r0
                nop
                branch.eq .cmdtab_search

                loadi.u r8,outputbuffer
                loadi.u r9,type
                callbranch r14,concatstr
                load.l r0,0(r10)
                callbranch r14,bytetoascii
                loadi.u r9,crlf
                callbranch r14,concatstr
                loadi.u r8,outputbuffer
                callbranch r14,putstring

                loadi.u r8,outputbuffer
                loadi.u r9,value
                callbranch r14,concatstr
                load.l r0,4(r10)
                callbranch r14,longtoascii
                loadi.u r9,crlf
                callbranch r14,concatstr
                loadi.u r8,outputbuffer
                callbranch r14,putstring

                add r10,r10,8

                branch .print_loop

.cmdtab_search: loadi.u r10,commandtable                            ; top of command table
                loadi.u r12,parsedbuffer
.cmdtab_loop:   loadi.u r8,commandbuffer
                load.l r9,(r10)
                nop
                test r9,r9
                nop
                branch.eq .no_such_cmd
                callbranch r14,stringcomp
                load.l r0,8(r10)
                jump.eq r0                                          ; run handler?

.cmdtab_next:   add r10,r10,3*4

                branch .cmdtab_loop

.no_such_cmd:   loadi.u r8,nosuchcmd
                callbranch r14,putstring
                branch mainloop

readbyte:       load.l r0,4(r12)                                ; get the address
                loadi.u r8,outputbuffer
                load.bu r0,(r0)                                 ; get the byte at that address
                callbranch r14,bytetoascii
                branch readmemorytail
readword:       load.l r0,4(r12)                                ; get the address
                loadi.u r8,outputbuffer
                load.wu r0,(r0)                                 ; get the word at that address
                callbranch r14,wordtoascii
                branch readmemorytail
readlong:       load.l r0,4(r12)                                ; get the address
                loadi.u r8,outputbuffer
                load.l r0,(r0)                                  ; get the long at that address
                callbranch r14,longtoascii
                branch readmemorytail

readmemorytail: loadi.u r9,crlf
                callbranch r14,concatstr
                loadi.u r8,outputbuffer
                callbranch r14,putstring
                branch mainloop

writebytes:     load.l r0,4(r12)                                ; get the long at that address
                add r12,r12,8
                nop
.loop:          load.l r1,0(r12)                                ; get type
                add r0,r0,1                                     ; add early
                test r1,r1
                nop
                branch.eq mainloop
                load.l r1,4(r12)                                ; get the word we are writing
                nop
                store.b -1(r0),r1
                add r12,r12,8
                branch .loop

writelongs:     load.l r0,4(r12)                                ; get the long at that address
                add r12,r12,8
                nop
.loop:          load.l r1,0(r12)                                ; get type
                add r0,r0,4                                     ; add early
                test r1,r1
                nop
                branch.eq mainloop
                load.l r1,4(r12)                                ; get the word we are writing
                nop
                store.l -4(r0),r1
                add r12,r12,8
                branch .loop

writewords:     load.l r0,4(r12)                                ; get the long at that address
                add r12,r12,8
                nop
.loop:          load.l r1,0(r12)                                ; get type
                add r0,r0,2                                     ; add early
                test r1,r1
                nop
                branch.eq mainloop
                load.l r1,4(r12)                                ; get the word we are writing
                nop
                store.w -2(r0),r1
                add r12,r12,8
                branch .loop

dump:           loadi.l r0,0xfffffff0
                load.l r6,4(r12)                                ; start address
                load.l r7,(2*4)+4(r12)                          ; number of byts
                and r6,r0,r6                                    ; round start to whole line
                and r7,r0,r7                                    ; round length to whole line
.line_loop:     copy r0,r6                                      ; get start of line addr
                loadi.u r8,outputbuffer
                callbranch r14,longtoascii
                loadi.u r9,spacespace
                callbranch r14,concatstr

                loadi.u r2,0
                loadi.u r1,8
.word_loop:     load.wu r0,r2(r6)
                callbranch r14,wordtoascii
                loadi.u r9,space
                callbranch r14,concatstr
                compare r2,r2,6
                nop
                branch.ne .skip_space
                loadi.u r9,space
                callbranch r14,concatstr
.skip_space:    add r2,r2,2
                sub r1,r1,1
                nop
                branch.ne .word_loop

                loadi.u r9,asciistart
                callbranch r14,concatstr

                loadi.u r2,0
                loadi.u r1,16

.ascii_loop:    load.bu r0,r2(r6)
                callbranch r14,printableascii
                add r2,r2,1
                sub r1,r1,1
                nop
                branch.ne .ascii_loop

                loadi.u r9,asciiend
                callbranch r14,concatstr
                loadi.u r8,outputbuffer
                callbranch r14,putstring

                add r6,r6,16
                sub r7,r7,16
                nop
                branch.ne .line_loop

                branch mainloop

; general guidance:
; r8 = string pointer

; concatenate the string in r9 onto the string at r8, returning a pointer in r8 to the null that was added
concatstr:      load.bu r4,(r9)                                     ; get the byte to add from the source
                add r8,r8,1                                         ; advance dst
                add r9,r9,1                                         ; advance src
                test r4,r4                                          ; test the byte we are about to add
                store.b -1(r8),r4                                   ; add the byte and the pos pre increment
                branch.ne concatstr                                 ; add more if byte wasn't null
                sub r8,r8,1                                         ; point at the null
                jump r14

; outputs the null terminated at r8 to the terminal
putstring:      sub r15,r15,8
                nop
                store.l 4(r15),r0
                store.l 0(r15),r14                                  ; save current return address
                nop
.loop:          load.bu r0,(r8)
                add r8,r8,1
                test r0,r0
                nop
                branch.eq .out
                callbranch r14,putchar
                branch .loop
.out:           load.l r14,0(r15)
                load.l r0,4(r15)
                add r15,r15,8
                jump r14

; inputs a cr or lf temrminated line into r8, which is moved to the end
getstring:      sub r15,r15,8
                nop
                store.l 4(r15),r0
                store.l 0(r15),r14                                  ; save current return address
.loop:          callbranch r14,getchar
                compare r0,r0,0x0d
                nop
                branch.eq .eol
                compare r0,r0,0x0a
                nop
                branch.eq .eol
                callbranch r14,putchar
                store.b (r8),r0
                add r8,r8,1
                branch .loop
.eol:           loadi.u r0,0                                        ; addding a null
                nop
                store.b (r8),r0
                load.l r14,0(r15)
                load.l r0,4(r15)
                add r15,r15,8
                jump r14

; outputs the byte in r0
putchar:        load.bu r4,UART_STATUS_OF(r11)                      ; get the current status
                nop
                bit r4,r4,0b00100000
                nop
                branch.eq putchar                                   ; loop back if not ready
                store.b UART_DATA_OF(r11),r0
                jump r14

; inputs the byte in r0
getchar:        load.bu r4,UART_STATUS_OF(r11)                      ; get the current status
                nop
                bit r4,r4,0b10000000
                nop
                branch.eq getchar                                   ; loop back if not read
                load.bu r0,UART_DATA_OF(r11)
                jump r14

; converts the nybble in r0 to hex, writing it into r8 and advancing it 1 byte
_nybbletoascii: compare r0,r0,10                                    ; <10?
                nop
                branch.lt .lt_10                                    ; yes, only add 0
                add r0,r0,ASCII_a-ASCII_0-10                        ; add past 'a', but less '0'
                nop
.lt_10:         add r0,r0,ASCII_0                                   ; add '0' too
                nop
                store.b (r8),r0                                     ; save that nybble
                add r8,r8,1
                jump r14

; convert the byte in r0 to hex, writing it into r8 and advancing it 2 bytes
bytetoascii:    sub r15,r15,8
                nop
                store.l 0(r15),r14
                store.l 4(r15),r1
                unsignextb r1,r0                                    ; save original
                logicright r0,r0,4                                  ; get the left most nybble
                callbranch r14,_nybbletoascii
                and r0,r1,0x0f                                      ; mask off the left nybble
                callbranch r14,_nybbletoascii
                copy r0,r1                                          ; restore r0
                loadi.u r1,0
                nop
                store.b (r8),r1                                     ; null terminate
                load.l r1,4(r15)
                load.l r14,0(r15)
                add r15,r15,8
                jump r14

; convert the word in r0 to hex, writing it into r8 and advancing it 4 bytes
wordtoascii:    sub r15,r15,8
                nop
                store.l 0(r15),r14
                store.l 4(r15),r1
                unsignextw r1,r0
                logicright r0,r0,8                                  ; get the top byte
                callbranch r14,bytetoascii
                unsignextb r0,r1
                callbranch r14,bytetoascii
                copy r0,r1                                          ; restore r0
                load.l r1,4(r15)
                load.l r14,0(r15)
                add r15,r15,8
                jump r14

; convert the long in r0 to hex, writing it into r8 and advancing it 8 bytes
longtoascii:    sub r15,r15,8
                nop
                store.l 0(r15),r14
                store.l 4(r15),r1                                  ; save current return address
                copy r1,r0
                logicright r0,r0,16
                callbranch r14,wordtoascii
                unsignextw r0,r1
                callbranch r14,wordtoascii
                copy r0,r1                                          ; restore r0
                load.l r1,4(r15)
                load.l r14,0(r15)
                add r15,r15,8
                jump r14

; output the char if printable; if not output a period
printableascii: bit r0,r0,0b11100000                            ; < space
                nop
                branch.eq .unprintable
                bit r0,r0,0b10000000
                nop
                branch.ne .unprintable
.out:           store.b (r8),r0
                nop
                add r8,r8,1
                jump r14
.unprintable:   loadi.u r0,ASCII_PERIOD
                branch .out

datatypetable:  #d8 0                                               ; 0

                #d8 1                                               ; 1
                #d8 1                                               ; 2

                #d8 2                                               ; 3
                #d8 2                                               ; 4

                #d8 3                                               ; 5
                #d8 3                                               ; 6
                #d8 3                                               ; 7
                #d8 3                                               ; 8

                #d8 0                                               ; padding
                #d8 0
                #d8 0

; convert the string at r8 to a integer. r0 will hold the value, r1 will
; hold the type (1=byte, 2=word, 3=long). on error, r1 will be 0.
; r2 will be moved to the first non printable char. sets zero on error.

asciitoint:     sub r15,r15,4
                nop
                store.l 0(r15),r3                                   ; save r3 as we mess with it
                loadi.u r0,0                                        ; set result to zero
                loadi.u r1,0                                        ; clear digit counter
                branch .next_char                                   ; branch into loop
.top_of_loop:   sub r3,r3,ASCII_0                                   ; subtract '0' - r3 is this char
                nop
                branch.lt .bad                                      ; <0? that's bad_4
                compare r3,r3,0x09                                  ; less than or equal to 0?
                nop
                branch.ls .next_nyb                                 ; yes? we are done with this
                sub r3,r3,ASCII_A-ASCII_COLON                       ; subtract diff A - :
                nop
                branch.lt .bad                                      ; <0? bad
                compare r3,r3,0x10                                  ; see if it is uppercase
                nop
                branch.lt .next_nyb                                 ; was uppercase
                sub r3,r3,ASCII_a-ASCII_A                           ; was lowercase
                nop
                compare r3,r3,0x10                                  ; compare with upper range
                nop
                branch.ge .bad                                      ; >15? bad
.next_nyb:      logicleft r0,r0,4                                   ; shift val to next nybble
                nop
                add r0,r0,r3                                        ; accumulate number
                add r1,r1,1                                         ; inc digit number
                nop
                compare r1,r1,0x08                                  ; too many digits?
                nop
                branch.gt .bad                                      ; yes? bad
.next_char:     load.bu r3,(r8)                                     ; get the next character
                add r8,r8,1                                         ; move to next position
                compare r3,r3,ASCII_EXP                             ; see if its a nonwsp char
                nop
                branch.ls .out                                      ; yes? then we are done
                branch .top_of_loop                                 ; back for more digits
.bad:           loadi.u r1,0                                        ; mark 0 digits
.out:           loadi.u r3,datatypetable                            ; get start of table
                nop
                load.bu r1,r1(r3)                                   ; translate to type
                sub r8,r8,1                                         ; wind back to space char or null
                load.l r3,0(r15)                                    ; restore r3
                add r15,r15,4
                jump r14

; compares the string in r8 (left) with r9 (right), returning r0 with 0 if the same
stringcomp:     load.bu r0,(r8)                                     ; get left char
                add r8,r8,1                                         ; next position for left
                test r0,r0                                          ; looking for null
                nop
                branch.eq .tail_check                               ; need to check end of r9 string too
                load.bu r1,(r9)                                     ; get the right char
                add r9,r9,1                                         ; next position for right
                compare r0,r0,r1                                       ; seeing if they are the same
                nop
                branch.eq stringcomp                                ; next char
.no_match:      loadi.u r0,1                                        ; bad match
                branch .exit
.tail_check:    load.bu r1,(r9)                                     ; still next to check right is a null
                nop
                test r1,r1
                nop
                branch.ne .no_match                                 ; it isn't, so bad
                loadi.u r0,0                                        ; match result
.exit:          test r0,r0                                          ; set flags on exit
                jump r14

                #res 32
stack:

inputbuffer:    #res 64
outputbuffer:   #res 64
commandbuffer:  #res 16
parsedbuffer:   #res 128

prompt:         #d "\r\n> \0"
youtyped:       #d "\r\nYou typed: \0"
command:        #d "\r\nCommand: \0"
type:           #d "Type: \0"
value:          #d "Value: \0"
crlf:           #d "\r\n\0"

; command strings and maximum param sizes (1=byte, 2=word, 3=long, 0=end)
readbytestr:    #d "readbyte\0"
readwordstr:    #d "readword\0"
readlongstr:    #d "readlong\0"
readmemoryprm:  #d8 3, 0

writebytesstr:  #d "writebytes\0"
writebytesprm:  #d8 3, 1+VARARG, 0
writewordsstr:  #d "writewords\0"
writewordsprm:  #d8 3, 2+VARARG, 0
writelongsstr:  #d "writelongs\0"
writelongsprm:  #d8 3, 3+VARARG, 0

dumpstr:        #d "dump\0"
dumpprm:        #d8 3, 2,0

#align 32
; pointer to string, pointer to param list, pointer to subroutine
commandtable:   #d32 readbytestr, readmemoryprm, readbyte
                #d32 readwordstr, readmemoryprm, readword
                #d32 readlongstr, readmemoryprm, readlong
                #d32 writebytesstr, writebytesprm, writebytes
                #d32 writewordsstr, writewordsprm, writewords
                #d32 writelongsstr, writelongsprm, writelongs
                #d32 dumpstr, dumpprm, dump
                #d32 0

nosuchcmd:      #d "No such command\r\n\0"
space:          #d " \0"
spacespace:     #d "  \0"
asciistart:     #d "  [\0"
asciiend:       #d "]\r\n\0"