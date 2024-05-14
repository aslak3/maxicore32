WIDTH=32
HEIGHT=32

VIDEO_MEM_BASE=0x01000000
IO_BASE=0x0f000000

LED_OF=0x00
PS2_STATUS_OF=0x04
PS2_SCANCODE_OF=0x08
TONEGEN_DURATION_OF=0x0c
TONEGEN_PERIOD_OF=0x10
SCROLL_OF=0x14
I2C_ADDRESS_OF=0x18
I2C_READ_OF=0x1c
I2C_WRITE_OF=0x20
I2C_CONTROL_OF=0x24
I2C_STATUS_OF=I2C_CONTROL_OF

KEY_BREAK=0xf0
KEY_W=0x1d
KEY_S=0x1b
KEY_A=0x1c
KEY_D=0x23
KEY_SPACE=0x29

TILE_WALL=0x01
TILE_DIRT=0x02
TILE_BOULDER=0x03
TILE_GEM=0x04
TILE_PLAYER=0x09
TILE_BAT=0x0a
TILE_BLANK=0x0f

BAT_DIR_UP=0x00
BAT_DIR_LEFT=0x10
BAT_DIR_DOWN=0x20
BAT_DIR_RIGHT=0x30

DEVICE_ADDRESS=0x50
LEVEL_NO=1
                loadi.u r15,stack
                loadi.u r14,0                                       ; return address
                loadi.u r13,vars                                    ; base of global variables
                loadi.l r12,VIDEO_MEM_BASE
                loadi.l r11,IO_BASE
                loadi.l r10,0x200000                                ; frame count, backwards while waiting
                loadi.s r5,4                                        ; direction boulder will slide

                callbranch r14,scrolling

waitloop:       sub r10,r10,1
                nop
                branch.ne waitloop

                loadi.u r1,1
                callbranch r14,loadlevel

mainloop:       add r10,r10,1
                nop
                bit r10,r10,0x3fff                                  ; every 2^14 loops
                nop
                callbranch.eq r14,gravity

                bit r10,r10,0x1fff                                   ; every 2^12 loops
                nop
                callbranch.eq r14,animater

                callbranch r14,scrolling

                callbranch r14,drawplayer

                callbranch r14,readkeybd                            ; might be 0 with zero set
                branch.eq mainloop

                copy r2,r0

                load.wu r0,player_xy-vars(r13)
                loadi.u r1,TILE_BLANK
                and r3,r0,0b1111111                                 ; 32*4, used for checking x

                compare r2,r2,KEY_W
                nop
                branch.eq .moveup
                compare r2,r2,KEY_S
                nop
                branch.eq .movedown
                compare r2,r2,KEY_A
                nop
                branch.eq .moveleft
                compare r2,r2,KEY_D
                nop
                branch.eq .moveright

.collisions:    load.bu r2,r0(r12)                                  ; get whats at new space, maybe again
                nop
                and r3,r2,0x0f
                nop
                compare r3,r3,TILE_GEM                              ; gems!
                nop
                branch.eq .gem
                compare r3,r3,TILE_WALL                             ; see if we can't walk into it
                nop
                branch.eq mainloop                                  ; if we can't, skip updating
                compare r3,r3,TILE_BOULDER                          ; see if we can't walk into it
                nop
                branch.eq mainloop                                  ; if we can't, skip updating
.updatepos:     store.w player_xy-vars(r13),r0                      ;.collisions new position
                branch mainloop

; r0=new player pos, r1=new pos of boulder, r2=whats at new pos of boulder, r4=delta of player
.bouldercheck:  load.bu r2,r0(r12)
                nop
                and r2,r2,0x0f
                nop
                compare r2,r2,TILE_BOULDER
                nop
                branch.ne .collisions                               ; check more collisions
                add r1,r0,r4                                        ; r1 is square on other side of boulder
                nop
                load.bu r2,r1(r12)                                  ; get that square
                nop
                compare r2,r2,TILE_BLANK
                nop
                branch.ne mainloop                                  ; can't move if square not empty
                loadi.u r2,TILE_BOULDER                             ; moving the boulder
                nop
                store.b r1(r12),r2                                  ; move boulder
                branch .updatepos                                   ; move into old space held by boulder

