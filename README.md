# Miniwedge for VIC-20 and C64

Miniwedge is a library for [cc65](https://cc65.github.io/) compiler suite
to ease the use of a Commodore disk drive.

# Commands

|Wedge command|Description|
|---|---|
|@|Display current drive error status|
|@"CMD"|Execute a disk drive command CMD|
|@"$"|Display the disk directory|
|@"$:PATTERN"|Display the disk directory of files matching PATTERN|

# Using library

## Compile library

Makefile is provided for Linux. Add correct `target` parameter depending on
your platform.

```
        make target=vic20
        make target=c64
```

## Import/export needed symbols

```
        .import miniwedge_install
        .import miniwedge_uninstall
        .import miniwedge_banner
        .import fkey_install
        .import fkey_uninstall

        .export keydef_f1
        .export keydef_f2
        .export keydef_f3
        .export keydef_f4
        .export keydef_f5
        .export keydef_f6
        .export keydef_f7
        .export keydef_f8
```

## Init library and display banner

```
        jsr     miniwedge_init
        lda     #<miniwedge_banner
        ldy     #>miniwedge_banner
        jsr     PTRSTR
        jsr     fkey_install
        rts
```

## Function key definitions

```
keydef_f1:
        ; Clear screen and display directory
        .byte 147, "@",34,"$",34,255
        .byte 0
keydef_f2:
        .byte "f2"
        .byte 0
keydef_f3:
        .byte "f3"
        .byte 0
keydef_f4:
        .byte "f4"
        .byte 0
keydef_f5:
        .byte "f5"
        .byte 0
keydef_f6:
        .byte "f6"
        .byte 0
keydef_f7:
        .byte "f7"
        .byte 0
keydef_f8:
        .byte "f8"
        .byte 0
```
