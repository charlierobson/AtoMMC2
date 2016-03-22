;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *INFO [filename]
;
; Shows metadata associated with the specified file.
;
star_info:
   lda   #0                     ; load address is not set
   sta   LEXEC

   jsr   read_filename
   jsr   open_file_read         ; invokes error handler if return code > 64
   jsr   read_info
   jsr   print_filename
   jmp   print_fileinfo