.gem:           loadi.u r1,0x1000
                loadi.l r2,0x80000
                store.l TONEGEN_PERIOD_OF(r11),r1
                store.l TONEGEN_DURATION_OF(r11),r2                 ; sound tone
                branch .updatepos                                   ; move into space held by gem

.moveup:        store.b r0(r12),r1
                sub r0,r0,WIDTH*4
                branch .collisions
.movedown:      store.b r0(r12),r1
                add r0,r0,WIDTH*4
                branch .collisions
.moveleft:      loadi.s r4,-4
                store.b r0(r12),r1
                add r0,r0,r4
                branch .bouldercheck
.moveright:     loadi.u r4,4                                        ; r4 has direction
                store.b r0(r12),r1
                add r0,r0,r4
                branch .bouldercheck

; r0=scanning position, r1=what's there, r2=what's at square below, r3=address of that square
gravity:        negate r5,r5                                        ; flip direction of sliding boulder
                loadi.u r0,WIDTH*4*(HEIGHT-2)                       ; start at row before last
                nop
.colloop:       load.bu r1,r0(r12)                                  ; get what's in this space
                nop
                and r2,r1,0x0f
                nop
                compare r2,r2,TILE_BOULDER                          ; hunting for moulders!
                nop
                branch.eq .foundboulder                             ; we will move them, if we should
                compare r2,r2,TILE_GEM                              ; we are checking for gems too
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
                compare r2,r2,TILE_BOULDER                          ; boulder landing on boulder?
                nop
                branch.eq .thingonboulder                           ; see if thing is landing on boulder
                compare r2,r2,TILE_BLANK                            ; looking for empty
                nop
                branch.ne .foundcontinue                            ; done if not empty
.done:          store.b r3(r12),r1                                  ; otherwise move it there
                loadi.u r1,TILE_BLANK
                nop
                store.b r0(r12),r1                                  ; clear original space
                add r3,r3,WIDTH*4                                   ; checking square below new pos
                nop
                load.bu r1,r3(r12)
                nop
                compare r1,r1,TILE_PLAYER
                nop
                branch.eq .hitplayer
                branch .foundcontinue                               ; back to look for more
.thingonboulder:add r4,r3,r5                                        ; look at tile to the right/left
                nop
                load.bu r2,r4(r12)
                nop
                compare r2,r2,TILE_BLANK                            ; looking for empty
                nop
                branch.ne .foundcontinue                            ; done if not empty
                copy r3,r4                                          ; found an empty, so set new pos
                branch .done
.hitplayer:     halt                                                ; todo

animater:       load.bu r4,bat_tile_match-vars(r13)                 ; get the bat tile we are looking for
                nop
                xor r1,r4,0x80                                      ; flip it for next time
                loadi.u r0,(WIDTH*4*HEIGHT)-4                       ; start at bottom right
                store.b bat_tile_match-vars(r13),r1                 ; save it
.loop:          load.bu r1,r0(r12)
                nop
                and r2,r1,0x8f
                nop
                compare r2,r2,TILE_GEM
                nop
                branch.eq .gem
                compare r2,r2,r4                                    ; looking for bats
                nop
                branch.eq .bat
.continue:      sub r0,r0,4
                nop
                branch.pl .loop
                jump r14
; r0=pos, r1=original and new tile
.gem:           add r1,r1,0x10
                nop
                and r1,r1,0x3f
                nop
                store.b r0(r12),r1
                branch .continue
; r0=original pos, r1=tile, r2=bat direction, r3=whats at new tile/what we are writing, r4=
.bat:           and r2,r1,0x30                                      ; get direction
                nop
                compare r2,r2,BAT_DIR_LEFT
                nop
                branch.eq .batleft
                compare r2,r2,BAT_DIR_DOWN
                nop
                branch.eq .batdown
                compare r2,r2,BAT_DIR_RIGHT
                nop
                branch.eq .batright
                sub r2,r0,WIDTH*4
                branch .collisions
.batleft:       sub r2,r0,4
                branch .collisions
.batdown:       add r2,r0,WIDTH*4
                branch .collisions
.batright:      add r2,r0,4
                branch .collisions
.collisions:    load.bu r3,r2(r12)                                  ; get whats at the new tile
                nop
                compare r3,r3,TILE_BLANK                            ; can only move into empty spaces
                nop
                branch.ne .rotate                                   ; bat needs to turn as it would hit soemthing
                loadi.u r3,TILE_BLANK
                nop
                store.b r0(r12),r3                                  ; clear tile vacated by bat
