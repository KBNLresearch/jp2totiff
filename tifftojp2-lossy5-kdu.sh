#!/bin/bash

# Convert directory tree with TIFF images to lossy JP2 with 5:1 compression ratio
# Requires: 
# - Kakadu (kdu_expand)
# - ExifTool
# - realpath


if [ "$#" -ne 2 ] ; then
  echo "Usage: tifftojp2-lossy-5-kdu.sh dirIn dirOut" >&2
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

# Log file (used too store Kakadu and Exiftool stdout, stderr)
logFile=$dirOut/tifftojp2.log

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

# Codestream comment strings for master and access images
cCommentMaster="KB_MASTER_LOSSY_05/03/2024"

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

    # Name for temporary XMP sidecar file
    xmpName=$bName.xmp

    echo "*** Exiftool log: ***" >> $logFile

    # Extract metadata from TIFF with Exiftool and write to XMP sidecar
    exiftool "$file" -o "$xmpName" >>$logFile 2>&1

    # Insert string "xml "at start of sidecar file so Kakadu knows to use XML box 
    sed -i "1s/^/xml /" "$xmpName"

    # Get SamplesPerPixel value 
    samplesPerPixel=$(exiftool -s -s -s -SamplesPerPixel "$file")

    # Determine bitrate values, depending on samplesPerPixel value
    # Since bitrate = (BPP/CompressionRatio)
    if [ $samplesPerPixel -eq 3 ] ; then
        bitratesMaster="4.8,2.4,1.2,0.6,0.3,0.15,0.075,0.0375,0.01875,0.009375" 
    fi

    if [ $samplesPerPixel -eq 1 ] ; then
        bitratesMaster="1.6,0.8,0.4,0.2,0.1,0.05,0.025,0.0125,0.00625,0.003125"
    fi

    # Construct Kakadu command lines (lossless master, lossy access copy)

    cmdlineMaster="$kduPath/kdu_compress -i "$file"
            -o "$jp2Out"
            Creversible=no
            Clevels=5
            Corder=RPCL
            Stiles={1024,1024}
            Cblk={64,64}
            Cprecincts={256,256},{256,256},{128,128}
            Clayers=10
            -rate $bitratesMaster
            Cuse_sop=yes
            Cuse_eph=yes
            Cmodes=SEGMARK
            -jp2_box "$xmpName"
            -com "$cCommentMaster""

    echo "*** Kakadu log: ***" >> $logFile

    # Convert to JP2
    $cmdlineMaster >>$logFile 2>&1

    kakaduStatus=$?
    echo $jp2Out,$kakaduStatus >> $kakaduStatusFile
 
    # Remove XMP sidecar file
    rm $xmpName

    #md5sum "$jp2Out" >> $checksumFile

    echo "------" >> $logFile

done < <(find $dirIn -type f -regex '.*\.\(tiff\|TIFF\|tif\|TIF\)' -print0)

# Power off the machine
# poweroff
