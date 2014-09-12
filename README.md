gfx2gf
======
These scripts are used to convert almost any graphic to Game Frame.
The original script (`gfx2gf.bat`) was writen by Jeremy Williams and
posted [here][1]. `gfx2gf.sh` is a bash implementation of this script.

I have only tested `gfx2gf.sh` on my Mac. It should, in theory, also
work on Linux.

Dependencies
------------
[ImageMagick][2] is required in order for this script to run. You also
might need to install [Ghostscript][3] in order for `convert` to run.

To install these packages via [Homebrew][4]:

    brew install imagemagick ghostscript

Usage
-----

    gfx2gf.sh [-f] [-o directory] [-v] file...

`gfx2gf.sh` can take multiple input graphic files. For each file,
the script will make an output directory of the same name inside the
input file's parent directory. The script will then generate Game
Frame files inside the output directory.

The `-f` option will force the script to overwrite any existing
output folders.

The `-o` option will direct the script to create the output
directory in the given location instead of an input file's parent
directory.

The `-v` option enables verbose mode.


  [1]: http://ledseq.com/forums/topic/graphic-conversion-tool-gfx2gf/#post-1220
  [2]: http://www.imagemagick.org/
  [3]: http://www.ghostscript.com/
  [4]: http://brew.sh/
