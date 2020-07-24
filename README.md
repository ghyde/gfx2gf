gfx2gf
======
These scripts are used to convert almost any graphic to Game Frame.
The original script (`gfx2gf.bat`) was writen by Jeremy Williams and
posted [here][1]. `gfx2gf.sh` is a bash implementation of this script.

I have only tested `gfx2gf.sh` on my Mac. It should, in theory, also
work on Linux.

Dependencies
------------
You must have the following packages installed in order to run this
script:

 - [FFmpeg][2]
 - [ImageMagick][3]
 - [Ghostscript][4]

To install these packages via [Homebrew][5]:

    brew install ffmpeg imagemagick ghostscript

Usage
-----

    gfx2gf.sh [-f] [-h] [-n] [-o directory] [-v] file...

`gfx2gf.sh` can take multiple input graphic files. For each file,
the script will make an output directory of the same name inside the
input file's parent directory. The script will then generate Game
Frame files inside the output directory.

The `-f` option will force the script to overwrite any existing
output folders.

The `-h` option will print out the usage for gfx2gf.sh.

The `-n` option will use nearest neighbor when scaling the images

The `-o` option will direct the script to create output directories
in the given location instead of an input file's parent directory.

The `-v` option enables verbose mode.


  [1]: http://ledseq.com/forums/topic/graphic-conversion-tool-gfx2gf/#post-1220
  [2]: https://www.ffmpeg.org/
  [3]: http://www.imagemagick.org/
  [4]: http://www.ghostscript.com/
  [5]: http://brew.sh/
