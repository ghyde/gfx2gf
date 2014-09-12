#!/bin/bash

##########################################################################
#                                                                        #
# gfx2gf.sh v1.0 (20140911)                                              #
# by Garrett Hyde                                                        #
#                                                                        #
# This bash script is based upon Jeremy Williams Window's batch file.    #
# *** You must have ImageMagick (www.imagemagick.org) installed! ***     #
# You also might need to install Ghostscript.                            #
#                                                                        #
##########################################################################

USAGE="$0 [-o $(tput smul)directory$(tput rmul)] $(tput smul)file$(tput rmul)..."

#Check if ImageMagick is installed
if ! type convert > /dev/null; then
    echo "You need to install ImageMagick first!"
    exit 1
fi

#Check if Ghostscript is installed
if ! type gs > /dev/null; then
    echo "You need to install Ghostscript first! (Required in order to run \`convert\`)"
    exit 1
fi

if [ "$#" -lt 1 ]; then
    echo $USAGE
    exit 1
fi

base_output=""
while getopts ":o:" opt; do
    case $opt in
        o)
            base_output="$OPTARG"
            ;;
        #TODO add option to force overwrite of existing folders
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

for input_path in "$@"; do
    # Establish output directory
    input_file="$(basename "$input_path")"
    output_dir="$(basename "$input_path" .${input_path##*.})"
    if [ -n "$base_output" ]; then
        output_path="$base_output/$output_dir"
    else
        output_path="$(dirname "$input_path")/$output_dir"
    fi

    echo "$output_path"
    # Make output directory
    if [ -e "$output_path" ]; then
        echo "Cannot create output directory \"$output_path\" because it already exists."
        exit 1
    else
        mkdir -p "$output_path"
    fi

    # Grab information about source file (height, width, delay)
    file_info=$(identify -format "%h %w %T" "$input_path"[0])
    height=$(echo $file_info | awk '{print $1}')
    width=$(echo $file_info | awk '{print $2}')
    delay=$(echo $file_info | awk '{print $3}')

    # Convert to BMP and extract animated GIF into separate files
    echo "Converting \"$input_file\" to Game Frame format..."
    echo "-----"
    ffmpeg -an -r 1 -i "$input_path" -r 1 -f image2 -pix_fmt bgr24 -s 16x16 "$output_path/frame_%06d.bmp"
    echo "-----"

    # Count the number of frames
    frames=$(ls "$output_path" | grep "frame_" | wc -l)
    echo "$frames 16x16 frame(s) created."

    if [ "$frames" -gt 196000 ]; then
        echo "File has more than 196000 frames. This might not work."
    fi

    if [ "$frames" -gt 1999 ]; then
        nested=1
    else
        nested=0
    fi

    # Combine multiple files into one long filmstrip
    echo "Creating filmstrip..."
    montage "$output_path/frame_*.bmp" -mode concatenate -tile 1x -type truecolor "$output_path/0.bmp"
    if [ "$frames" -gt 1 ]; then
        echo "Filmstrip conversion finished!"

        if [ "$delay" -lt 4 ]; then
            delay=4
        fi
        delay=$(($delay * 4))

        # Write config.ini using stored delay value
        echo "# All of these settings are optional. 
# If this file does't exist, or if 
# settings don't appear in this file, 
# Game Frame will use default values. 
. 
[animation] 
. 
# milliseconds to hold each frame 
# (1000 = 1 sec; lower is faster) 
hold = $delay
. 
# should the animation loop? If false, 
# system will progress to next folder 
# after the last frame is displayed. 
loop = true 
. 
[translate] 
. 
# move the animation across the screen 
# this many pixels per frame. Experiment 
# with positive and negative numbers for 
# different directions. 
moveX = 0 
moveY = 16 
. 
# should the movement loop? 
$(if [ "$nested" -eq 0 ]; then
	echo "loop = true"
else
	echo "loop = false"
fi)
. 
# begin/end scroll off screen? 
panoff = false 
. 
# optionally dictate the next animation 
# EXAMPLE: nextFolder = mspacman 
# nextFolder = defend1" > "$output_path/config.ini"

        echo "File \"config.ini\" written!"

        echo "Generating preview..."
        delay=$(($delay / 10))
        if [ "$frames" -le 250 ]; then
            convert -delay $delay -filter box -resize 128x128 "$output_path/frame_*.bmp" "$output_path"/"$output_dir"_preview.gif
        else
            echo "Long animation; only previewing the first 250 frames..."
            convert -delay $delay -filter box -resize 128x128 "$output_path/frame_%06d.bmp[1-250]" "$output_path"/"$output_dir"_preview.gif
        fi
        echo "Preview created!"

    else
        echo "Graphic conversion finished!"
        echo "Generating preview..."
        convert -filter box -resize 128x128 "$output_path/frame_*.bmp" "$output_path"/"$output_dir"_preview.gif
        echo "Preview created!"
    fi

    # Cleanup
    find "$output_path" -name 'frame_*.bmp' -delete

    # Build nest
    if [ "$nested" -eq 1 ]; then
        echo "Long video detected; nesting folders..."

        convert -crop 16x32000x0x0 "$output_path/0.bmp" "$output_path/strip_%01d.bmp"
        strips=$(ls "$output_path" | grep "strip_" | wc -l)
        echo "$strips filmstrips created."

        for i in $(seq 0 $(($strips - 1))); do
            echo "Making nested folder $i"
            mkdir "$output_dir/$i"
            mv "$output_dir/strip_$i.bmp" "$output_dir/$i/0.bmp"
            cp "$output_dir/config.ini" "$output_dir/$i/"
        done
        rm -f "$output_dir/config.ini"
        rm -f "$output_path/0.bmp"
        echo "Nesting folders complete!"

    fi
    
    echo "Process finished!"
done

exit 0
