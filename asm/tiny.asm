                nop                 ; FIX!
                loadi.u r1, stuff
                nop
                load.l r2, (r1)
                nop
                or r3, r2, 0x678
                halt

                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop

stuff:          #d32 0x12345000
