WIDTH=32
HEIGHT=32

VIDEO_MEM_BASE=0x01000000
STATUS_MEM_BASE=0x02000000
IO_BASE=0x0f000000

LED_OF=0x00
PS2_STATUS_OF=0x04
PS2_SCANCODE_OF=0x08
TONEGEN_DURATION_OF=0x0c
TONEGEN_PERIOD_OF=0x10
TONEGEN_STATUS_OF=0x14
SCROLL_OF=0x18
I2C_ADDRESS_OF=0x1c
I2C_READ_OF=0x20
I2C_WRITE_OF=0x24
I2C_CONTROL_OF=0x28
I2C_STATUS_OF=I2C_CONTROL_OF

KEY_BREAK=0xf0
KEY_W=0x1d
KEY_S=0x1b
KEY_A=0x1c
KEY_D=0x23
KEY_ESC=0x76
KEY_SPACE=0x29

TILE_BLANK=0x00                 ; TILE_BLANK=0x00
TILE_WALL=0x01                  ; TILE_WALL=0x01
TILE_DIRT=0x02                  ; TILE_DIRT=0x02
TILE_BOULDER=0x03               ; TILE_BOULDER=0x03
TILE_EXIT=0x04                  ; TILE_EXIT=0x*d
TILE_PLAYER=0x05

TILE_GEM=0x08                   ; TILE_GEM=0x*c
TILE_GEM_1=0x09
TILE_GEM_2=0x0a
TILE_GEM_3=0x0b
TILE_BAT=0x0c                   ; TILE_BAT=0x*e
TILE_BAT_1=0x0d
TILE_BAT_2=0x0e
TILE_BAT_3=0x0f

TILE_STATUS_0=0x10
TILE_STATUS_1=0x11
TILE_STATUS_2=0x12
TILE_STATUS_3=0x13
TILE_STATUS_4=0x14
TILE_STATUS_5=0x15
TILE_STATUS_6=0x16
TILE_STATUS_7=0x17
TILE_STATUS_8=0x18
TILE_STATUS_9=0x19

TILE_STATUS_GEM=0x1a
TILE_STATUS_BLANK=0x1b
TILE_STATUS_PLAYER=0x1c
TILE_STATUS_DEAD_PLAYER=0x1d
TILE_STATUS_LEVEL1=0x1e
TILE_STATUS_LEVEL2=0x1f

BAT_DIR_UP=0x00
BAT_DIR_LEFT=0x01
BAT_DIR_DOWN=0x02
BAT_DIR_RIGHT=0x03

EEPROM_DEVICE_ADDRESS=0x50                                                 ; at24c64 i2c address
TFP410_DEVICE_ADDRESS=0x38

; fixed register usage: all other register usage is fairly adhoc
;   r15=stack, r14=return address, r13=vars pointer, r12=video memory, r11=io base address, r10=status line
;   r5=boulder sliding direction (TODO: this should be a variable instead)

startnewgame:   loadi.u r15,stack                                   ; setup stack pointer
                loadi.u r14,0                                       ; return address
                loadi.u r13,vars                                    ; base of global variables
                loadi.l r12,VIDEO_MEM_BASE
                loadi.l r11,IO_BASE
                loadi.l r10,STATUS_MEM_BASE
                loadi.s r5,4                                        ; direction boulder will slide

                callbranch r14,tfp410_init

                callbranch r14,skelstatus                           ; the status tuff that doesn't change

                callbranch r14,newgame
startnextlevel: callbranch r14,newlevel
                callbranch r14,scrolling
                callbranch r14,loadlevel
                callbranch r14,statusupdate

                loadi.l r9,0x100000                                 ; frame count, backwards while waiting
waitloop:       sub r9,r9,1
                nop
                branch.ne waitloop

mainloop:       add r9,r9,1
                nop
                bit r9,r9,0x3fff                                    ; every 2^14 loops move boulders
                nop
                callbranch.eq r14,gravity

                bit r9,r9,0x3fff                                    ; every 2^13 loops animate
                nop
                callbranch.eq r14,animater

                callbranch r14,scrolling

                callbranch r14,drawplayer

                callbranch r14,readkeybd                            ; might be 0 with zero set
                branch.eq mainloop

                copy r2,r0

                load.wu r0,player_pos-vars(r13)
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
                compare r2,r2,KEY_ESC
                nop
                branch.eq startnewgame                              ; escape will restart the game, if not halted


