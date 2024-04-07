                nop
                loadi.u r1, stuff
                loadi.u r4, 1
                nop
                load.l r2, 4(r1)
                nop
                nop
                not r3, r2
                halt

stuff:          #d32 0x12345678
                #d32 0xff00ff00

