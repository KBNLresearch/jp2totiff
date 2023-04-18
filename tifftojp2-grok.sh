#!/bin/bash

# Convert directory tree with TIFF images to JP2
# Requires: 
# - Grok
# - realpath

if [ "$#" -ne 2 ] ; then
  echo "Usage: tifftojp2-grok.sh dirIn dirOut" >&2
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

# Log file (used too store Grok stdout, stderr)
logFile=$dirOut/tifftojp2-grok.log

# Groku status file (used to store Grok exit status)
grokStatusFile=$dirOut/grokStatus.csv

# Checksum file
checksumFile=$dirOut/checksums.md5

# Remove log and checksum files if they exist already (writing done in append mode!)
if [ -f $logFile ] ; then
  rm $logFile
fi

if [ -f $grokStatusFile ] ; then
  rm $grokStatusFile
fi

if [ -f $checksumFile ] ; then
  rm $checksumFile
fi

# Codestream comment strings for master and access images
cCommentMaster="KB_MASTER_LOSSLESS_01/01/2015"
cCommentAccess="KB_ACCESS_LOSSY_01/01/2015"

# First clone the directory structure of dirIn to dirOut 

while IFS= read -d $'\0' -r directory ; do
    # Directory path, relative to dirIn
    dirInRel=$(realpath --relative-to=$dirIn $directory)

    # Absolute path to folder in output directory
    dirOutAbs=$dirOut/$dirInRel

    # Create folder in output directory
    mkdir -p $dirOutAbs
done < <(find $dirIn -type d -print0)

# Iterate over all files in dirIn and convert JP2s
# to TIFF, writing result to corresponding folder in dirout

while IFS= read -d $'\0' -r file ; do

    echo $file >> $logFile

    # File basename, extension removed
    bName=$(basename "$file" | cut -f 1 -d '.')
    
    # Output name
    outName=$bName.jp2

    # Input path
    inPath=$(dirname "$file")

    # Input path, relative to dirIn
    inPathRel=$(realpath --relative-to=$dirIn $inPath)

    # Full path to output file
    jp2Out="$dirOut/$inPathRel/$outName"

    # Convert TIFF to lossy access JP2 according to KB specs
    # Note: Grok writes XMP metadata UUID box, whereas KB
    # specs prescribe XML box!
    cmdCompress="grk_compress -i "$file"
           -o "$jp2Out"
           -n 6
           -p RPCL
           -t 1024,1024
           -b 64,64
           -c [256,256],[256,256],[128,128],[128,128],[128,128],[128,128]
           -r 2560,1280,640,320,160,80,40,20,10,5,1
           -S
           -E
           -M 32
           -C "$cCommentMaster"
           -W "$logFile""

    echo "*** grok log: ***" >> $logFile

    $cmdCompress >>$logFile 2>&1
    grokCompressStatus=$?
    echo $jp2Out,$grokCompressStatus >> $grokStatusFile
 
    #md5sum "$jp2Out" >> $checksumFile

    echo "------" >> $logFile

done < <(find $dirIn -type f -regex '.*\.\(tiff\|TIFF\|tif\|TIF\)' -print0)

