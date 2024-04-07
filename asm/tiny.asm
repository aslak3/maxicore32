                loadi.u r1, stuff
                loadi.u r2, target
                nop
                load.ws r3, (r1)
                nop
                store.w (r2), r3
                nop
                nop
                nop
                nop
                nop

stuff:          #d16 -1
target: