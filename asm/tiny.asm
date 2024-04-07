                nop                 ; FIX!
                loadi.u r1, stuff
                nop
                load.l r2, (r1)
                add r1, r1, 8
                nop
                load.l r2, -4(r1)
                halt

                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop

stuff:          #d32 0x12345678
                #d32 0xdeadbeef
