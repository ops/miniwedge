;;;
;;; miniwedge
;;;
;;; September 2020 ops
;;;

        .include "cbm_kernal.inc"

        .ifdef  __C64__
        .include "c64.inc"
        GONE      := $A7E4
        PRNTCRLF  := $AAD7
        PRNTSPC   := $AB3F
        PRTFIX    := $BDCD
        SCRNOUT   := $E716
        NEWSTT    := $A7AE
        DELST     := $B6A3
        FRMEVL    := $AD9E
        SETKEYS   := $EB48
        SYNPRT    := $EA13
        .endif

        .ifdef  __VIC20__
        .include "vic20.inc"
        GONE      := $C7E4
        PRNTCRLF  := $CAD7
        PRNTSPC   := $CB3F
        PRTFIX    := $DDCD
        SCRNOUT   := $E742
        NEWSTT    := $C7AE
        DELST     := $D6A3
        FRMEVL    := $CD9E
        SETKEYS   := $EBDC
        SYNPRT    := $EAA1
        .endif

        .segment "MINIWEDGE"

        .export miniwedge_install
        .export miniwedge_uninstall
        .export miniwedge_banner
        .export fkey_install
        .export fkey_uninstall

        .import keydef_f1
        .import keydef_f2
        .import keydef_f3
        .import keydef_f4
        .import keydef_f5
        .import keydef_f6
        .import keydef_f7
        .import keydef_f8


CHRGET          = $73           ; get next char
CHRGOT          = $79           ; get char
INDEX           = $22           ; pointer
LSTX            = $C5           ; current key
SFDX            = $CB           ; which key
CDBLN           = $CE           ; character under cursor
BLNON           = $CF           ; cursor blink phase
INSRT           = $D8           ; insert mode


GDCOL           := $0287        ; colour under cursor
SHFLAG          := $028D        ; SHIFT/CTRL/C=
KEYLOG          := $028F
IGONE           := $0308


;
; PETSCII charactes
;

CH_RET          = $0D
CH_ARROW_L      = $5F


miniwedge_install:
        lda     #<miniwedge_gone
        sta     IGONE
        lda     #>miniwedge_gone
        sta     IGONE+1
        rts


miniwedge_uninstall:
        lda     #<GONE
        sta     IGONE
        lda     #>GONE
        sta     IGONE+1
        rts


fkey_install:
        lda     #<fkey_handler
        sta     KEYLOG
        lda     #>fkey_handler
        sta     KEYLOG+1
        rts


fkey_uninstall:
        lda     #<SETKEYS
        sta     KEYLOG
        lda     #>SETKEYS
        sta     KEYLOG+1
        rts


miniwedge_gone:
        jsr     CHRGET
        php
        cmp     #'@'
        beq     drive_cmd
dirnam: cmp     #'$'
        beq     directory
        plp
        jmp     GONE+3


.proc drive_cmd
        plp
        jsr     CHRGET
        beq     drive_status
        jsr     FRMEVL          ; evaluate expression
        jsr     DELST           ; evaluate string
        tay
        beq     drive_status
        sta     INDEX+2         ; store cmd length
        ; Send command
        lda     DEVNUM
        jsr     LISTEN
        lda     #$6F
        jsr     SECOND
        ldy     #$00
:       lda     (INDEX),y
        jsr     CIOUT
        iny
        cpy     INDEX+2
        bne     :-
        jsr     UNLSN
        ; Discard the rest of the line
        jsr     CHRGOT
        beq     @out
:       jsr     CHRGET
        bne     :-
@out:   jmp     NEWSTT
.endproc


.proc drive_status
        ; Check that drive is present
        lda     #$00
        sta     STATUS
        lda     DEVNUM
        jsr     LISTEN
        lda     #$6F
        jsr     SECOND
        jsr     UNLSN
        lda     STATUS
        bne     @out
        ; Get status line
        lda     DEVNUM
        jsr     TALK
        lda     #$6F
        jsr     TKSA
:       lda     STATUS
        bne     @eof
        jsr     ACPTR
        jsr     CHROUT
        jmp     :-
@eof:   jsr     UNTLK
@out:   jmp     NEWSTT
.endproc


.proc directory
        plp
        jsr     CHRGET
        jsr     dodir
        jsr     CLRCHN
        jmp     NEWSTT
.endproc

        ; Display disk directory
.proc dodir
        lda     #$01
        ldx     #<(dirnam+1)
        ldy     #>(dirnam+1)
        jsr     SETNAM
        ldx     DEVNUM
        ldy     #$00
        jsr     SETLFS
        jsr     OPEN
        bcs     @out
        jsr     PRNTCRLF
        ldx     #$01
        jsr     CHKIN
        ldx     #4
@readline:
:       jsr     CHRIN
        ldy     STATUS
        bne     @out
        dex
        bpl     :-

        tax
        jsr     CHRIN
        jsr     PRTFIX
        jsr     PRNTSPC

        jsr     CHRIN
@next:  ldy     STATUS
        bne     @out
        cmp     #CH_RET
        beq     @cnvrt
        cmp     #141            ; SHIFT+RET
        bne     @skip
@cnvrt: lda     #CH_ARROW_L
@skip:  jsr     CHROUT
        inc     INSRT
        jsr     CHRIN
        bne     @next

        jsr     PRNTCRLF
        jsr     STOP
        beq     @out
        ldx     #2
        bne     @readline

@out:   lda     #$01
        jmp     CLOSE
.endproc


.proc fkey_handler
        ldx     #$03            ; number of keys - 1
        lda     SFDX            ; get which key
:       cmp     fkeycodes,x     ; compare with function key
        beq     :+
        dex                     ; decrement index
        bpl     :-              ; loop for all function keys
@out:   jmp     SETKEYS
:       cmp     LSTX            ; compare with last key
        beq     @out            ; if equal then exit
        sta     LSTX
        txa
        asl
        tax
        lda     SHFLAG
        lsr
        bcc     :+
        inx
:       lda     offsets,x
        pha
        lda     #$00
        sta     BLNON           ; clear cursor blink phase
        lda     CDBLN           ; get character under cursor
        ldx     GDCOL           ; get colour under cursor
        jsr     SYNPRT
        pla
        tay
@loop:  lda     keydef_f1,y
        beq     @out
        cmp     #255
        beq     @handle_return
        jsr     CHROUT
        iny
        bne     @loop
@handle_return:
        ldx     KEY_COUNT
        inc     KEY_COUNT
        lda     #CH_RET
        sta     $0277,x
        iny
        bne     @loop

fkeycodes:
        .ifdef  __C64__
          .byte $04,$05,$06,$03
        .endif

        .ifdef  __VIC20__
          .byte $27,$2F,$37,$3F
        .endif

offsets:
        .byte <(keydef_f1-keydef_f1)
        .byte <(keydef_f2-keydef_f1)
        .byte <(keydef_f3-keydef_f1)
        .byte <(keydef_f4-keydef_f1)
        .byte <(keydef_f5-keydef_f1)
        .byte <(keydef_f6-keydef_f1)
        .byte <(keydef_f7-keydef_f1)
        .byte <(keydef_f8-keydef_f1)
.endproc


miniwedge_banner:
        .ifdef  __C64__
          .byte "         *** miniwedge v1.0 ***", CH_RET
          .byte 0
        .endif

        .ifdef  __VIC20__
          .byte " ** miniwedge v1.0 **", CH_RET
          .byte 0
        .endif
