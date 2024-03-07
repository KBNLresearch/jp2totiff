#!/bin/bash

# Performs pixel-wise check between images in two directory trees
# Requires: 
# - ImageMagick
# - realpath


if [ "$#" -ne 3 ] ; then
  echo "Usage: pixelCheck.sh dir1 dir2 dirOut" >&2
  exit 1
fi

# Input and output directories
dir1="$1"
dir2="$2"
dirOut="$3"

if ! [ -d "$dir1" ] ; then
  echo "input directory 1 does not exist" >&2
  exit 1
fi

if ! [ -d "$dir2" ] ; then
  echo "input directory 2 does not exist" >&2
  exit 1
fi

if ! [ -d "$dirOut" ] ; then
  mkdir "$dirOut"
fi

# Output file
fileOut=$dirOut/pixelCheck.csv

# Remove loutput file if it exists already (writing done in append mode!)
if [ -f $fileOut ] ; then
  rm $fileOut
fi

# Write header to output file
echo "file1","file2","ae","psnr" >> $fileOut

# Iterate over all images in dir1, and do pixel check
# with corresponding image in dir2

while IFS= read -d $'\0' -r file ; do

    # File basename, extension removed
    #bName=$(basename "$file" | cut -f 1 -d '.')
    file1="$file"
    #bName=$(basename "$file")
    
    # Output name
    #outName=$bName.jp2
    file2Name=$(basename "$file")

    # Input path
    path1=$(dirname "$file1")

    # Input path, relative to dir1
    inPathRel=$(realpath --relative-to=$dir1 $path1)

    # Full path to corresponding file in dir2
    file2="$dir2/$inPathRel/$file2Name"

    ae=$(compare -quiet -metric AE "$file1" "$file2" null: 2>&1)
    psnr=$(compare -quiet -metric psnr "$file1" "$file2" null: 2>&1)

    echo "$file1","$file2","$ae","$psnr" >> $fileOut
 
done < <(find $dir1 -type f -regex '.*\.\(tiff\|TIFF\|tif\|TIF\)' -print0)

# Power off the machine
# poweroff
