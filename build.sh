#!/bin/bash

rm -f *.rom

BASE=atommc2-3.0

AVR_A000_ROM=${BASE}-a000-avr.rom
AVR_E000_ROM=${BASE}-e000-avr.rom
PIC_A000_ROM=${BASE}-a000-pic.rom
PIC_E000_ROM=${BASE}-e000-pic.rom


echo Assembling AVR
ca65 -l atomm2.a000.lst -o a000.o -DAVR atommc2.asm
ca65 -l atomm2.e000.lst -o e000.o -DAVR -D EOOO atommc2.asm

echo Linking AVR
ld65 a000.o -o ${AVR_A000_ROM} -C atommc2-a000.lkr
ld65 e000.o -o ${AVR_E000_ROM} -C atommc2-e000.lkr

echo Removing AVR object files
rm -f *.o

echo Assembling PIC
ca65 -l atomm2.a000.lst -o a000.o atommc2.asm
ca65 -l atomm2.e000.lst -o e000.o -D EOOO atommc2.asm

echo Linking PIC
ld65 a000.o -o ${PIC_A000_ROM} -C atommc2-a000.lkr
ld65 e000.o -o ${PIC_E000_ROM} -C atommc2-e000.lkr

echo Removing PIC object files
rm -f *.o

for i in ${AVR_A000_ROM} ${AVR_E000_ROM} ${PIC_A000_ROM} ${PIC_E000_ROM}
do
    truncate -s 4096 $i
done

mkdir -p AVR
mkdir -p PIC
rm -f AVR/*
rm -f PIC/*

xxd -r > AVR/ATMMC3A <<EOF
00: 41 54 4d 4d 43 33 41 00 00 00 00 00 00 00 00 00
10: 00 A0 00 A0 00 10
EOF
cat ${AVR_A000_ROM} >> AVR/ATMMC3A
mv  ${AVR_A000_ROM} AVR/ATMMC3A.rom
md5sum AVR/ATMMC3A.rom

xxd -r > AVR/ATMMC3E <<EOF
00: 41 54 4d 4d 43 33 45 00 00 00 00 00 00 00 00 00
10: 00 E0 00 E0 00 10
EOF
cat ${AVR_E000_ROM} >> AVR/ATMMC3E
mv  ${AVR_E000_ROM} AVR/ATMMC3E.rom
md5sum AVR/ATMMC3E.rom

xxd -r > PIC/ATMMC3A <<EOF
00: 41 54 4d 4d 43 33 41 00 00 00 00 00 00 00 00 00
10: 00 A0 00 A0 00 10
EOF
cat ${PIC_A000_ROM} >> PIC/ATMMC3A
mv  ${PIC_A000_ROM} PIC/ATMMC3A.rom
md5sum PIC/ATMMC3A.rom

xxd -r > PIC/ATMMC3E <<EOF
00: 41 54 4d 4d 43 33 45 00 00 00 00 00 00 00 00 00
10: 00 E0 00 E0 00 10
EOF
cat ${PIC_E000_ROM} >> PIC/ATMMC3E
mv  ${PIC_E000_ROM} PIC/ATMMC3E.rom
md5sum PIC/ATMMC3E.rom
