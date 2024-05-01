WIDTH=32
HEIGHT=32

            loadi.t r11,0x0100              ; base of vid memory
            loadi.b r11,0

            loadi.u r2,0x03                 ; rock

            loadi.u r0,0
            loadi.u r1,0
            loadi.u r3,18
            loadi.u r4,14
            nop
mainloop:   callbranch r13,box
            nop
            nop
            add r0,r0,1
            add r1,r1,1
            add r2,r2,1
            sub r3,r3,1
            sub r4,r4,1
            nop
            compare r0,r0,7
            nop
            branch.ne mainloop
            nop
            nop
            loadi.u r0,0
            loadi.u r1,0
            nop
            callbranch r14,readtile
            nop
            nop
            loadi.u r0,1
            loadi.u r1,1
            nop
            callbranch r14,writetile
            nop
            nop
            halt
            nop
            nop

box:        copy r5,r0
            copy r6,r1

toploop:    callbranch r14,writetile
            nop
            nop
            add r0,r0,1
            nop
            compare r0,r0,r3
            nop
            branch.ne toploop
            nop
            nop            
rightloop:  callbranch r14,writetile
            nop
            nop
            add r1,r1,1
            nop
            compare r1,r1,r4
            nop
            branch.ne rightloop
            nop
            nop            
bottomloop: callbranch r14,writetile
            nop
            nop
            sub r0,r0,1
            nop
            compare r0,r0,r5
            nop
            branch.ne bottomloop
            nop
            nop            
leftloop:   callbranch r14,writetile
            nop
            nop
            sub r1,r1,1
            nop
            compare r1,r1,r6
            nop
            branch.ne leftloop
            nop
            nop
            jump r13
            nop
            nop

; r0=x, r1=y, r2=item
writetile:  mulu r8,r0,4
            mulu r9,r1,WIDTH*4
            nop
            add r9,r9,r8
            nop
            store.b r9(r11),r2
            loadi.t r10,0x2
            loadi.b r10,0
            nop
.delay:     sub r10,r10,1
            nop
            branch.ne .delay
            nop
            nop
            jump r14
            nop
            nop
            nop

readtile:   mulu r8,r0,4
            mulu r9,r1,WIDTH*4
            nop
            add r9,r9,r8
            nop
            load.bu r2,r9(r11)
            nop
            jump r14
            nop
            nop

