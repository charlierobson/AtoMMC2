;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *LOAD [filename] ([address])
;
; Loads specified file to memory. If reload address is specified then this will be
; used in preference to the reload address stored in the file's metadata.
;
star_load:
   jsr   read_filename          ; copy filename into $140
   jsr   $f844                  ; set $c9\a = $140, set x = $c9
   jmp   $f95b                  ; *LOAD+3


; LODVEC entry point
;
; 0,x = file parameter block
;
; 0,x = file name string address
; 2,x = data dump start address
; 4,x  if bit 7 is clear, then the file's own start address is to be used
;
osloadcode:
   ; transfer control block to $c9 (LFNPTR) onward and check name
   ;
   jsr   copy_name              ; copy data block at $00,x to COS workspace at $c9
                                ; also checks filename is < 14 chars, PIC additionally checks < 8 chars
                                ; copy filename from ($c9) to $140

   jsr   open_file_read         ; invokes error handler if return code > 64
   jsr   read_info

   ; @@TUBE@@
   ; Test if the tube is enabled, then claim and initiate transfer
   ldx   #LLOAD                 ; block containing transfer address
   ldy   #1                     ; transfer type
   jsr   tube_claim_wrapper

   bit   MONFLAG                ; 0 = mon, ff = nomon
   bmi   @noprint

   jsr   print_fileinfo

@noprint:
   jsr   read_file

   ; @@TUBE@@
   ; Test if the tube is enabled, then release
   jmp   tube_release_wrapper


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *RLOAD [filename] [address]
;
; Load specified file to memory starting at the specified address. The file's FAT
; file system length is used, and any ATM metadata is read as part of the file.
;
;star_rload:
;  jsr   read_filename          ; copy filename into $140
;  jsr   $f844                  ; set $c9\a = $140, set x = $c9
;
;  ldx   #$cb                   ; Point to the vector at #CB, #CC
;  jsr   RDOPTAD                ; ..and interpret the load address to store it here
;  beq   rlerr                  ; ..can't interpret load address - error
;
;  jsr   COSPOST                ; Do COS interpreter post test
;  ldx   #$c9                   ; File data starts at #C9
;
;  jsr   CHKNAME
;  jsr   open_filename_getinfo  ; opens the filename for reading, and calls getinfo
;
;  lda   NAME                   ; fat file length
;  sta   LLENGTH
;  lda   NAME+1
;  sta   LLENGTH+1
;
;  jmp   read_file
;
;rlerr:
;  jmp   COSSYN
;
;
;nomemerr:
;  REPERROR noramstr
;
;
;noramstr:
;  .byte "NO RAM"
;  nop
;
;
;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *ROMLOAD [filename]
;
; Requires RAMOTH RamRom board with firmware giving read access to the option latch.
; Ensures 4k bank at $7000 is present in memory map then loads the specified file
; there. Sets utility ROM to bank 0 (redundant, possibly) pages $70 to $a0 and
; waits for break.
;
;star_romload:
;  lda   $bffd                  ; map $7000-$7fff to $7000 - needs ramrom with latest CPLD code
;  and   #$fe
;
;  lda #0
;
;  sta   $bffe                  ; ensure there's RAM at 7000
;  ora   #1                     ; for 'selectrom' code later
;  sta   $cc
;
;  lda   #$55
;  sta   $7000
;  cmp   $7000
;  bne   nomemerr
;  asl   a
;  sta   $7000
;  cmp   $7000
;  bne   nomemerr
;
;  jsr   read_filename          ; copy filename into $140
;  jsr   $f844                  ; set $c9\a = $140, set x = $c9
;  ;jsr   CHKNAME
;  jsr   open_file_read         ; invokes error handler if return code > 64
;
;  lda   #0
;  sta   LLOAD
;  sta   LLENGTH
;
;  sta   $cb
;
;  lda   #$10
;  sta   LLENGTH+1
;  lda   #$70
;  sta   LLOAD+1
;
;  jsr   read_file
;
;  ; cb = rom num for bfff
;  ; cc = option latch at bffe
;  ;
;  jmp   selectrom
