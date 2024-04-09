                nop                 ; FIX!
                loadi.u r1, stuff
                loadi.u r3, again
                load.bu r2, (r1)
                nop
again:          add r1, r1, 1
                nop
                nop
                store.b (r1), r2
                sub r2, r2, 1
                jump.ne r3
                nop
                nop
                nop
                halt

stuff:          #d8 0x20
