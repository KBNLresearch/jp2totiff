## Contents of this repo

### jp2totiff.sh

Takes a  directory tree with JP2 images, and converts them to TIFF.

Usage:

```
jp2totiff.sh dirIn dirOut
```

The directory structure of *dirIn* is cloned to *dirOut*.

Requires:

- Kakadu (kdu_expand)
- ExifTool
- realpath

### tifftojp2.sh

Takes a  directory tree with TIFF images, and converts them to JP2.

Usage:

```
tifftojp2.sh dirIn dirOut
```

The directory structure of *dirIn* is cloned to *dirOut*.

Requires:

- Kakadu (kdu_expand)
- ExifTool
- realpath

### mastertoaccess-grok.sh

Takes a  directory tree with (lossless master) JP2 images, and converts them to lossy JP2 according to KB specifications using Grok.

Usage:

```
mastertoaccess-grok.sh dirIn dirOut
```

Requires:

- Grok (grk_decompress and grk_compress)
- ExifTool
- realpath
- jprofile