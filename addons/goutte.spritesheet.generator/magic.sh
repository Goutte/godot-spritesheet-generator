#!/bin/bash

echo -e "Opening the glue tube…"

## ARGUMENTS ##################################################################

OUTPUT_DIR=$1       # absolute, with trailing path separator
FILE_SLUG=$2

# Color values from 0 to 255
COLOR_R=$3
COLOR_G=$4
COLOR_B=$5
SHADOW_COLOR_R=$6
SHADOW_COLOR_G=$7
SHADOW_COLOR_B=$8


## OS DETECTION ###############################################################

IS_WINDOWS=0

case "$OSTYPE" in
  solaris*)
    echo -e "Solaris?! If you read this you are awesome, or mad, or both."
    ;;
  darwin*)
    echo -e "You're on a computer of the brand Apple©? Tell us if it works!"
    ;;
  linux*)
    echo -e "Hello, gaming penguin."
    ;;
  bsd*)
    echo -e "BSD!? If you read this you are awesome."
    ;;
  msys*)
    IS_WINDOWS=1
    ;;
  *)
    echo -e "Wait. What's your OS? This: $OSTYPE ? Assuming NOT Windows."
    ;;
esac


GIMP_BIN="gimp"
MONTAGE_BIN="montage"
CONVERT_BIN="convert"
if [ ${IS_WINDOWS} -eq 1 ]
then
    MONTAGE_BIN="magick montage"
    CONVERT_BIN="magick convert"
fi


###############################################################################

GIMP_COLOR="(${COLOR_R} ${COLOR_G} ${COLOR_B})"
GIMP_SHADOW_COLOR="(${SHADOW_COLOR_R} ${SHADOW_COLOR_G} ${SHADOW_COLOR_B})"

RGB_COLOR="rgb(${COLOR_R},${COLOR_G},${COLOR_B}))"

INPUT_FILES="${OUTPUT_DIR}${FILE_SLUG}_capture_*.png"

OUTPUT_FILE_NO_ALPHA="${OUTPUT_DIR}${FILE_SLUG}_spritesheet_noalpha.png"
OUTPUT_FILE_1="${OUTPUT_DIR}${FILE_SLUG}_spritesheet_1.png"
OUTPUT_FILE_2="${OUTPUT_DIR}${FILE_SLUG}_spritesheet_2.png"
OUTPUT_FILE_3="${OUTPUT_DIR}${FILE_SLUG}_spritesheet_3.png"
OUTPUT_FILE_4="${OUTPUT_DIR}${FILE_SLUG}_spritesheet_4.png"


###############################################################################
# 0. Create the sprite sheet image without alpha
${MONTAGE_BIN} ${INPUT_FILES} \
        -tile x1 -geometry '1x1+0+0<' \
        -alpha On -background "rgba(0,0,0,0.0)" \
        -quality 100 \
        ${OUTPUT_FILE_NO_ALPHA}


###############################################################################
# 1. Using ImageMagick (usually poor results with partial transparency)
${CONVERT_BIN} ${OUTPUT_FILE_NO_ALPHA} \
        -transparent "${RGB_COLOR}" \
        -alpha On -background "rgba(0,0,0,0.0)" \
        -quality 100 \
        ${OUTPUT_FILE_1}


