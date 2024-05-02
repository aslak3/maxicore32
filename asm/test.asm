WIDTH=32
HEIGHT=32

                loadi.u r15,stack
                loadi.u r14,0                   ; return address
                loadi.u r13,vars                ; base of global variables
                loadi.t r11,0x0100              ; base of vid memory
                loadi.b r11,0
                loadi.t r10,0x0200              ; base of io
                loadi.b r10,0

LED_OF=0x00
PS2_STATUS_OF=0x04
PS2_SCANCODE_OF=0x08

KEY_BREAK=0xf0
KEY_W=0x1d
KEY_S=0x1b
KEY_A=0x1c
KEY_D=0x23

TILE_PLAYER=9
TILE_BLANK=12

mainloop:       callbranch r14,readkeybd

                test r0,r0
                nop
                branch.eq mainloop

                copy r3,r0

                load.wu r0,player_x-vars(r13)
                load.wu r1,player_y-vars(r13)
                loadi.u r2,TILE_BLANK

                compare r3,r3,KEY_W
                nop
                branch.eq .move_up
                compare r3,r3,KEY_S
                nop
                branch.eq .move_down
                compare r3,r3,KEY_A
                nop
                branch.eq .move_left
                compare r3,r3,KEY_D
                nop
                branch.eq .move_right

.update:        store.w player_x-vars(r13),r0
                store.w player_y-vars(r13),r1

                loadi.u r2,TILE_PLAYER
                    
                callbranch r14,writetile

                branch mainloop

.move_up:       callbranch r14,writetile
                sub r1,r1,1
                branch .update
.move_down:     callbranch r14,writetile
                add r1,r1,1
                branch .update
.move_left:     callbranch r14,writetile
                sub r0,r0,1
                branch .update
.move_right:    callbranch r14,writetile
                add r0,r0,1
                branch .update

; r0=x, r1=y, r2=item
writetile:      mulu r8,r0,4
                mulu r9,r1,WIDTH*4
                nop
                add r9,r9,r8
                nop
                store.b r9(r11),r2
                jump r14

readtile:       mulu r8,r0,4
                mulu r9,r1,WIDTH*4
                nop
                add r9,r9,r8
                nop
                load.bu r2,r9(r11)
                jump r14

readkeybd:      load.bu r0,PS2_STATUS_OF(r10)
                nop
                bit r0,r0,0x80
                nop
                branch.eq .nokey
                load.bu r0,PS2_SCANCODE_OF(r10)
                load.wu r8,last_key-vars(r13)
                store.w last_key-vars(r13),r0
                compare r8,r8,KEY_BREAK
                nop
                branch.eq .nokey
                compare r0,r0,KEY_BREAK
                nop
                branch.eq .nokey
                jump r14
.nokey:         loadi.u r0,0
                jump r14

                #res 128
stack:

vars:
player_x:       #d16 10
player_y:       #d16 6
last_key:       #d16 0
