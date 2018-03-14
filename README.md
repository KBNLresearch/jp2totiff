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
