#!/bin/bash

#====================================================================
# Created by Kirstie Whitaker on 26th May 2016
# Updated on 12 February 2019
#
# DESCRIPTION:
#    This code finds the MPM R1_head.nii.gz file and runs
#      freesurfer's recon-all on it, applying the R1_brain.nii.gz 
#      mask instead of allowing freesurfer to do its standard skull 
#      strip.
#    The update in Feburary 2019 makes much better use of "make"
#      and allows for the possibility that you might want to start
#      totally from scratch by deleting orig.mgz while keeping
#      the surfaces that already exist.
#
# INPUTS:
#    study_dir : The directory containing the SUB_DATA folder which
#                  itself contains directories named by sub_id.
#    sub_id    : Subject ID. These folders should be inside SUB_DATA
#                  and themselves contain a directory called MPM.
#    occ       : The scan occasion. One of baseline, CBSU, UCL, 
#                  WBIC, t1 or t2. This directory is found inside 
#                  the subject's MPM directory.
#
# EXPECTS:
#    NSPN_mpm_bet_mask must have been completed.
#
# OUTPUTS:
#
#====================================================================

#====================================================================
# USAGE: NSPN_Reconall_MPM.sh <study_dir> <sub> <occ>
#====================================================================
function usage {

    echo "USAGE: NSPN_Reconall_MPM.sh <study_dir> <sub> <occ>"
    echo "       <study_dir> is the parent directory to the SUB_DATA"
    echo "         directory and expects to find SUB_DATA inside it"
    echo "         and then the standard NSPN directory structure."
    echo "       <sub> is the subject ID that corresponds to a"
    echo "          folder in the SUB_DATA directory."
    echo "       <occ> is the scan occasion and is one of baseline,"
    echo "         CBSU, WBIC, UCL, t1 or t2"
    echo ""
    echo "DESCRIPTION: This code finds the MPM R1_head.nii.gz file"
    echo "               and runs freesurfer's recon-all on it,"
    echo "               applying the R1_brain.nii.gz mask instead of"
    echo "               allowing freesurfer to do its standard skull"
    echo "               strip"
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
highres_file=${study_dir}/SUB_DATA/${sub}/MPM/${occ}/R1_head.nii.gz

if [[ ! -f ${highres_file} ]]; then
    echo "Highres file doesn't exist - CHECK ${highres_file}"
    exit
fi

#====================================================================
# DEFINE VARIABLES
#====================================================================
# Set the subjects dir and subject id variables
surfer_dir=${study_dir}/SUB_DATA/${sub}/SURFER/${occ}/
SUBJECTS_DIR=`dirname ${surfer_dir}`
surf_sub=${occ}


#====================================================================
# PRINT TO SCREEN WHAT WE'RE DOING
#====================================================================
echo "==== Running Reconall ===="

#====================================================================
# AND GO!
#====================================================================

# If the surfer directory doesn't exist, then start from the very beginnning
if [[ ! -d ${SUBJECTS_DIR}/${occ} ]]; then

    mkdir -p ${SUBJECTS_DIR}

    # Run most of autorecon1 but then copy across the 
    # R1_brain mask as this is usually more reliable than
    # the ones that freesurfer create from R1 data.
    recon-all -i ${SUBJECTS_DIR}/../MPM/${occ}/R1_head.nii.gz \
                -subjid ${occ} \
                -sd ${SUBJECTS_DIR} \
                -motioncor \
                -talairach \
                -normalization \
                -deface

    mri_convert ${SUBJECTS_DIR}/../MPM/${occ}/R1_brain.nii.gz \
                ${SUBJECTS_DIR}/${occ}/mri/brainmask.mgz \
                --conform
                    
    cp ${SUBJECTS_DIR}/${occ}/mri/brainmask.mgz \
        ${SUBJECTS_DIR}/${occ}/mri/brainmask.auto.mgz 

    recon-all -subjid ${occ} -sd ${SUBJECTS_DIR} -nuintensitycor

# If the processing hasn't got to the nu.mgz point, then we'll
# start it from the beginning.
# We USED to delete the whole folder...which meant that none of what
# had been used could be re-used. So now we're just going to
# run those first few steps again.
# Note that these steps DO NOT USE MAKE.
elif [[ ! -f ${SUBJECTS_DIR}/${occ}/mri/nu.mgz ]]; then

    recon-all -subjid ${occ} \
              -sd ${SUBJECTS_DIR} \
              -motioncor \
              -talairach \
              -normalization \
              -deface

    mri_convert ${SUBJECTS_DIR}/../MPM/${occ}/R1_brain.nii.gz \
                ${SUBJECTS_DIR}/${occ}/mri/brainmask.mgz \
                --conform
                    
    cp ${SUBJECTS_DIR}/${occ}/mri/brainmask.mgz \
        ${SUBJECTS_DIR}/${occ}/mri/brainmask.auto.mgz 

    recon-all -subjid ${occ} -sd ${SUBJECTS_DIR} -nuintensitycor

# If the nu.mgz file does exist, run autorecon1 with make
else

  recon-all -subjid ${occ} \
              -sd ${SUBJECTS_DIR} \
              -make all

fi

# For all of the options above, run autorecon2 and autorecon3 with make
recon-all -subjid ${occ} -sd ${SUBJECTS_DIR} -make autorecon2 autorecon3
