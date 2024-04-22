main:           loadi.u r15,stack

                loadi.t r10,0xff00
                loadi.b r10,0
                loadi.u r11,0

loop:           loadi.u r0,0xf
                nop
.l1:            sub r0,r0,1
                nop
                branch.ne .l1
                nop
                nop
                nop
                store.b 3(r10),r11
                not r11,r11
                branch loop
                nop
                nop
                nop

#align 32

                #res 128
stack:

