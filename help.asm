;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *HELP
;
; Shows some info
;
star_help:

   ldy   #(version_long - version)
   jsr   print_version

   jsr   STROUT
   .byte 10, 13, "INTERFACE F/W VERSION "
   ; NOP not needed, as next opcode is > 0x80

   lda   #CMD_GET_FW_VER
   jsr   fast_cmd
   jsr   ndotn

   jsr   STROUT
   .byte 10, 13, "BOOTLOADER VERSION "
   ; NOP not needed, as next opcode is > 0x80

   lda   #CMD_GET_BL_VER
   jsr   fast_cmd
   jsr   ndotn

   ; read and display card type
   ;
   jsr   STROUT
   .byte 10, 13, "CARD TYPE: "
   ; NOP not needed, as next opcode is > 0x80

   lda   #CMD_GET_CARD_TYPE
   jsr   slow_cmd

   jsr   bittoindex
   ldy   #4

@sctloop:
   lda   cardtypes,x
   cmp   #$20
   beq   @skipwhite
   jsr   OSWRCH
@skipwhite:
   inx
   dey
   bne   @sctloop

   jmp   OSCRLF

ndotn:
   pha
   lsr   a
   lsr   a
   lsr   a
   lsr   a
   jsr   $f80b                  ; print major version
   lda   #'.'
   jsr   OSWRCH
   pla
   jmp   $f80b                  ; print minor version
