;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; STARSAVE
;
; Parses filename then resumes execution of the BIOS' save routine.
;
STARSAVE:
   jsr  read_filename       ; copy filename into $140
   jsr  $f844               ; set $c9\a = $140, set x = $c9
   jmp  $fabe               ; scan parameters and jmp through SAVVEC



;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; SAVVEC
;
; 0,x = file parameter block
;
; 0,x = file name string address
; 2,x = data reload address
; 4,x = data execution address
; 6,x = data start address
; 8,x = data end address + 1
;
ossavecode:
   jsr  $f84f               ; copy data block at $00,x to COS workspace at $c9

   OPEN_WRITE              ; returns with any error in A

   and   #$3f
   beq   @continue

   cmp   #$08              ; FILE EXISTS
   beq   @askover   

   jmp   expect64orless    ; other kind of error

@askover:
   jsr   overwrite

   pha
   jsr   OSCRLF
   pla
   cmp   #'Y'
   beq   @preparetocont

   rts

@preparetocont:
   DELETE_FILE

   OPEN_WRITE
   jsr   expect64orless

@continue:
   lda   SLOAD           ; tag the file info onto the end of the filename data
   sta   $150
   lda   SLOAD+1
   sta   $151
   lda   SEXEC
   sta   $152
   lda   SEXEC+1
   sta   $153
   sec
   lda   SEND+1
   sbc   SSTART+1
   sta   $155
   lda   SEND
   sbc   SSTART
   sta   $154

   ldx   #$ff          ; zero out any data after the name at $140

@mungename:
   inx
   lda   NAME,x
   cmp   #$0d
   bne   @mungename

   lda   #0

@munge2:
   sta   NAME,x
   inx
   cpx   #16
   bne   @munge2

   jsr   write_info         ; write the ATM header

   jsr   write_file         ; save the main body of data

   CLOSE_FILE

   bit   MONFLAG             ; 0 = mon, ff = nomon
   bmi   @noprint

   ldx   #5
   
@cpydata:
   lda   $150,x
   sta   LLOAD,x
   dex
   bpl   @cpydata
   
   jsr   print_fileinfo

@noprint:
   jmp   OSCRLF





overwrite:
   jsr   STROUT
   .byte "OVERWRITE (Y):"
   nop

   jsr   OSRDCH
   jmp   OSWRCH