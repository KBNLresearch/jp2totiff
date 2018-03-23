#!/bin/bash

# Demo script:
# - Convert several directory trees from JP2 to TIFF
# - From these TIFFs do a roundtrip conversion back to JP2
# - Verify if JP2s from roundtrip conversion meet KB requirements
#   using jprofile (https://github.com/KBNLresearch/jprofile)
# - power off the machine when finished

jp2totiff=~/ownCloud/jp2totiff/jp2totiff.sh
tifftojp2=~/ownCloud/jp2totiff/tifftojp2.sh

# Convert to TIFF
$jp2totiff /media/johan/Elements/MMUBWA03_000000001_1_01 MMUBWA03_000000001_1_01-TIFF
$jp2totiff /media/johan/Elements/MMKB18A_000000001_1_04 MMKB18A_000000001_1_04-TIFF

# Roundtrip conversion to JP2
$tifftojp2 MMUBWA03_000000001_1_01-TIFF MMUBWA03_000000001_1_01-JP2-roundtrip
$tifftojp2 MMKB18A_000000001_1_04-TIFF MMKB18A_000000001_1_04-JP2-roundtrip

# Analyse JP2s
jprofile -p kb_300Colour_2014.xml MMUBWA03_000000001_1_01-JP2-roundtrip MMUBWA03_000000001_1_01
jprofile -p kb_300Colour_2014.xml MMKB18A_000000001_1_04-JP2-roundtrip MMKB18A_000000001_1_04

# Power off the machine
poweroff
