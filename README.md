## Contents of this repo

### jp2totiff.sh

Takes a  directory tree with JP2 images, and converts them to TIFF.

Usage:

    jp2totiff.sh dirIn dirOut

The directory structure of *dirIn* is cloned to *dirOut*.

Requires:

    - Kakadu (kdu_expand)
    - ExifTool
    - realpath

### tifftojp2.sh

Takes a  directory tree with TIFF images, and converts them to JP2.

Usage:

    tifftojp2.sh dirIn dirOut

The directory structure of *dirIn* is cloned to *dirOut*.

Requires:

    - Kakadu (kdu_expand)
    - ExifTool
    - realpath
 