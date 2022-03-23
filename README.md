## Contents of this repo

Various scripts for converting to and from JP2 (JPEG 2000 Part 1).

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

Takes a  directory with (lossless master) JP2 images, and converts them to lossy JP2 according to KB specifications using Grok.

Usage:

```
mastertoaccess-grok.sh dirIn dirOut
```

Requires:

- Grok (grk_decompress and grk_compress)
- ExifTool
- realpath
- [jprofile](https://github.com/KBNLresearch/jprofile)

### mastertoaccess-kdu.sh

Takes a  directory with (lossless master) JP2 images, and converts them to lossy JP2 according to KB specifications using Kakadu.

Usage:

```
mastertoaccess-kdu.sh dirIn dirOut
```

Requires:

- Kakadu (kdu_expand and kdu_compress)
- ExifTool
- sed
- [jprofile](https://github.com/KBNLresearch/jprofile)