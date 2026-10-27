#!/bin/bash

# Convert directory tree with JP2 images to TIFF
# Requires: 
# - Openjpeg (opj_decompress)
# - ExifTool
# - tiffinfo
# - realpath


if [ "$#" -ne 2 ] ; then
  echo "Usage: jp2totiff-opj.sh dirIn dirOut" >&2
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

# Log file (used to store Kakadu and Exiftool stdout, stderr)
logFile=$dirOut/jp2totiff-opj.log

# OPJ status file (used to store OpenJPEG decompres exit status)
opjStatusFile=$dirOut/opjStatus.csv

# Checksum file
checksumFile=$dirOut/checksums.md5

# Remove log and checksum files if they exist already (writing done in append mode!)
if [ -f $logFile ] ; then
  rm $logFile
fi

if [ -f $opjStatusFile ] ; then
  rm $opjStatusFile
fi

if [ -f $checksumFile ] ; then
  rm $checksumFile
fi

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
    echo "*** OpenJPEG log: ***" >> $logFile

    # File basename, extension removed
    bName=$(basename "$file" | cut -f 1 -d '.')
    
    # Output name
    outName=$bName.tif

    # Input path
    inPath=$(dirname "$file")

    # Input path, relative to dirIn
    inPathRel=$(realpath --relative-to=$dirIn $inPath)

    # Full path to output file
    tiffOut="$dirOut/$inPathRel/$outName"

    # Full path to temporary file
    tiffTemp="$dirOut/$inPathRel/tmpjp2totiff.tif"

    # OpenJPEG command line
    opjCmd="opj_decompress -i "$file" -o "$tiffTemp""

    # Convert to TIFF
    $opjCmd >>$logFile 2>&1
    opjStatus=$?
    echo $tiffOut,$opjStatus >> $opjStatusFile

    echo "*** Exiftool log: ***" >> $logFile

    exiftool -o "$tiffOut" \
              -XResolution=300 \
              -YResolution=300 \
              -ResolutionUnit=inches \
              "$tiffTemp" >>$logFile 2>&1

    rm "$tiffTemp"

    # Compute MD5 checksum
    md5sum "$tiffOut" >> $checksumFile

    # Run TIFF through TIFFInfo, errors to log file
    echo "*** tiffinfo stderr: ***" >> $logFile
    tiffinfo -d "$tiffOut" 2>> $logFile >/dev/null

    echo "------" >> $logFile

done < <(find $dirIn -type f -regex '.*\.\(jp2\|JP2\)' -print0)
