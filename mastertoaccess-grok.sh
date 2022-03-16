#!/bin/bash

# Convert directory tree with JP2 lossless master images to  lossy access JP2s
# Requires: 
# - Grok
# - ExifTool
# - realpath
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

# Log file (used too store Kakadu and Exiftool stdout, stderr)
logFile=$dirOut/tifftojp2.log

# Grok status file (used to store Kakadu exit status)
grokStatusFile=$dirOut/grokStatus.csv

# Remove log and checksum files if they exist already (writing done in append mode!)
if [ -f $logFile ] ; then
  rm $logFile
fi

if [ -f $grokStatusFile ] ; then
  rm $grokStatusFile
fi

# Codestream comment string for access images
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
# to TIFF, then convert those TIFFs to lossy JP2
# according to KB access specs.

while IFS= read -d $'\0' -r file ; do

    # File basename, extension removed
    bName=$(basename "$file" | cut -f 1 -d '.')
    
    # Output names
    outNameTIF=$bName.tif
    outNameJP2=$bName.jp2

    # Input path
    inPath=$(dirname "$file")

    # Input path, relative to dirIn
    inPathRel=$(realpath --relative-to=$dirIn $inPath)

    # Full paths to output files
    tifOut="$dirOut/$inPathRel/$outNameTIF"
    jp2Out="$dirOut/$inPathRel/$outNameJP2"

    # First convert master JP2 to TIFF
    cmdDecompress="grk_decompress -i "$file"
            -o "$tifOut"
            -W "$logFile""
    $cmdDecompress
    grokDecompressStatus=$?
    echo $tifOut,$grokDecompressStatus >> $grokStatusFile

    # Remove all metadata from TIFF
    # WORKAROUND for apparent bug in grk_compress
    # that results in malformed embedded metadata!
    exiftool -overwrite_original -all= -TagsFromFile @ -ColorSpaceTags "$tifOut"

    # Convert TIFF to lossy access JP2 according to KB specs
    # Note: for some reason setting the -t option results
    # in malformed XML data inside the UUID box!
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
 
    # Convert TIFF to lossy access JP2
    $cmdCompress
    grokCompressStatus=$?

    echo $jp2Out,$grokCompressStatus >> $grokStatusFile

    # Add XMP metadata from source JP2
    # WORKAROUND for apparent bug in grk_compress
    # that results in malformed embedded metadata!
    exiftool -overwrite_original -tagsfromfile "$file" -xmp "$jp2Out"

    # Remove TIFF file
    rm $tifOut

    # Run jprofile
    jprofile -p kb_300Colour_2014.xml $dirOutAbs jprofile

done < <(find $dirIn -type f -regex '.*\.\(jp2\|JP2\)' -print0)
