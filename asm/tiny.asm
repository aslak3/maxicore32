                nop                 ; FIX!
                loadi.u r1, stuff
                loadi.u r3, again
                load.wu r2, (r1)
                nop
again:          add r1, r1, 2
                callbranch r15, storeit
                nop
                nop
                nop
                sub r2, r2, 1
                jump.ne r3
                nop
                nop
                nop
                halt

storeit:        store.w (r1), r2
                jump r15
                nop
                nop
                nop

stuff:          #d16 0x20
