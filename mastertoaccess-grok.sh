#!/bin/bash

# Convert directory tree with JP2 lossless master images to  lossy access JP2s
# Requires: 
# - Grok
# - ExifTool
# - jprofile

if [ "$#" -ne 2 ] ; then
  echo "Usage: mastertoaccess-grok.sh dirIn dirOut" >&2
  exit 1
fi

# Input and output directories
dirIn="$1"
dirOut="$2"

if ! [ -d "$dirIn" ] ; then
  echo "input directory does not exist" >&2
  exit 1
fi

if ! [ -d "$dirOut" ] ; then
  mkdir "$dirOut"
fi

dirAccess="$dirOut"/access

if ! [ -d "$dirAccess" ] ; then
  mkdir "$dirAccess"
fi

# Log file (used too store Grok stdout, stderr)
logFile=$dirOut/mastertoaccess-grok.log

# Grok status file (used to store Kakadu exit status)
grokStatusFile=$dirOut/grokStatus.csv

# Remove log and status files if they exist already (writing done in append mode!)
if [ -f $logFile ] ; then
  rm $logFile
fi

if [ -f $grokStatusFile ] ; then
  rm $grokStatusFile
fi

# Codestream comment string for access images
cCommentAccess="KB_ACCESS_LOSSY_01/01/2015"

# Iterate over all files in dirIn and convert JP2s
# to TIFF, then convert those TIFFs to lossy JP2
# according to KB access specs.

while IFS= read -d $'\0' file ; do

    # File basename, extension removed
    bName=$(basename "$file" | cut -f 1 -d '.')
    
    # Output names
    outNameTIF=$bName.tif
    outNameJP2=$bName.jp2

    # Input path
    inPath=$(dirname "$file")

    # Full paths to output files
    tifOut="$dirAccess/$outNameTIF"
    jp2Out="$dirAccess/$outNameJP2"

    # First convert master JP2 to TIFF
    cmdDecompress="grk_decompress -i "$file"
          -o "$tifOut"
          -W "$logFile""

    $cmdDecompress
    grokDecompressStatus=$?
    echo $tifOut,$grokDecompressStatus >> $grokStatusFile

    # Convert TIFF to lossy access JP2 according to KB specs
    # Note: XMP metadata are written to UUID box, whereas KB
    # specs prescribe XML box. Don't think this is a problem
    # for access images. 
    cmdCompress="grk_compress -i "$tifOut"
           -o "$jp2Out"
           -I
           -n 6
           -p RPCL
           -t 1024,1024
           -b 64,64
           -c [256,256],[256,256],[128,128],[128,128],[128,128],[128,128]
           -r 2560,1280,640,320,160,80,40,20
           -S
           -E
           -M 32
           -C "$cCommentAccess"
           -W "$logFile""

    $cmdCompress
    grokCompressStatus=$?
    echo $jp2Out,$grokCompressStatus >> $grokStatusFile

    # Remove TIFF file
    rm $tifOut

done < <(find $dirIn -type f -regex '.*\.\(jp2\|JP2\)' -print0)

# Run jprofile
jprofile -p kb_300Colour_2014.xml $dirAccess jprofile-grok