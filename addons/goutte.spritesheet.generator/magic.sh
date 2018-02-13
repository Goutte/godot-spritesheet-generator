#!/bin/bash

echo -e "Opening the glue tube…"

OUTPUT_DIR=$1
FILE_SLUG=$2
COLOR_R=$3
COLOR_G=$4
COLOR_B=$5
SHADOW_COLOR_R=$6
SHADOW_COLOR_G=$7
SHADOW_COLOR_B=$8

###############################################################################

GIMP_COLOR="(${COLOR_R} ${COLOR_G} ${COLOR_B})"
GIMP_SHADOW_COLOR="(${SHADOW_COLOR_R} ${SHADOW_COLOR_G} ${SHADOW_COLOR_B})"

echo -e "COLOR"
echo -e "${GIMP_COLOR}"
echo -e "${GIMP_SHADOW_COLOR}"

#GIMP_COLOR="(0 0 0)"
#GIMP_SHADOW_COLOR="(0 0 0)"

RGB_COLOR="rgb(${COLOR_R},${COLOR_G},${COLOR_B}))"

INPUT_FILES="${OUTPUT_DIR}${FILE_SLUG}_capture_*"
OUTPUT_FILE_NO_ALPHA="${OUTPUT_DIR}${FILE_SLUG}_spritesheet_noalpha.png"
OUTPUT_FILE_1="${OUTPUT_DIR}${FILE_SLUG}_spritesheet_1.png"
OUTPUT_FILE_2="${OUTPUT_DIR}${FILE_SLUG}_spritesheet_2.png"
OUTPUT_FILE_3="${OUTPUT_DIR}${FILE_SLUG}_spritesheet_3.png"
OUTPUT_FILE_4="${OUTPUT_DIR}${FILE_SLUG}_spritesheet_4.png"


###############################################################################
# 0. Create the sprite sheet image without alpha
montage ${INPUT_FILES} \
        -tile x1 -geometry '1x1+0+0<' \
        -alpha On -background "rgba(0,0,0,0.0)" \
        -quality 100 \
        ${OUTPUT_FILE_NO_ALPHA}


###############################################################################
# 1. Using ImageMagick (usually poor results with partial transparency)
convert ${OUTPUT_FILE_NO_ALPHA} \
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
    (gimp-image-convert-rgb image)
    (plug-in-colortoalpha RUN-NONINTERACTIVE image drawable '${GIMP_COLOR} )
    (gimp-file-save RUN-NONINTERACTIVE image drawable \"${OUTPUT_FILE_2}\" \"${OUTPUT_FILE_2}\")
)
"
echo -e "${COLOR2ALPHA_1}"
gimp -i -b "${COLOR2ALPHA_1}" -b "(gimp-quit 0)"


###############################################################################
# 3. Using GIMP, colortoalpha on selection by color, with feather and grow
COLOR2ALPHA_2="
(let*
    (
        (image (car (file-png-load RUN-NONINTERACTIVE \"${OUTPUT_FILE_NO_ALPHA}\" \"${OUTPUT_FILE_NO_ALPHA}\") ) )
        (drawable (car (gimp-image-active-drawable image)))
        ;(selection (car (gimp-image-get-selection image)))
    )
    (gimp-image-convert-rgb image)
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
gimp -i -b "${COLOR2ALPHA_2}" -b "(gimp-quit 0)"


###############################################################################
# 4. Same as 3. plus sharpen
COLOR2ALPHA_3="
(let*
    (
        (image (car (file-png-load RUN-NONINTERACTIVE \"${OUTPUT_FILE_NO_ALPHA}\" \"${OUTPUT_FILE_NO_ALPHA}\") ) )
        (drawable (car (gimp-image-active-drawable image)))
        ;(selection (car (gimp-image-get-selection image)))
    )
    (gimp-image-convert-rgb image)
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
gimp -i -b "${COLOR2ALPHA_3}" -b "(gimp-quit 0)"

###############################################################################

echo -e "Scraping glue from fingers…"
echo -e "Look in ${OUTPUT_DIR} for your sprites."