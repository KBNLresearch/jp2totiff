#!/bin/bash

# Convert directory with JP2 lossless master images to PDF with
# various JPEG quality levels via TIFF
# Requires: 
# - Grok
# - ImageMagick

if [ "$#" -ne 3 ] ; then
  echo "Usage: jp2totpdf-grok.sh prefix dirIn dirOut" >&2
  exit 1
fi

# Input and output directories
prefix="$1"
dirIn="$2"
dirOut="$3"

# PDF JPEG parameters
density=300
qualityLevels=(100 92 85 70 60 50)

if ! [ -d "$dirIn" ] ; then
  echo "input directory does not exist" >&2
  exit 1
fi

if ! [ -d "$dirOut" ] ; then
  mkdir "$dirOut"
fi

# Output CSV file
csvOut="$dirOut"/"$prefix"_qsize.csv

if [ -f "$csvOut" ] ; then
    rm $csvOut
fi

# Log file (used too store Grok stdout, stderr)
logFile=$dirOut/jp2topdf-grok.log

# Grok status file (used to store Kakadu exit status)
grokStatusFile=$dirOut/grokStatus.csv

# Remove log and status files if they exist already (writing done in append mode!)
if [ -f $logFile ] ; then
  rm $logFile
fi

if [ -f $grokStatusFile ] ; then
  rm $grokStatusFile
fi

# Iterate over all files in dirIn and convert JP2s
# to TIFF

while IFS= read -d $'\0' file ; do

    # File basename, extension removed
    bName=$(basename "$file" | cut -f 1 -d '.')
    
    # Output names
    outNameTIF=$bName.tif

    # Input path
    inPath=$(dirname "$file")

    # Full paths to output files
    tifOut="$dirOut/$outNameTIF"

    # First convert master JP2 to TIFF
    cmdDecompress="grk_decompress -i "$file"
          -o "$tifOut"
          -W "$logFile""

    $cmdDecompress
    grokDecompressStatus=$?
    echo $tifOut,$grokDecompressStatus >> $grokStatusFile

done < <(find $dirIn -type f -regex '.*\.\(jp2\|JP2\)' -print0)

echo "q","fileSize" >> $csvOut

# Create PDFs from TIFF images

for q in "${qualityLevels[@]}"; do
    fileOut="$dirOut/$prefix"_"$q".pdf
    convert "$dirOut/*.{tif}" \
            -compress jpeg \
            -quality "$q" \
            -density "$density" \
            "$fileOut"
    fileSize=$(ls -l $fileOut | awk '{print $5}')
    echo "$q","$fileSize" >> $csvOut
done

# Remove TIFF images

while IFS= read -d $'\0' file ; do
    rm $file
done < <(find $dirOut -type f -regex '.*\.\(tif\|TIF\)' -print0)
