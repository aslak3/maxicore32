                nop                 ; FIX!
                loadi.u r1, stuff
                nop
                load.bu r2, (r1)
                nop
again:          add r1, r1, 1
                nop
                nop
                store.b (r1), r2
                sub r2, r2, 1
                branch.ne again
                nop
                nop
                nop
                halt

stuff:          #d8 0x20
