WIDTH=32
HEIGHT=32

VIDEO_MEM_BASE=0x01000000
IO_BASE=0x02000000

LED_OF=0x00
PS2_STATUS_OF=0x04
PS2_SCANCODE_OF=0x08
TONEGEN_DURATION_OF=0x0c
TONEGEN_PERIOD_OF=0x10

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
                loadi.u r14,0                                       ; return address
                loadi.u r13,vars                                    ; base of global variables
                loadi.l r12,VIDEO_MEM_BASE
                loadi.l r11,IO_BASE
                loadi.u r10,0                                       ; frame count

waitloop:       callbranch r14,readkeybd                            ; wait for a key before starting

                test r0,r0
                nop
                branch.eq waitloop

mainloop:       add r10,r10,1
                nop
                bit r10,r10,0x3fff                                 ; every 2^14 loops
                nop
                callbranch.eq r14,moveboulders

                callbranch r14,drawplayer

                callbranch r14,readkeybd

                test r0,r0
                nop
                branch.eq mainloop

                copy r2,r0

                load.wu r0,player_xy-vars(r13)
                loadi.u r1,TILE_BLANK
                and r3,r0,0b1111111                                 ; 32*4, used for checking x

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

.update:        load.bu r2,r0(r12)                                  ; get whats at new space
                nop
                compare r2,r2,TILE_WALL                             ; see if we can't walk into it
                nop
                branch.eq mainloop                                  ; if we can't, skip updating
                store.w player_xy-vars(r13),r0                      ; update new position
                compare r2,r2,TILE_GEM
                nop
                branch.eq gem

                branch mainloop

.move_up:       compare r0,r0,WIDTH*4
                store.b r0(r12),r1
                branch.lt mainloop
                sub r0,r0,WIDTH*4
                branch .update
.move_down:     compare r0,r0,14*WIDTH*4                            ; TODO
                store.b r0(r12),r1
                branch.gt mainloop
                add r0,r0,WIDTH*4
                branch .update
.move_left:     compare r3,r3,0
                store.b r0(r12),r1
                branch.eq mainloop
                sub r0,r0,1*4
                branch .update
.move_right:    compare r3,r3,19*4                                  ; TODO
                store.b r0(r12),r1
                branch.eq mainloop
                add r0,r0,1*4
                branch .update

gem:            loadi.u r0,0x1000
                nop
                store.l TONEGEN_PERIOD_OF(r11),r0
                loadi.l r0,0x80000
                nop
                store.l TONEGEN_DURATION_OF(r11),r0
                branch mainloop

drawplayer:     load.wu r0,player_xy-vars(r13)
                loadi.u r1,TILE_PLAYER
                nop
                store.b r0(r12),r1
                jump r14

; r0=scanning position, r1=what's there, r2=what's at square below, r3=address of that square
moveboulders:   loadi.u r0,WIDTH*4*(HEIGHT-2)                        ; start at row before last
                nop
.colloop:       load.bu r1,r0(r12)                                  ; get what's in this space
                nop
                compare r1,r1,TILE_BOULDER                          ; hunting for moulders!
                nop
                branch.eq .foundboulder                             ; we will move them, if we should
                compare r1,r1,TILE_GEM                              ; we are checking for gems too
                nop
                branch.eq .foundboulder                             ; gems are the same as boulders
.foundcontinue: add r0,r0,4                                         ; move to next boulder
                nop
                bit r0,r0,0b1111111                                 ; see if we are at the end of row
                nop
                branch.ne .colloop                                  ; back to the next tile?
                sub r0,r0,2*WIDTH*4                                 ; if not move back to start of prev row
                nop
                branch.pl .colloop                                  ; back to start the previous row
                jump r14
.foundboulder:  add r3,r0,WIDTH*4                                   ; getting square below
                nop
                load.bu r2,r3(r12)                                  ; get that into r2
                nop
                compare r2,r2,TILE_BLANK                            ; looking for empty
                nop
                branch.ne .foundcontinue                            ; done if not empty
                store.b r3(r12),r1                                  ; otherwise move it there
                loadi.u r1,TILE_BLANK
                nop
                store.b r0(r12),r1                                  ; clear original space
                branch .foundcontinue                               ; back to look for more

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
