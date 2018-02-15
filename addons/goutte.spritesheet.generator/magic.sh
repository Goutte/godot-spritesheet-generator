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
OUTPUT_FILE_5="${OUTPUT_DIR}${FILE_SLUG}_spritesheet_5.png"

OUTPUT_LOG="${OUTPUT_DIR}${FILE_SLUG}.log"
# Even on success, log may be filled with internal GIMP errors such as
# GEGL-gegl-operation.c-WARNING **: Cannot change name of operation class
# Just ignore them, to find meaningful errors.

###############################################################################

#echo -e "Make me a function" >>${OUTPUT_LOG} 2>&1

###############################################################################
# 0. Create the sprite sheet image without alpha
#    png:color-type ensures that the resulting image is RGB and never Indexed.
echo -e "MONTAGE…" >>${OUTPUT_LOG} 2>&1
${MONTAGE_BIN} ${INPUT_FILES} \
        -tile x1 -geometry '1x1+0+0<' \
        -alpha On -background "rgba(0,0,0,0.0)" \
        -quality 100 \
        -define png:color-type='2' \
        ${OUTPUT_FILE_NO_ALPHA}


###############################################################################
# 1. Using ImageMagick (usually poor results with partial transparency)
echo -e "METHOD 1…" >>${OUTPUT_LOG} 2>&1
${CONVERT_BIN} ${OUTPUT_FILE_NO_ALPHA} \
        -transparent "${RGB_COLOR}" \
        -alpha On -background "rgba(0,0,0,0.0)" \
        -quality 100 \
        ${OUTPUT_FILE_1}

# ... and make a GIF as well
${CONVERT_BIN} ${OUTPUT_FILE_1} \
        -crop 128x128 +repage -set dispose background \
        -loop 0 -set delay 6 \
        ${OUTPUT_DIR}${FILE_SLUG}.gif


###############################################################################
# 2. Using GIMP, unadulterated colortoalpha (makes everything semi-transparent)
echo -e "METHOD 2…" >>${OUTPUT_LOG} 2>&1
SCHEME_2="
(let*
    (
        (image (car (file-png-load RUN-NONINTERACTIVE \"${OUTPUT_FILE_NO_ALPHA}\" \"${OUTPUT_FILE_NO_ALPHA}\") ) )
        (drawable (car (gimp-image-active-drawable image) ) )
    )
    (plug-in-colortoalpha RUN-NONINTERACTIVE image drawable '${GIMP_COLOR} )
    (gimp-file-save RUN-NONINTERACTIVE image drawable \"${OUTPUT_FILE_2}\" \"${OUTPUT_FILE_2}\")
)
"
${GIMP_BIN} -i -b "${SCHEME_2}" -b "(gimp-quit 0)" >>${OUTPUT_LOG} 2>&1


###############################################################################
# 3. Using GIMP, colortoalpha on selection of 1st color, with feather and grow
echo -e "METHOD 3…" >>${OUTPUT_LOG} 2>&1
SCHEME_3="
(let*
    (
        (image (car (file-png-load RUN-NONINTERACTIVE \"${OUTPUT_FILE_NO_ALPHA}\" \"${OUTPUT_FILE_NO_ALPHA}\") ) )
        (drawable (car (gimp-image-active-drawable image)))
    )
    (gimp-context-set-antialias FALSE)
    (gimp-context-set-feather TRUE)
    (gimp-context-set-feather-radius 1 1)
    (gimp-context-set-sample-criterion SELECT-CRITERION-COMPOSITE)
    (gimp-context-set-sample-threshold-int 2)
    (gimp-image-select-color image CHANNEL-OP-REPLACE drawable '${GIMP_COLOR})
    (gimp-selection-grow image 1)
    (gimp-selection-sharpen image)

    (plug-in-colortoalpha RUN-NONINTERACTIVE image drawable '${GIMP_COLOR})
    (gimp-file-save RUN-NONINTERACTIVE image drawable \"${OUTPUT_FILE_3}\" \"${OUTPUT_FILE_3}\" )
)
"
${GIMP_BIN} -i -b "${SCHEME_3}" -b "(gimp-quit 0)" >>${OUTPUT_LOG} 2>&1


###############################################################################
# 4. Using GIMP, colortoalpha on selections of both colors, with feather & grow
echo -e "METHOD 4…" >>${OUTPUT_LOG} 2>&1
SCHEME_4="
(let*
    (
        (image (car (file-png-load RUN-NONINTERACTIVE \"${OUTPUT_FILE_NO_ALPHA}\" \"${OUTPUT_FILE_NO_ALPHA}\") ) )
        (drawable (car (gimp-image-active-drawable image)))
        ;(selection (car (gimp-image-get-selection image)))
    )
    (gimp-context-set-antialias FALSE)
    (gimp-context-set-feather TRUE)
    (gimp-context-set-feather-radius 2 2)
    (gimp-context-set-sample-criterion SELECT-CRITERION-COMPOSITE)
    (gimp-context-set-sample-threshold-int 2)
    (gimp-image-select-color image CHANNEL-OP-REPLACE drawable '${GIMP_COLOR})
    (gimp-image-select-color image CHANNEL-OP-ADD drawable '${GIMP_SHADOW_COLOR})
    (gimp-selection-grow image 1)

    (plug-in-colortoalpha RUN-NONINTERACTIVE image drawable '${GIMP_COLOR})
    (gimp-file-save RUN-NONINTERACTIVE image drawable \"${OUTPUT_FILE_4}\" \"${OUTPUT_FILE_4}\" )
)
"
${GIMP_BIN} -i -b "${SCHEME_4}" -b "(gimp-quit 0)" >>${OUTPUT_LOG} 2>&1


###############################################################################
# 5. Same as 4. plus sharpen
echo -e "METHOD 5…" >>${OUTPUT_LOG} 2>&1
SCHEME_5="
(let*
    (
        (image (car (file-png-load RUN-NONINTERACTIVE \"${OUTPUT_FILE_NO_ALPHA}\" \"${OUTPUT_FILE_NO_ALPHA}\") ) )
        (drawable (car (gimp-image-active-drawable image)))
        ;(selection (car (gimp-image-get-selection image)))
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
    (gimp-file-save RUN-NONINTERACTIVE image drawable \"${OUTPUT_FILE_5}\" \"${OUTPUT_FILE_5}\" )
)
"
${GIMP_BIN} -i -b "${SCHEME_5}" -b "(gimp-quit 0)" >>${OUTPUT_LOG} 2>&1

###############################################################################

echo -e "Scraping glue from fingers…"
echo -e "Look in '${OUTPUT_DIR}' for your sprites."