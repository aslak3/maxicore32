main:           loadi.u r15,stack
                loadi.u r1,string

                callbranch r14,my_strlen
                nop
                nop
                nop
                halt

string:         #d "Hello, world...\0"

#align 32

                #res 128
stack:


; strlen: r1 is string, returns length in r2, r1 not preserved
my_strlen:      sub r15,r15,8               ; make room on stack for two longs
                nop
                store.l 0(r15),r14          ; save our return address as we callbranch
                store.l 4(r15),r3           ; save the temp
                copy r2,r1                  ; save original pointer
.l1:            load.bu r3,(r1)             ; get this byte
                callbranch r14,checkfornull ; do the null check
                nop
                nop
                nop
                branch.eq .out              ; on zero we are done
                nop
                nop
                nop
                add r1,r1,1                 ; inc pointer
                branch .l1                  ; back for more
                nop
                nop
                nop
.out:           sub r2,r1,r2                ; calculate length
                load.l r14,0(r15)           ; restore return address
                load.l r3,4(r15)            ; restore temp
                add r15,r15,8               ; shrink stack back
                jump r14                    ; return
                nop
                nop
                nop

; check for null - just does a test of r3
checkfornull:   test r3,r3                  ; comparing with zero
                jump r14
                nop
                nop
                nop