.draw:          xor r3,r1,0x80                                      ; flip the "seen" bit
                nop
                store.b r2(r12),r3
                branch .continue
.rotate:        add r1,r1,0x10                                      ; rotate!
                copy r2,r0                                          ; not moving
                and r1,r1,0b10111111
                branch .draw

scrolling:      load.wu r0,player_xy-vars(r13)                      ; get current position in tile memory
                nop
                and r2,r0,0b000001111100                            ; get x
                and r3,r0,0b111110000000                            ; get 32 * y
                sub r2,r2,(20*4)/2                                  ; move half a screen
                nop
                branch.mi .sethleft
                compare r2,r2,(31-20)*4
                nop
                branch.hi .sethright
.scrollh:       sub r3,r3,(15/2)*WIDTH*4                            ; mid point
                nop
                branch.mi .setvtop
                compare r3,r3,(31-15)*WIDTH*4
                nop
                branch.hi .setvbottom
.scrollv:       or r2,r2,r3                                         ; combine x and y
                nop
                store.l SCROLL_OF(r11),r2
                jump r14

.sethleft:      loadi.u r2,0
                branch .scrollh
.sethright:     loadi.u r2,(32-20)*4
                branch .scrollh
.setvtop:       loadi.u r3,0
                branch .scrollv
.setvbottom:    loadi.u r3,(32-15)*WIDTH*4
                branch .scrollv

drawplayer:     load.wu r0,player_xy-vars(r13)                      ; get current position in tile memory
                loadi.u r1,TILE_PLAYER
                nop
                store.b r0(r12),r1
                jump r14

; return the key pressed in r0, or 0. return with flags set according to test r0
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
                test r0,r0                                          ; exit with flags of key state
                jump r14
.nokey:         loadi.u r0,0                                        ; return 0 unless we got a real key down
                jump r14

; r1=level to load
loadlevel:      sub r15,r15,4
                nop
                store.l 0(r15),r14                                  ; save current return address
                loadi.u r0,0
                nop
                store.b I2C_CONTROL_OF(r11),r0                      ; clear last byte
                loadi.u r0,DEVICE_ADDRESS
                nop
                store.b I2C_ADDRESS_OF(r11),r0
                callbranch r14,i2cwaitnotbusy
                branch.ne nack
                mulu r1,r1,1024
                nop
                byteright r0,r1                                     ; take bits 15:8
                nop
                store.b I2C_WRITE_OF(r11),r0
                callbranch r14,i2cwaitnotbusy
                branch.ne nack
                store.b I2C_WRITE_OF(r11),r1
                callbranch r14,i2cwaitnotbusy
                branch.ne nack
                loadi.u r0,DEVICE_ADDRESS | 0x80                    ; read
                nop
                store.b I2C_ADDRESS_OF(r11),r0
                callbranch r14,i2cwaitnotbusy
                branch.ne nack
                loadi.u r1,32*32-1
                loadi.u r2,0
.loop:          store.b I2C_READ_OF(r11),r0
                callbranch r14,i2cwaitnotbusy
                branch.ne nack
                load.bu r0,I2C_READ_OF(r11)
                nop
                store.b r2(r12),r0                                 ; save tile into screen
                add r2,r2,4
                sub r1,r1,1
                nop
                branch.ne .loop
                loadi.u r0,0x80
                nop
                store.b I2C_CONTROL_OF(r11),r0                      ; set last byte
                store.b I2C_READ_OF(r11),r0
                callbranch r14,i2cwaitnotbusy
                branch.ne nack
                load.bu r0,I2C_READ_OF(r11)
                nop
                store.b r2(r12),r0
                load.l r14,0(r15)
                add r15,r15,4
                jump r14

nack:           halt

; returns with zero clear if nack'd
i2cwaitnotbusy: load.bs r0,I2C_STATUS_OF(r11)                       ; get the current status
                nop
                test r0,r0
                nop
                branch.mi i2cwaitnotbusy                               ; loop back if busy is set
                and r0,r0,0x40                                      ; test the ack status while here
                jump r14

                #res 128
stack:

vars:
player_xy:      #d16 (1*4)+(25*WIDTH*4)                              ; position stored as tile mem offset
last_key:       #d16 0
bat_tile_match: #d8 TILE_BAT
