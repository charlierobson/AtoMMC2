;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *[file name]
;
; Synonymous with *RUN.
;
STARARBITRARY:
   ldy   #0                  ; copy filename up to NAME buffer

@copyname:
   lda   $100,y
   sta   NAME,y
   iny
   cmp   #$0d
   bne   @copyname

   jmp   runname



;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *RUN [filename]
;
; Try to execute the program with the specified name. If it's a BASIC program
; with an execution address of C2B2 then execute a 'RUN' command at return.
;
STARRUN:
    jsr  read_filename       ; copy filename into $140

runname:
   lda   MONFLAG
   pha
   lda   #$ff
   sta   MONFLAG
   jsr   $f844               ; set $c9\a = $140, set x = $c9
   jsr   $f95b
   pla
   sta   MONFLAG

   lda   LEXEC               ; if this is a non-auto-running basic program
   cmp   #$b2
   bne   @runit
   lda   LEXEC+1
   cmp   #$c2
   bne   @runit

   lda   #<@runcmd
   sta   $5
   lda   #>@runcmd
   sta   $6
   jmp   $c2f2

@runit:
   jmp   (LEXEC)


@runcmd:
   .byte "RUN",$0d