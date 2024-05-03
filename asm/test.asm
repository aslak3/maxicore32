WIDTH=32
HEIGHT=32

VIDEO_MEM_BASE=0x01000000
IO_BASE=0x02000000

LED_OF=0x00
PS2_STATUS_OF=0x04
PS2_SCANCODE_OF=0x08

KEY_BREAK=0xf0
KEY_W=0x1d
KEY_S=0x1b
KEY_A=0x1c
KEY_D=0x23
KEY_SPACE=0x29

TILE_WALL=1
TILE_DIRT=2
TILE_BOULDER=3
TILE_GEM=4
TILE_PLAYER=9
TILE_BLANK=12

                loadi.u r15,stack
                loadi.u r14,0                               ; return address
                loadi.u r13,vars                            ; base of global variables
                loadi.l r12,VIDEO_MEM_BASE
                loadi.l r11,IO_BASE

mainloop:       callbranch r14,drawplayer

                callbranch r14,readkeybd

                test r0,r0
                nop
                branch.eq mainloop

                copy r2,r0

                load.wu r0,player_xy-vars(r13)
                loadi.u r1,TILE_BLANK

                compare r2,r2,KEY_W
                nop
                branch.eq .move_up
                compare r2,r2,KEY_S
                nop
                branch.eq .move_down
                compare r2,r2,KEY_A
                nop
                branch.eq .move_left
                compare r2,r2,KEY_D
                nop
                branch.eq .move_right

.update:        load.bu r2,r0(r12)                              ; get whats at new space
                nop
                compare r2,r2,TILE_WALL                         ; see if we can't walk into it
                nop
                branch.eq mainloop                              ; if we can't, skip updating
                store.w player_xy-vars(r13),r0
                branch mainloop

.move_up:       store.b r0(r12),r1
                sub r0,r0,WIDTH*4
                branch .update
.move_down:     store.b r0(r12),r1
                add r0,r0,HEIGHT*4
                branch .update
.move_left:     store.b r0(r12),r1
                sub r0,r0,1*4
                branch .update
.move_right:    store.b r0(r12),r1
                add r0,r0,1*4
                branch .update

drawplayer:     load.wu r0,player_xy-vars(r13)
                loadi.u r1,TILE_PLAYER
                store.b r0(r12),r1
                jump r14

readkeybd:      load.bu r0,PS2_STATUS_OF(r11)                       ; get status of ps/2 port
                nop
                bit r0,r0,0x80                                      ; top bit is data ready
                nop
                branch.eq .nokey                                    ; no data, then out
                load.bu r0,PS2_SCANCODE_OF(r11)                     ; get current scancode
                load.wu r8,last_key-vars(r13)                       ; retrieve the last scancode we got
                store.w last_key-vars(r13),r0                       ; now overwrite it with current one
                compare r8,r8,KEY_BREAK                             ; see if LAST scancode was a break (0xf0)
                nop
                branch.eq .nokey                                    ; if it was, we ignore what we just got
                compare r0,r0,KEY_BREAK                             ; now see if THIS key is a break
                nop
                branch.eq .nokey                                    ; if it was, then ignore that too
                jump r14
.nokey:         loadi.u r0,0                                        ; return 0 unless we got a real key down
                jump r14

                #res 128
stack:

vars:
player_xy:      #d16 (0*4)+(2*WIDTH*4)                              ; position stored as tile mem offset
last_key:       #d16 0