.collisions:    load.bu r3,r0(r12)                                  ; get whats at new space, maybe again
                nop
                compare r3,r3,TILE_EXIT
                nop
                branch.eq .exit
                compare r3,r3,TILE_WALL                             ; see if we can't walk into it
                nop
                branch.eq mainloop                                  ; if we can't, skip updating
                compare r3,r3,TILE_BOULDER                          ; see if we can't walk into it
                nop
                branch.eq mainloop                                  ; if we can't, skip updating
                and r3,r3,0x1c                                      ; mask away anim bits
                nop
                compare r3,r3,TILE_GEM                              ; gems!
                nop
                branch.eq .gem
.updatepos:     store.w player_pos-vars(r13),r0                     ; new position
                branch mainloop

; r0=new player pos, r1=new pos of boulder, r2=whats at new pos of boulder, r4=delta of player
.bouldercheck:  load.bu r2,r0(r12)
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

.gem:           loadi.u r1,0x4000
                loadi.u r2,0x1000
                store.l TONEGEN_PERIOD_OF(r11),r1
                store.l TONEGEN_DURATION_OF(r11),r2                 ; sound tone
                load.wu r1,exit_open-vars(r13)
                nop
                test r1,r1
                nop
                branch.ne .updatepos
                load.wu r1,gems_needed_1-vars(r13)                  ; get units of gems left
                nop
                sub r1,r1,1
                nop
                branch.mi .gem_unit_wrap
                store.w gems_needed_1-vars(r13),r1
.gemupdate:     callbranch r14,statusupdate
                callbranch r14,gemcountcheck
                branch .updatepos                                   ; move into space held by gem
.gem_unit_wrap: loadi.u r1,9                                        ; 0-1 = 9
                load.wu r2,gems_needed_10-vars(r13)                 ; get units of gems left
                store.w gems_needed_1-vars(r13),r1
                sub r2,r2,1
                nop
                branch.mi .gem_ten_wrap
                store.w gems_needed_10-vars(r13),r2
                branch .gemupdate
.gem_ten_wrap:  loadi.u r1,9                                        ; 0-1 = 9
                load.wu r2,gems_needed_100-vars(r13)                ; get units of gems left
                store.w gems_needed_10-vars(r13),r1
                sub r2,r2,1
                nop
                branch.mi .gem_hun_wrap
                store.w gems_needed_100-vars(r13),r2
                branch .gemupdate
.gem_hun_wrap:  loadi.u r1,9                                        ; 0-1 = 9
                nop
                store.w gems_needed_100-vars(r13),r1
                branch .gemupdate

.exit:          loadi.u r1,0x2000
                loadi.u r2,0x800
.beep_loop:     store.l TONEGEN_PERIOD_OF(r11),r1
                store.l TONEGEN_DURATION_OF(r11),r2                 ; sound tone
