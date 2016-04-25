#!/bin/bash

#====================================================================
# Created by Kirstie Whitaker on 25th April 2016 
#
# DESCRIPTION:
#    This code takes a freesurfer directory and runs the appropriate 
#      commands to parcellate the volume into the six lobes defined
#      by freesurfer using the --lobesStrict flag.
#    For more information see: 
#      https://surfer.nmr.mgh.harvard.edu/fswiki/CorticalParcellation
#
# USAGE:
#    NSPN_AssignLobes.sh <surfer_dir>
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
#    The LobesStrictLUT.txt file should be in the same directory as 
#      this script.
#    Recon-all and quality control edits must have been completed.
#
# OUTPUTS:
#    All output are in the same directory as the input file.
#    A sub-directory called PDw_bet is created and contains all the
#      files created by FSL's bet command
#
#       R1_head.nii.gz     R1_brain.nii.gz
#       R2s_head.nii.gz    R2s_brain.nii.gz
#       MT_head.nii.gz     MT_brain.nii.gz
#       A_head.nii.gz      A_brain.nii.gz
#
#====================================================================

#====================================================================
# USAGE: NSPN_AssignLobes.sh <study_dir> <sub> <occ>
#====================================================================
function usage {

    echo "USAGE: NSPN_AssignLobes.sh <study_dir> <sub> <occ>"
    echo "       <study_dir> is the parent directory to the SUB_DATA"
    echo "         directory and expects to find SUB_DATA inside it"
    echo "         and then the standard NSPN directory structure."
    echo "       <sub> is the subject ID that corresponds to a"
    echo "          folder in the SUB_DATA directory."
    echo "       <occ> is the scan occasion and is one of baseline,"
    echo "         CBSU, WBIC and UCL"
    echo ""
    echo "DESCRIPTION: This code takes a freesurfer directory and"
    echo "             runs the appropriate commands to parcellate"
    echo "             the volume into the six lobes defined by"
    echo "             freesurfer using the --lobesStrict flag."
    echo "             The code should be applied after recon-all"
    echo "             edits have been completed"
    exit
} 

#====================================================================
# READ IN COMMAND LINE ARGUMENTS
#====================================================================
study_dir=$1
sub=$2
occ=$3

if [[ ! -d ${study_dir} ]]; then
    echo "**** STUDY DIRECTORY does not exist ****"
    usage
fi

if [[ -z ${sub} ]]; then
    echo "**** No subject ID given ****"
    usage
fi

if [[ -z ${occ} ]]; then
    echo "**** No occasion given ****"
    usage
fi
    
#====================================================================
# CHECK THE INPUTS
#====================================================================
surfer_dir=${study_dir}/SUB_DATA/${sub}/SURFER/${occ}

if [[ ! -d ${surfer_dir} ]]; then
    echo "Surfer dir doesn't exist - CHECK ${surfer_dir}"
    exit
fi

#====================================================================
# DEFINE VARIABLES
#====================================================================
# Set the subjects dir and subject id variables
SUBJECTS_DIR=${surfer_dir}/../
surf_sub=${occ}
lobes_ctab=`dirname ${0}`/LobesStrictLUT.txt

#=============================================================================
# COMBINE LABELS
#=============================================================================
# First you have to pull together the labels
# from the surface annotation files
for hemi in lh rh; do
    if [[ ! -f ${surfer_dir}/label/${hemi}.lobesStrict ]]; then
        mri_annotation2label --subject ${surf_sub} \
                             --hemi ${hemi} \
                             --lobesStrict \
                             ${surfer_dir}/label/${hemi}.lobesStrict
    fi
done

#=============================================================================
# LABEL WHITE MATTER
#=============================================================================
# Transform the surface annotation into a segmentation volume
# and label the white matter up to 5mm beneath the lobes
if [[ ! -f ${surfer_dir}/mri/lobes+aseg.mgz ]]; then

    mri_aparc2aseg --s ${surf_sub} \
                --labelwm \
                --rip-unknown \
                --annot lobesStrict \
                --o ${surfer_dir}/mri/lobes+aseg.mgz
fi


