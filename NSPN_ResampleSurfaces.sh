#!/bin/bash

#====================================================================
# Created by Kirstie Whitaker on 25th April 2016
#
# DESCRIPTION:
#    This code takes a freesurfer directory and calculates 9 surfaces
#      between the white and pial surfaces at fractional depths of
#      10% thickness, and also calculates 19 steps of 0.1mm depth
#      from the grey/white matter boundary into white matter
#
# INPUTS:
#    study_dir : The directory containing the SUB_DATA folder which
#                  itself contains directories named by sub_id.
#    sub_id    : Subject ID. These folders should be inside SUB_DATA
#                  and themselves contain directories called SURFER
#                  and MPM.
#    occ       : The scan occasion. One of baseline, CBSU, UCL and
#                  WBIC. This directory contains the output of
#                  recon-all and is found inside the subject's SURFER
#                  directory.
#
# EXPECTS:
#    Recon-all, trac-all and quality control edits must have been
#      completed.
#
# OUTPUTS:
#
#====================================================================

#====================================================================
# USAGE: NSPN_ExtractRois.sh <study_dir> <sub> <occ>
#====================================================================
function usage {

    echo "USAGE: NSPN_ResampleSurfaces.sh <study_dir> <sub> <occ>"
    echo "Note that data dir expects to find SUB_DATA within it"
    echo "and then the standard NSPN directory structure"
    echo ""
    echo "DESCRIPTION: This code takes a freesurfer directory and "
    echo "calculates 9 surfaces between the white and pial surfaces"
    echo "at fractional depths of 10% thickness, and also calculates"
    echo "19 steps of 0.1mm depth from the grey/white matter boundary"
    echo "into white matter."
    exit
}

#====================================================================
# CHECK INPUTS
#====================================================================
data_dir=$1
sub=$2
occ=$3

if [[ ! -d ${data_dir} ]]; then
    echo "${data_dir} is not a directory, please check"
    print_usage=1
fi

if [[ -z ${sub} ]]; then
    echo "No subject id provided"
    print_usage=1
fi

if [[ -z ${occ} ]]; then
    echo "No occ provided"
    print_usage=1
fi

if [[ ${print_usage} == 1 ]]; then
    usage
fi

#=============================================================================
# SET A COUPLE OF USEFUL VARIABLES
#=============================================================================
surfer_dir=${data_dir}/SUB_DATA/${sub}/SURFER/${occ}/

SUBJECTS_DIR=${surfer_dir}/../
surf_sub=`basename ${surfer_dir}`


#====================================================================
# PRINT TO SCREEN WHAT WE'RE DOING
#====================================================================
echo "==== Resample Surfaces ===="

#=============================================================================
# DON'T BOTHER IF THERE'S NO DATA!
#=============================================================================
if [[ ! -f ${surfer_dir}/mri/T1.mgz ]]; then
    echo "No T1.mgz file in surfer directory. Exiting"
    exit
fi

#=============================================================================
# RESAMPLE THE SURFACES
#=============================================================================

# Loop over both left and right hemispheres
for hemi in lh rh; do
    echo " Hemi: ${hemi}"

    # Loop through a bunch of different fractional depths
    # from the white matter surface

    for frac in `seq -f %+02.2f 0.0 0.1 1.0`; do
        echo -n "  frac: ${frac}"

        # You don't have to create a surface for the white matter and
        # pial surfaces which are the "special cases" of frac == 0.0 and
        # 1.0 respectively
        if [[ ${frac} == +1.00 ]]; then
            cp ${surfer_dir}/surf/${hemi}.pial \
                ${surfer_dir}/surf/${hemi}.white_frac${frac}_expanded
        elif [[ ${frac} == +0.00 ]]; then
            cp ${surfer_dir}/surf/${hemi}.white \
                ${surfer_dir}/surf/${hemi}.white_frac${frac}_expanded
        fi

        # Create the interim surface by expanding the white matter surface by
        # the given fraction of thickness
        echo -n " expanding surface"
        if [[ ! -f ${surfer_dir}/surf/${hemi}.white_frac${frac}_expanded ]]; then
            mris_expand -thickness \
                            ${surfer_dir}/surf/${hemi}.white \
                            ${frac} \
                            ${surfer_dir}/surf/${hemi}.white_frac${frac}_expanded
        fi
        echo " - done!"

    done # Close the fraction of cortical thickness loop

    # Now loop through the different absolute depths
    # from the grey/white matter boundary
    for dist in `seq -f %+02.2f -2 0.1 -0.1`; do
        echo -n "  dist: ${dist}"

        # Create the interim surface by expanding the white matter surface by
        # the given fraction of thickness
        echo -n " expanding surface into white matter"
        if [[ ! -f ${surfer_dir}/surf/${hemi}.white_dist${dist}_expanded ]]; then
            mris_expand ${surfer_dir}/surf/${hemi}.white \
                            ${dist} \
                            ${surfer_dir}/surf/${hemi}.white_dist${dist}_expanded
        fi
        echo " - done!"

    done # Close the absolute distance from grey/white matter boundary loop
    #echo -ne "\n" # Close the text string
done # Close hemi loop

#=============================================================================
# Well done. You're all finished :)
#=============================================================================
