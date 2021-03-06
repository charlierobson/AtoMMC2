;================================================================
; Random Access File Handling
;================================================================

CMD_SEEK                   = $16
CMD_FILE_OPEN_RANDOM_READ  = $31
CMD_FILE_OPEN_RANDOM_WRITE = $37

STATUS_FILEHANDLE          = $60
STATUS_EOF                 = $60

;----------------------------------------------------------------
; OSFIND vector $218
;
; - Send INIT_READ/WRITE command
; - Send filename terminated with $0
; - Send FILE_OPEN_RANDOM_READ/WRITE command
; - Return file handle ($61,$62,$63) or 0 if error occured
;
; carry = 1 -> open file for reading (FIN)
;
;  Input:  X = pointer to filename
;
;  Output: File handle if file exists
;          0 if file does not exist
;
; carry = 0 -> open file for writing (FOUT)
;
;  Input:  X = pointer to filename
;
;  Output: File handle if file exists
;           If file does not exist, create new file
;
;----------------------------------------------------------------

osfindcode:
   php                          ; Save status

   lda   $00,x
   sta   LFNPTR
   lda   $01,x
   sta   LFNPTR+1
   ldy   #0
name_copy:
   lda   (LFNPTR),y
   sta   NAME,y
   iny
   cmp   #$0D
   bne   name_copy

   plp
   php
   bcs   raf_open_read          ; Jump if FIN

raf_open_write:                 ; Open file for writing
   lda   #CMD_FILE_OPEN_RANDOM_WRITE
   bne   raf1

raf_open_read:                  ; Open file for reading
   lda   #CMD_FILE_OPEN_RANDOM_READ
raf1:
   jsr   open_file              ; Open file
   cmp   #STATUS_FILEHANDLE+1   ; Check if filehandle ok
   bcs   open_ok                ; Existing file opened
open_nok:
   plp                          ; Get status
   bcs   open_in                ; C=1 is FIN; C=0 is FOUT
   jmp   expect64orless         ; If FOUT, return ERROR
open_in:
   lda   #0                     ; If FIN, return 0
   rts

open_ok:
   plp
   rts                          ; Return file handle in A

;----------------------------------------------------------------
; OSSHUT vector $21A
;
; Input:  Y = File handle
;             0 -> close all files
;----------------------------------------------------------------

osshutcode:
   pha                          ; Save A

   tya                          ; Set handle in A

   bne   shut_one               ; Shut one file

shut_all:
   ldy   #$61
   jsr   shut_file              ; Close file1
   ldy   #$62
   jsr   shut_file              ; Close file2
   ldy   #$63
shut_one:
   jsr   shut_file              ; Close file3

   pla                          ; Get A
   rts

shut_file:
   jsr   mul32handle            ; Command = 32*(file handle AND 3)
   adc   #CMD_FILE_CLOSE        ; Select CMD_FILE_CLOSE command file 1,2 or 3
   jmp   slow_cmd               ; Send command + wait

;----------------------------------------------------------------
; OSBPUT vector $216
;
; - Send INIT_WRITE command
; - Send databyte
; - Send number of bytes to send
; - Send WRITE_BYTES command
;
; Input:  Y = File handle
;         A = Byte
;
; Output: If 1<=file handle<=3 -> output to file
;         If file handle=0     -> output to screen
;----------------------------------------------------------------

osbputcode:
   pha                          ; Save databyte

   tya                          ; File handle in A
   beq   bput_zero_device       ; Check for screen output

   jsr   prepare_write_data     ; CMD_READ_WRITE

   pla
   jsr   write_data_reg         ; Save databyte

   lda   #1                     ; Set nr of bytes to send
   jsr   write_latch_reg        ; Wait

   jsr   mul4handle             ; Command=$21+4*file handle
   adc   #CMD_WRITE_BYTES
   jmp   slow_cmd_and_check     ; invokes error handler if return code > 64

bput_zero_device:
   pla                          ; Screen output
   jmp $ffe9

