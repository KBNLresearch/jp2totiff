#!/bin/bash

# Convert directory tree with JP2 lossless master images to  lossy access JP2s
# Requires: 
# - Kakadu
# - ExifTool
#  -sed
# - jprofile

if [ "$#" -ne 2 ] ; then
  echo "Usage: mastertoaccess-kdu.sh dirIn dirOut" >&2
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

# Location of Kakadu binaries
kduPath=~/kakadu

# Add Kakadu path to LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$kduPath

# Log file (used too store kakadu stdout, stderr)
logFile=$dirOut/mastertoaccess-kdu.log

# Kakadu status file (used to store Kakadu exit status)
kduStatusFile=$dirOut/kduStatus.csv

# Remove log and status files if they exist already (writing done in append mode!)
if [ -f $logFile ] ; then
  rm $logFile
fi

if [ -f $kduStatusFile ] ; then
  rm $kduStatusFile
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
    cmdDecompress="$kduPath/kdu_expand -i "$file"
            -o "$tifOut""

    $cmdDecompress >>$logFile 2>&1
    kduDecompressStatus=$?
    echo $tifOut,$kduDecompressStatus >> $kduStatusFile

    # Get SamplesPerPixel value from output TIFF
    samplesPerPixel=$(exiftool -s -s -s -SamplesPerPixel "$tifOut")

    # Determine bitrate values, depending on samplesPerPixel value
    # Since bitrate = (BPP/CompressionRatio)
    if [ $samplesPerPixel -eq 3 ] ; then
        bitratesAccess="1.2,0.6,0.3,0.15,0.075,0.0375,0.01875,0.009375" 
    fi

    if [ $samplesPerPixel -eq 1 ] ; then
        bitratesAccess="0.4,0.2,0.1,0.05,0.025,0.0125,0.00625,0.003125"
    fi

    # Name for temporary XMP sidecar file
    xmpName=$bName.xmp

    # Extract metadata from TIFF with Exiftool and write to XMP sidecar
    exiftool "$file" -o "$xmpName" >>$logFile 2>&1

    # Insert string "xml "at start of sidecar file so Kakadu knows to use XML box 
    sed -i "1s/^/xml /" "$xmpName"

    # Convert TIFF to lossy access JP2 according to KB specs
    # Note: XMP metadata are written to UUID box, whereas KB
    # specs prescribe XML box. Don't think this is a problem
    # for access images. 

    cmdCompress="$kduPath/kdu_compress -i "$tifOut"
           -o "$jp2Out"
           Creversible=no
           Clevels=5
           Corder=RPCL
           Stiles={1024,1024}
           Cblk={64,64}
           Cprecincts={256,256},{256,256},{128,128}
           Clayers=8
           -rate $bitratesAccess
           Cuse_sop=yes
           Cuse_eph=yes
           Cmodes=SEGMARK
           -jp2_box "$xmpName"
           -com "$cCommentAccess""

    $cmdCompress >>$logFile 2>&1
    kduCompressStatus=$?
    echo $jp2Out,$kduCompressStatus >> $kduStatusFile

    # Remove TIFF file
    rm $tifOut

    # Remove XMP sidecar file
    rm $xmpName

done < <(find $dirIn -type f -regex '.*\.\(jp2\|JP2\)' -print0)

# Run jprofile
jprofile -p kb_300Colour_2014.xml $dirAccess jprofile