###############################################################################
# 2. Using GIMP, unadulterated colortoalpha (makes everything semi-transparent)
COLOR2ALPHA_1="
(let*
    (
        (image (car (file-png-load 1 \"${OUTPUT_FILE_NO_ALPHA}\" \"${OUTPUT_FILE_NO_ALPHA}\") ) )
        (drawable (car (gimp-image-active-drawable image) ) )
    )
    (if (gimp-drawable-is-indexed drawable)
        (gimp-image-convert-rgb image)
        ()
    )
    (plug-in-colortoalpha RUN-NONINTERACTIVE image drawable '${GIMP_COLOR} )
    (gimp-file-save RUN-NONINTERACTIVE image drawable \"${OUTPUT_FILE_2}\" \"${OUTPUT_FILE_2}\")
)
"
#echo -e "${COLOR2ALPHA_1}"
${GIMP_BIN} -i -b "${COLOR2ALPHA_1}" -b "(gimp-quit 0)"


###############################################################################
# 3. Using GIMP, colortoalpha on selection by color, with feather and grow
COLOR2ALPHA_2="
(let*
    (
        (image (car (file-png-load RUN-NONINTERACTIVE \"${OUTPUT_FILE_NO_ALPHA}\" \"${OUTPUT_FILE_NO_ALPHA}\") ) )
        (drawable (car (gimp-image-active-drawable image)))
        ;(selection (car (gimp-image-get-selection image)))
    )
    (if (gimp-drawable-is-indexed drawable)
        (gimp-image-convert-rgb image)
        ()
    )
    (gimp-context-set-antialias FALSE)
    (gimp-context-set-feather TRUE)
    (gimp-context-set-feather-radius 1 1)
    (gimp-context-set-sample-criterion SELECT-CRITERION-COMPOSITE)
    (gimp-context-set-sample-threshold-int 2)
    (gimp-image-select-color image CHANNEL-OP-REPLACE drawable '${GIMP_COLOR})
    (gimp-image-select-color image CHANNEL-OP-ADD drawable '${GIMP_SHADOW_COLOR})
    (gimp-selection-grow image 1)

    ; colortoalpha will only be applied to the selection
    (plug-in-colortoalpha RUN-NONINTERACTIVE image drawable '${GIMP_COLOR})
    (gimp-file-save RUN-NONINTERACTIVE image drawable \"${OUTPUT_FILE_3}\" \"${OUTPUT_FILE_3}\" )
)
"
${GIMP_BIN} -i -b "${COLOR2ALPHA_2}" -b "(gimp-quit 0)"


###############################################################################
# 4. Same as 3. plus sharpen
COLOR2ALPHA_3="
(let*
    (
        (image (car (file-png-load RUN-NONINTERACTIVE \"${OUTPUT_FILE_NO_ALPHA}\" \"${OUTPUT_FILE_NO_ALPHA}\") ) )
        (drawable (car (gimp-image-active-drawable image)))
        ;(selection (car (gimp-image-get-selection image)))
    )
    (if (gimp-drawable-is-indexed drawable)
        (gimp-image-convert-rgb image)
        ()
    )
    (gimp-context-set-antialias FALSE)
    (gimp-context-set-feather TRUE)
    (gimp-context-set-feather-radius 2 2)
    (gimp-context-set-sample-criterion SELECT-CRITERION-COMPOSITE)
    ;(gimp-context-set-sample-criterion SELECT-CRITERION-H)
    ;(gimp-context-set-sample-criterion SELECT-CRITERION-V)
    ;(gimp-context-set-sample-criterion SELECT-CRITERION-R)
    (gimp-context-set-sample-threshold-int 2)
    (gimp-image-select-color image CHANNEL-OP-REPLACE drawable '${GIMP_COLOR})
    (gimp-image-select-color image CHANNEL-OP-ADD drawable '${GIMP_SHADOW_COLOR})
    (gimp-selection-grow image 1)

    ; Trying to sharpen the selection with a custom threshold and rescale.
    ; ... No such luck.
    ;(gimp-levels (car (gimp-image-get-selection image)) HISTOGRAM-VALUE 0 127 1.0 0 0)
    ;(gimp-levels (car (gimp-image-get-selection image)) HISTOGRAM-VALUE 128 255 1.0 0 255)

    (gimp-selection-sharpen image)

    ; colortoalpha will only be applied to the selection
    (plug-in-colortoalpha RUN-NONINTERACTIVE image drawable '${GIMP_COLOR})
    (gimp-file-save RUN-NONINTERACTIVE image drawable \"${OUTPUT_FILE_4}\" \"${OUTPUT_FILE_4}\" )
)
"
${GIMP_BIN} -i -b "${COLOR2ALPHA_3}" -b "(gimp-quit 0)"

###############################################################################

echo -e "Scraping glue from fingers…"
echo -e "Look in ${OUTPUT_DIR} for your sprites."