;----------------------------------------------------------------
; OSBGET vector $214
;
; - Send number of bytes to read
; - Send READ_BYTES command
; - Check if EOF reached
; - If not
; -   Send INIT_READ command
; -   Get databyte
; -   Clear carry
; - If yes
; -   Return $FF
; -   Set carry
;
; Input:  Y = File handle
;
; Output: A           = databyte -> carry cleared
;        $ff -> EOF reached -> carry set
;----------------------------------------------------------------

osbgetcode:
   tya                          ; Set handle in A
   beq   bget_zero_device       ; If file handle zero, output to screen

   lda   #1                     ; Set nr of bytes to send
   jsr   write_latch_reg        ; Wait

   jsr   mul4handle             ; Command=$22+4*file handle
   adc   #CMD_READ_BYTES        ; CMD_READ_BYTES
   jsr   slow_cmd               ; Send command + wait
   cmp   #STATUS_EOF            ; Check for EOF flag
   beq   set_eof_flag
   jsr   expect64orless         ; Check for errors
   jmp   read_byte              ; No errors, read byte

set_eof_flag:
   lda   #$ff                   ; EOF reached
   sec                          ; Return carry set
   rts

read_byte:
   jsr   prepare_read_data      ; CMD_INIT_READ
   jsr   read_data_reg          ; Read byte

   clc                          ; Return carry clear
   rts

bget_zero_device:
   jmp   $ffe6                  ; Return input from keyboard

;----------------------------------------------------------------
; OSRDAR vector $210
;
; - If A=0 the read PTR
; -
; - If A=1 the read EXT
; -   Send CMD_FILE_GETINFO command
; -   Send INIT_READ command
; -   Read 3 bytes from WRITEDATAREG in $52/53/54
;
; Input:  A = 0 -> Read PTR
;        1 -> Read EXT
;    Y = File handle
;
; Output: PTR or EXT in $52/53/54
;----------------------------------------------------------------

osrdarcode:
   pha                          ; Save A

   jsr   mul32handle            ; Command=$15+32*file handle
   adc   #CMD_FILE_GETINFO
   jsr   slow_cmd               ; Send command + wait

   jsr   prepare_read_data      ; CMD_INIT_READ

   jsr   rdar_cont              ; Read LOF

   pla
   bne   rdar_end               ; If EXT then end

   jsr   rdar_cont              ; Read sector
   jsr   rdar_cont              ; Read PTR
rdar_end:
   rts

rdar_cont:
   jsr   read_data_reg          ; Read data byte
   sta   $00,x
   jsr   read_data_reg          ; Read data byte
   sta   $01,x
   jsr   read_data_reg          ; Read data byte
   sta   $02,x
   jmp   read_data_reg          ; Read data byte

;----------------------------------------------------------------
; OSSTAR vector $212
;
; - Send INIT_WRITE command
; - Write 3 bytes from $52/53/54 to WRITE_DATA_REG
; - Send CMD_SEEKO command
;
; Input:  Y         = File handle, if 0 then ERROR
;    $52/53/54 = value
;
; Output: PTR = $52/53/54
;----------------------------------------------------------------

osstarcode:
   tya                          ; File handle in A
   beq   ptr_zero_device        ; Error if no file open

   jsr   prepare_write_data     ; CMD_INIT_WRITE

   lda   $00,x
   jsr   write_data_reg         ; Write databyte
   lda   $01,x
   jsr   write_data_reg         ; Write databyte
   lda   $02,x
   jsr   write_data_reg         ; Write databyte
   lda   #0
   jsr   write_data_reg         ; Write databyte

   jsr   mul32handle
   adc   #CMD_SEEK              ; Command=$16+32*file handle
   jmp   slow_cmd               ; Send command + wait

ptr_zero_device:
   brk

;----------------------------------------------------------------
; Command = 32*filenr
;----------------------------------------------------------------

mul32handle:
   tya
   and   #3
   asl   a
   asl   a
   asl   a
mul4:
   asl   a
   asl   a
   clc
   rts

;----------------------------------------------------------------
; Command = 4*filenr
;----------------------------------------------------------------

mul4handle:
   tya
   and   #3
   jmp   mul4
