                nop
                loadi.u r1, stuff
                loadi.u r4, 1
                nop
                load.l r2, (r1)
                nop
                nop
                not r3, r2
                nop
                nop
                halt
                nop
                nop
                nop
                nop
                nop

stuff:          #d32 0x12345678
