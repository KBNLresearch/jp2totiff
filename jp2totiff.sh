#!/bin/bash

# Convert directory tree with JP2 images to TIFF
# Requires: 
# - Kakadu (kdu_expand)
# - ExifTool
# - tiffinfo
# - realpath


if [ "$#" -ne 2 ] ; then
  echo "Usage: jp2totiff.sh dirIn dirOut" >&2
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

# Location of Kakadu binaries
kduPath=~/kakadu

# Add Kakadu path to LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$kduPath

# Log file (used to store Kakadu and Exiftool stdout, stderr)
logFile=$dirOut/jp2totiff.log

# Kakadu status file (used to store Kakadu exit status)
kakaduStatusFile=$dirOut/kduStatus.csv

# Checksum file
checksumFile=$dirOut/checksums.md5

# Remove log and checksum files if they exist already (writing done in append mode!)
if [ -f $logFile ] ; then
  rm $logFile
fi

if [ -f $kakaduStatusFile ] ; then
  rm $kakaduStatusFile
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
    echo "*** Kakadu log: ***" >> $logFile

    # File basename, extension removed
    bName=$(basename "$file" | cut -f 1 -d '.')
    
    # Output name
    outName=$bName.tiff

    # Input path
    inPath=$(dirname "$file")

    # Input path, relative to dirIn
    inPathRel=$(realpath --relative-to=$dirIn $inPath)

    # Full path to output file
    tiffOut="$dirOut/$inPathRel/$outName"

    # Kakadu command line
    kduCmd="$kduPath/kdu_expand -i "$file"
            -o "$tiffOut""

    # Convert to TIFF
    $kduCmd >>$logFile 2>&1
    kakaduStatus=$?
    echo $tiffOut,$kakaduStatus >> $kakaduStatusFile

    echo "*** Exiftool log: ***" >> $logFile

    # Remove XMP tags, except xmp-tiff ones
    # Skipping this step results in not well-formed XML
    # in round-trip JP2 generation with Kakadu (uuidbox)
    exiftool -overwrite_original -xmp:all= "-all:all<xmp-tiff:all" "$tiffOut" >>$logFile 2>&1

    # Compute MD5 checksum
    md5sum "$tiffOut" >> $checksumFile

    # Run TIFF through TIFFInfo, errors to log file
    echo "*** tiffinfo stderr: ***" >> $logFile
    tiffinfo -d "$tiffOut" 2>> $logFile >/dev/null

    echo "------" >> $logFile

done < <(find $dirIn -type f -regex '.*\.\(jp2\|JP2\)' -print0)

# Power off the machine
# poweroff
