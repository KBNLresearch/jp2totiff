# Grok build process and installation

This note documents the build process for Grok (including all third-party libraries that are needed to support various input formats andv ICC profiles). Partially based on [Bill Comstock's notes](https://wiki.harvard.edu/confluence/display/DigitalImaging/Installing+OpenJPEG+on+Windows+10%2C+Linux%2C+and+MacOS).

## Target OS

Linux Mint 20.1 Ulyssa (based on Ubuntu Focal Fossa 20.04).

## Dev environment

Install latest C and C++ compilers:

```
sudo apt install gcc-10
sudo apt install g++-10
```

Configure update alternatives so that newly installed compilers are used:

```
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100 --slave /usr/bin/g++ g++ /usr/bin/g++-10
```

Uninstall current version of cmake (which is too old for Grok):

```
sudo apt purge --auto-remove cmake
```

Install newer version as per [here](https://askubuntu.com/a/1157132/1052776):

```
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
sudo apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main'
sudo apt update
sudo apt install cmake
```

##  Install libraries needed by Grok

```
sudo apt-get install pkg-config libltdl-dev liblcms2-dev libtiff-dev libpng-dev libz-dev libzstd-dev libwebp-dev
```

## Grok build process 

Download latest source distribution from:

<https://github.com/GrokImageCompression/grok/releases/latest>

Then unzip.

Note: earlier (9.7.3 and before) source distributions failed to compile because of [missing subdirectories in the "thirdparty" directory](https://github.com/GrokImageCompression/grok/issues/296). This is fixed from version 9.7.4 onwards.


Go to Grok directory:

```
cd grok
```

Create build directory, the go there:

```
mkdir build
cd build
```

If you want to list all the build options:

```
cmake .. -LA  '{if(f)print} /-- Cache values/{f=1}'
```

From this huge list the following flags are important:

- `CMAKE_BUILD_TYPE=Release`
- `GROK_BUILD_THIRDPARTY:BOOL=ON`

Configure build:

```
cmake -DCMAKE_BUILD_TYPE=Release -DGROK_BUILD_THIRDPARTY:BOOL=ON ..
```
For build we can specify number of logical cores. Check out using:

```
lscpu
```

Result:

```
Architecture:                    x86_64
CPU op-mode(s):                  32-bit, 64-bit
Byte Order:                      Little Endian
Address sizes:                   39 bits physical, 48 bits virtual
CPU(s):                          4
On-line CPU(s) list:             0-3
Thread(s) per core:              1
Core(s) per socket:              4
Socket(s):                       1
```

So in this case we have 4 physical cores, each running 1 thread (so 4 logical cores as well). So build using:

```
make -j4
```

Install:

```
sudo make install
```

Configure shared libraries:

```
sudo ldconfig
```
Clean:

```
sudo make clean
```

Done!
