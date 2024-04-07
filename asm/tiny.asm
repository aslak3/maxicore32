                nop
                loadi.u r1, stuff
                nop
                load.l r2, 4(r1)
                loadi.u r4, 4
                not r3, r2
                nop
                store.l 12(r1), r3
                nop
                add r1, r1, r4
                nop
                store.l 12(r1), r3
                store.l -12(r1), r3
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
                #d32 0x99999999