.beep_wait:     load.l r0,TONEGEN_STATUS_OF(r11)                    ; get the status of the tone generator
                nop
                test r0,r0                                          ; top bit is the "sounding" bit
                nop
                branch.mi .beep_wait                                ; wait for tone to finish
                sub r1,r1,0x100                                     ; adjust frequency u=p
                load.wu r0,current_level-vars(r13)                  ; while waiting, we can load level no
                branch.ne .beep_loop
                add r0,r0,1
                nop
                and r0,r0,0x07                                      ; only got 8 levels. :( well, 3 actually...
                nop
                store.w current_level-vars(r13),r0                  ; save the new current level
                branch startnextlevel                               ; to the top, but skip the new game bit

.moveup:        store.b r0(r12),r1
                sub r0,r0,WIDTH*4
                branch .collisions
.movedown:      store.b r0(r12),r1
                add r0,r0,WIDTH*4
                branch .collisions
.moveleft:      loadi.s r4,-4                                       ; r4 has direction, which is used later
                store.b r0(r12),r1
                add r0,r0,r4
                branch .bouldercheck
.moveright:     loadi.u r4,4                                        ; r4 has direction, ...
                store.b r0(r12),r1
                add r0,r0,r4
                branch .bouldercheck

; gemcountcheck - opens the door to the next level if remaning gem count is zero
gemcountcheck:  load.wu r1,gems_needed_100-vars(r13)                ; get the decimal count spread over three words
                load.wu r2,gems_needed_10-vars(r13)
                load.wu r3,gems_needed_1-vars(r13)
                add r1,r1,r2
                nop
                add r1,r1,r3                                        ; sum digits to see if they are all zero
                nop
                branch.eq .allgemsfound
                jump r14                                            ; non zero exit
.allgemsfound:  loadi.u r1,1                                        ; we are setting the exit_open var to one
                load.wu r2,exit_pos-vars(r13)                       ; get the exit position for this level
                loadi.u r3,TILE_EXIT                                ; stamping a TILE_EXIT tile
                store.w exit_open-vars(r13),r1                      ; set the exit_open var
                store.b r2(r12),r3                                  ; and stamp
                jump r14                                            ; the above ordering avoids some noppage

; statusupdate - loads the variables for lives and level and shows them in the status bar
statusupdate:   load.wu r1,gems_needed_100-vars(r13)                ; lots of registers means no stalls
                load.wu r2,gems_needed_10-vars(r13)
                load.wu r3,gems_needed_1-vars(r13)
                load.wu r4,current_level-vars(r13)
                add r1,r1,TILE_STATUS_0                             ; offset for the "0" tile index
                add r2,r2,TILE_STATUS_0
                add r3,r3,TILE_STATUS_0
                add r4,r4,TILE_STATUS_1
                store.b STATUS_GEM_HUNDREDS(r10),r1
                store.b STATUS_GEM_TENS(r10),r2
                store.b STATUS_GEM_UNITS(r10),r3
                store.b STATUS_LEVEL(r10),r4
                jump r14

; gravity - move boulders and gems if they are under fresh air (TILE_EXIT)
; r0=scanning position, r1=what's there, r2=what's at square below, r3=address of that square
gravity:        sub r15,r15,4                                       ; we are not a leaf sub, so make room on stack
                nop                                                 ; routine we might call is playerdead
                store.l 0(r15),r14                                  ; stack the return address
                negate r5,r5                                        ; flip direction of sliding boulder
                loadi.u r0,WIDTH*4*(HEIGHT-2)                       ; start at row before last
                nop
.colloop:       load.bu r1,r0(r12)                                  ; get what's in this space
                nop
                and r2,r1,0x0f                                      ; mask away upper nibble - we only want tile "type"
                nop
                compare r2,r2,TILE_BOULDER                          ; hunting for boulders!
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
                load.l r14,0(r15)                                   ; get the return address
                add r15,r15,4                                       ; give back to the stack
                jump r14                                            ; and done here
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
                load.bu r1,r3(r12)                                  ; get that tile
                nop
                compare r1,r1,TILE_PLAYER                           ; looking for a boulder or gem landing on player
                nop
                branch.eq .hitplayer                                ; boulder moved into space above player; he is dead
                branch .foundcontinue                               ; back to look for more
.thingonboulder:add r4,r3,r5                                        ; look at tile to the right/left
                nop
                load.bu r2,r4(r12)                                  ; load that tile
                nop
                compare r2,r2,TILE_BLANK                            ; looking for empty
                nop
                branch.ne .foundcontinue                            ; done if not empty
                copy r3,r4                                          ; found an empty, so set new pos
                branch .done
.hitplayer:     loadi.u r1,TILE_BLANK                               ; clearing the space where object was
                nop
                store.b r3(r12),r1                                  ; clear original space
                callbranch r14,playerdead                           ; player is dead now
                branch .foundcontinue                               ; when done burying the player, back to gravity

; playerdead - oh dear, sound tone, reduce the lives, update the status display and halt if lives is zero now
playerdead:     loadi.u r1,0x8000
                loadi.u r2,0x4000
                store.l TONEGEN_PERIOD_OF(r11),r1
                load.wu r1,lives_left-vars(r13)                     ; load lives left
                store.l TONEGEN_DURATION_OF(r11),r2                 ; sound death tone
                mulu r2,r1,4                                        ; turn it into a long address in r2
                sub r1,r1,1                                         ; reduce lives by one (r1)
                loadi.u r3,TILE_STATUS_DEAD_PLAYER                  ; get the crossed out player tile
                store.w lives_left-vars(r13),r1                     ; save lives in the global var
                store.b r2(r10),r3                                  ; update status bar
                branch.eq .nolivesleft                              ; looking for now having zero lives
                load.wu r1,new_life_pos-vars(r13)                   ; get the starting player pos for this level
                nop
                store.w player_pos-vars(r13),r1                     ; reset starting position for player
                jump r14
.nolivesleft:   halt                                                ; TODO: currently requires a full board restart

; animater - called every n'th frame to make gems sparkle and move bats
animater:       load.bu r4,bat_tile_match-vars(r13)                 ; don't animate the same bat twice; top bit is toggled
                nop                                                 ; to make sure this can't happen
                xor r1,r4,0x80                                      ; flip it for next time
                loadi.u r0,(WIDTH*4*HEIGHT)-4                       ; start at bottom right
                store.b bat_tile_match-vars(r13),r1                 ; save it
.loop:          load.bu r1,r0(r12)
                nop
                and r2,r1,0xfc                                      ; mask out lower (anim frame) bits
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
.gem:           add r1,r1,0x01                                      ; next animation frame
                nop
                and r1,r1,TILE_GEM|0x03                             ; mask out so it doesn't wrap
                nop
                store.b r0(r12),r1
                branch .continue
; r0=original pos, r1=tile, r2=bat direction, r3=whats at new tile/what we are writing, r4=
.bat:           and r2,r1,0x03                                      ; get direction
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
                nop
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
.rotate:        add r1,r1,0x01                                      ; rotate!
                copy r2,r0                                          ; not moving
                and r1,r1,0x03
                nop
                or r1,r1,TILE_BAT
                branch .draw

scrolling:      load.wu r0,player_pos-vars(r13)                      ; get current position in tile memory
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
                compare r3,r3,(31-14)*WIDTH*4
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
.setvbottom:    loadi.u r3,(32-14)*WIDTH*4
                branch .scrollv

drawplayer:     load.wu r0,player_pos-vars(r13)                      ; get current position in tile memory
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

loadlevel:      sub r15,r15,4
                nop
                store.l 0(r15),r14                                  ; save current return address
                load.wu r1,current_level-vars(r13)                  ; get current level
                loadi.u r0,0
                nop
                store.b I2C_CONTROL_OF(r11),r0                      ; clear last byte
                loadi.u r0,EEPROM_DEVICE_ADDRESS
                nop
                store.b I2C_ADDRESS_OF(r11),r0
                callbranch r14,i2cwaitnotbusy
                branch.ne nack
                mulu r1,r1,1024
                nop
                logicright r0,r1,8                                  ; take bits 15:8
                nop
                store.b I2C_WRITE_OF(r11),r0
                callbranch r14,i2cwaitnotbusy
                branch.ne nack
                store.b I2C_WRITE_OF(r11),r1
                callbranch r14,i2cwaitnotbusy
                branch.ne nack
                loadi.u r0,EEPROM_DEVICE_ADDRESS | 0x80             ; read
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

tfp410_init:    sub r15,r15,4
                nop
                store.l 0(r15),r14                                  ; save current return address

                loadi.u r1,tfp_reg_start
                loadi.u r2,tfp_reg_end-tfp_reg_start

.loop:          loadi.u r0,0
                nop
                store.b I2C_CONTROL_OF(r11),r0                      ; clear last byte
                loadi.u r0,TFP410_DEVICE_ADDRESS
                nop
                store.b I2C_ADDRESS_OF(r11),r0
                callbranch r14,i2cwaitnotbusy
                branch.ne nack
                load.bu r0,(r1)
                nop
                add r1,r1,1
                nop
                store.b I2C_WRITE_OF(r11),r0
                callbranch r14,i2cwaitnotbusy
                branch.ne nack
                loadi.u r0,0x80
                nop
                store.b I2C_CONTROL_OF(r11),r0                     ; set last byte
                load.bu r0,(r1)
                nop
                add r1,r1,1
                nop
                store.b I2C_WRITE_OF(r11),r0
                callbranch r14,i2cwaitnotbusy
                branch.ne nack

                sub r2,r2,2
                nop
                branch.ne .loop

                load.l r14,0(r15)
                add r15,r15,4
                jump r14

; returns with zero clear if nack'd
i2cwaitnotbusy: load.bs r0,I2C_STATUS_OF(r11)                       ; get the current status
                nop
                test r0,r0
                nop
                branch.mi i2cwaitnotbusy                            ; loop back if busy is set
                and r0,r0,0x40                                      ; test the ack status while here
                jump r14

; skelstatus - fill in a basic status line
skelstatus:     loadi.u r2,status_end-vars                          ; source of tile data
                loadi.u r1,20*4                                     ; counting down on this
.loop:          sub r2,r2,1                                         ; move down source
                sub r1,r1,4                                         ; move down destination
                load.bu r0,r2(r13)                                  ; get byte from source using r13 (vars) as base
                nop
                store.b r1(r10),r0                                  ; save byte into status using r10 (status) as base
                branch.ne .loop                                     ; back for more?
                jump r14                                            ; return

; newgame - sets lives to maximum and level number to zero
newgame:        loadi.u r0,5
                loadi.u r1,0
                store.w lives_left-vars(r13),r0
                store.w current_level-vars(r13),r1
                jump r14

; newlevel - copies the current level table entry into the vars, stashes the new level player position from the level
; data, and clears the exit open flag. does not: increment curernt level or load new level from eeprom.
newlevel:       sub r15,r15,4                                       ; making room on stack for ret addr
                load.wu r0,current_level-vars(r13)                  ; get current level number
                store.l 0(r15),r14                                  ; saves ret addr on stack
                mulu r0,r0,LEVEL_SIZE                               ; multiple level number by size of level struct
                nop
                add r0,r0,levels                                    ; add the start of the levels table to r0 (src)
                nop
                load.wu r1,LEVEL_PLAYER_POS(r0)                     ; get the new life player position
                nop
                store.w new_life_pos-vars(r13),r1                   ; save the new live player postion
                loadi.u r1,player_pos                               ; player_pos is the start of the vars (dst)
                loadi.u r2,LEVEL_SIZE                               ; we need this number of bytes
                callbranch r14,copywords                            ; copy from src to dst
                loadi.u r0,0                                        ; clearint the exit open flag
                nop
                store.w exit_open-vars(r13),r0                      ; clear it
                load.l r14,0(r15)                                   ; get ret addr
                add r15,r15,4                                       ; shrink stack
                jump r14

; utility

; r0=source, r1=dest, r2=count of words
copywords:      sub r2,r2,2
                nop
                load.wu r3,r2(r0)
                nop
                store.w r2(r1),r3
                branch.ne copywords
                jump r14

                #res 32
stack:

vars:

; copied from level at start of level
player_pos:     #d16 0
gems_needed_100:#d16 0
gems_needed_10: #d16 0
gems_needed_1:  #d16 0
exit_pos:       #d16 0
; regular variables
exit_open:      #d16 0                                              ; 1 for exit to next level is open
last_key:       #d16 0                                              ; last scan code (used for ignoring key up)
lives_left:     #d16 0                                              ; obviously lives left
current_level:  #d16 0                                             ; ...
new_life_pos:   #d16 0                                              ; where to start when dying on current level

; descriptor (struct) for a level
LEVEL_PLAYER_POS=0                                                  ; starting position for player
LEVEL_GEMS_NEEDED_HUNDREDS=2                                        ; gems needed 100s
LEVEL_GEMS_NEEDED_TENS=4                                            ; gems needed 10s
LEVEL_GEMS_NEEDED_UNITS=6                                           ; gems needed 1s
LEVEL_EXIT_POS=8                                                    ; position of exit
LEVEL_SIZE=10

levels:         #d16 (1*4)+(1*WIDTH*4)
                #d16 0
                #d16 2
                #d16 0
                #d16 (1*4)+(30*WIDTH*4)

                #d16 (1*4)+(25*WIDTH*4)
                #d16 0
                #d16 1
                #d16 0
                #d16 (30*4)+(1*WIDTH*4)

                #d16 (16*4)+(16*WIDTH*4)
                #d16 0
                #d16 1
                #d16 0
                #d16 (1*4)+(1*WIDTH*4)

; position of tiles on the status row
STATUS_GEM_HUNDREDS=9*4
STATUS_GEM_TENS=10*4
STATUS_GEM_UNITS=11*4

STATUS_LEVEL=18*4

; used to hold the look of the status line before starting play
status_start:   #d8 TILE_STATUS_BLANK
                #d8 TILE_STATUS_PLAYER
                #d8 TILE_STATUS_PLAYER
                #d8 TILE_STATUS_PLAYER
                #d8 TILE_STATUS_PLAYER
                #d8 TILE_STATUS_PLAYER
                #d8 TILE_STATUS_BLANK
                #d8 TILE_STATUS_BLANK
                #d8 TILE_STATUS_GEM
                #d8 TILE_STATUS_BLANK
                #d8 TILE_STATUS_BLANK
                #d8 TILE_STATUS_BLANK
                #d8 TILE_STATUS_GEM
                #d8 TILE_STATUS_BLANK
                #d8 TILE_STATUS_BLANK
                #d8 TILE_STATUS_LEVEL1
                #d8 TILE_STATUS_LEVEL2
                #d8 TILE_STATUS_BLANK
                #d8 TILE_STATUS_BLANK
                #d8 TILE_STATUS_BLANK
status_end:

; the next animation bat tile - the top bit is toggled on each animation frame so we don't move the same bat twice
bat_tile_match: #d8 TILE_BAT

tfp_reg_start:
                #d8 0x08
                #d8 0b00110101                                      ; ctl_1_mode
                #d8 0x09
                #d8 0b00111000                                      ; ctl_2_mode
                #d8 0x0a
                #d8 0b10000000                                      ; ctl_3_mode
                #d8 0x32
                #d8 0b00000000                                     ; de_dly
                #d8 0x33
                #d8 0b00000000                                     ; de_ctl
tfp_reg_end:
