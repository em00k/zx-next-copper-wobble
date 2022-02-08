; em00k 2021 
; there may be some droplets not used 

        SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
        DEVICE ZXSPECTRUMNEXT
        CSPECTMAP "test.map"

        org  $8000

main:

TBBLUE_REGISTER_SELECT_P_243B   EQU $243B

LAYER2_RAM_BANK_NR_12           EQU $12
TURBO_CONTROL_NR_07             EQU $7
LAYER2_XOFFSET_NR_16            EQU $16
LAYER2_YOFFSET_NR_17            EQU $17 
VIDEO_LINE_LSB_NR_1F            EQU $1F 
COPPER_DATA_NR_60               EQU $60 
COPPER_CONTROL_LO_NR_61         EQU $61
COPPER_CONTROL_HI_NR_62         EQU $62 
DISPLAY_CONTROL_NR_69           EQU $69 

    nextreg LAYER2_RAM_BANK_NR_12,12
    nextreg TURBO_CONTROL_NR_07,3
    nextreg DISPLAY_CONTROL_NR_69,1<<7 
    nextreg COPPER_CONTROL_LO_NR_61,0           
    nextreg COPPER_CONTROL_HI_NR_62,0           
    ; nextreg VIDEO_LINE_OFFSET_NR_64,31          

        ld      a,1 
        ld      (c_d),a             ; d = 1 
        
copper_wobble: 

        ld      a,2
        out     ($fe),a             ; red border 

        xor     a 
        ld      (c_l),a             ; l = 0     copper line 
        ld      a,(c_b)             
        ld      (c_e),a             ; e = b     y delta 
        ld      (c_x),a             ; x = b     x delta 
        

        ; c = 1+(peek(add+cast(uinteger,d))>>2)
        ; used to slide start position in sine data 

        ld      hl,sindata
        ld      a,(c_d)
        add     hl,a 
        ld      a,(hl)
        srl     a 
        srl     a 
        add     a,1 
        ld      (c_c),a 

        ld      b,0
    
cop_upload_loop:

        nextreg COPPER_DATA_NR_60,  128         ; wait %1000 0000
        ld      a,(c_l)
        
        nextreg COPPER_DATA_NR_60,a             ; line 

        ; i = peek(add+cast(uinteger,x))

        ld      hl,sindata                      ; x offset 
        ld      a,(c_x)
        add     hl,a 
        ld      a,(hl)
        ld      (c_i),a 

        ; write x offset 
        nextreg COPPER_DATA_NR_60,LAYER2_XOFFSET_NR_16
        ld      a,(c_i) 
        ; add     a,a 
        nextreg COPPER_DATA_NR_60,a

        ; j = peek(add+cast(uinteger,e))

        ld      hl,sindata
        ld      a,(c_e)
        add     hl,a 
        ld      a,(hl)
        ld      (c_j),a 

        ; write y offset 
        nextreg COPPER_DATA_NR_60,LAYER2_YOFFSET_NR_17
        ld      a,(c_j) 
        ld      h,a 
        ld      a,(c_c)             ; we will add c>>1 to j for a but more effect 
        srl     a 
        ;srl     a 
        
        add     a,h  
        ; srl     a 
        ; add     a,a 
        nextreg COPPER_DATA_NR_60,a

        ; inc variables 

        ld      hl,c_e              ; e = e + 1     increase y delta 
        inc     (hl) 
        ld      hl,c_l              ; l = l + 1     increase coppper line
        inc     (hl) 
        ld      hl,c_x              ; x = x + 1     increase x delta 
        inc     (hl) 

        djnz    cop_upload_loop     ; repeat for all copper line s

        nextreg COPPER_DATA_NR_60,%10000001         ; WAIT MSB 1 
        nextreg COPPER_DATA_NR_60,255               ; Inifite line 
        nextreg COPPER_CONTROL_LO_NR_61,0
        nextreg COPPER_CONTROL_HI_NR_62,%11000000

        ld      hl,c_e              ; e = e + 1     increase y delta 
        inc     (hl) 

        ld      hl,c_d              ; d = d + 1    
        inc     (hl) 

        ld      hl,c_c              ; b = b + c
        ld      a,(c_b)
        add     a,(hl)
        ld      (c_b),a 

        xor     a                   ; border 0 
        out     ($fe),a 

        call    wait_raster_line 

        jp      copper_wobble       ; repeat 


wait_raster_line:

        ld      a,VIDEO_LINE_LSB_NR_1F
        ld      bc,TBBLUE_REGISTER_SELECT_P_243B
        out     (c),a 
        inc     b   
        in      a,(c)
        cp      250                 ; wait for line 250
        jr      nz,wait_raster_line
        ret 


c_x:    db 0
c_i:    db 0 
c_b:    db 0 
c_l:    db 0 
c_c:    db 0
c_d:    db 1 
c_e:    db 16 
c_j:    db 0 


;------------------------------------------------------------------------------
; Stack reservation
STACK_SIZE      equ     100

stack_bottom:
        defs    STACK_SIZE * 2
stack_top:
        defw    0

sindata:
    ; 

        DUP 2
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        db 1,1,1,1,1,2,2,2,2,2,3,3,3,3,4,4
        db 4,4,5,5,5,6,6,6,6,7,7,7,8,8,8,9
        db 9,9,10,10,11,11,11,12,12,12,13,13,14,14,14,15
        db 15,15,16,16,17,17,17,18,18,19,19,19,20,20,20,21
        db 21,21,22,22,22,23,23,23,24,24,24,25,25,25,26,26
        db 26,26,27,27,27,27,28,28,28,28,28,29,29,29,29,29
        db 29,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30
        db 30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,29
        db 29,29,29,29,29,28,28,28,28,28,27,27,27,27,26,26
        db 26,26,25,25,25,24,24,24,23,23,23,22,22,22,21,21
        db 21,20,20,20,19,19,19,18,18,17,17,17,16,16,15,15
        db 15,14,14,14,13,13,12,12,12,11,11,11,10,10,9,9
        db 9,8,8,8,7,7,7,6,6,6,6,5,5,5,4,4
        db 4,4,3,3,3,3,2,2,2,2,2,1,1,1,1,1
        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        EDUP 

bmpimport:
        mmu     7 n, 24  
        org     $e000
        incbin  "tut.bmp", 1078

;------------------------------------------------------------------------------
; Output configuration
        SAVENEX OPEN "h:/copper_test.nex", main, stack_top 
        SAVENEX CORE 3,0,0
        SAVENEX CFG 7,0,0,0
        SAVENEX AUTO 
        SAVENEX CLOSE