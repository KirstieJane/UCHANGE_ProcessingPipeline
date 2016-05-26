#!/bin/bash

#====================================================================
# Created by Kirstie Whitaker on 26th May 2016 
#
# DESCRIPTION:
#    This code finds an MPRAGE highres.nii.gz file and runs 
#      freesurfer's recon-all on it.
#
# INPUTS:
#    study_dir : The directory containing the SUB_DATA folder which
#                  itself contains directories named by sub_id.
#    sub_id    : Subject ID. These folders should be inside SUB_DATA
#                  and themselves contain a directory called MPRAGE.
#    occ       : The scan occasion. One of baseline, CBSU, UCL, 
#                  WBIC, t1 or t2. This directory is found inside 
#                  the subject's MPRAGE directory.
#
# EXPECTS:
#    A file called highres.nii.gz to be inside the MPRAGE/${occ}
#     directory.
#
# OUTPUTS:
#
#====================================================================

#====================================================================
# USAGE: NSPN_Reconall_MPRAGE.sh <study_dir> <sub> <occ>
#====================================================================
function usage {

    echo "USAGE: NSPN_Reconall_MPRAGE.sh <study_dir> <sub> <occ>"
    echo "       <study_dir> is the parent directory to the SUB_DATA"
    echo "         directory and expects to find SUB_DATA inside it"
    echo "         and then the standard NSPN directory structure."
    echo "       <sub> is the subject ID that corresponds to a"
    echo "          folder in the SUB_DATA directory."
    echo "       <occ> is the scan occasion and is one of baseline,"
    echo "         CBSU, WBIC, UCL, t1_AP, t1_PA, t1_RL, t2_AP or"
    echo "         t2_PA"
    echo ""
    echo "DESCRIPTION: This code finds an MPRAGE highres.nii.gz file"
    echo "             and runs freesurfer's recon-all on it."
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
highres_file=${study_dir}/SUB_DATA/${sub}/MPRAGE/${occ}/highres.nii.gz

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
# If the process has already started then keep going

if [[ -f  ${SUBJECTS_DIR}/${occ}/mri/nu.mgz ]]; then
    
    recon-all -subjid ${occ} \
              -sd ${SUBJECTS_DIR} \
              -make all
else

    rm -rf ${SUBJECTS_DIR}/${occ}
    mkdir -p ${SUBJECTS_DIR}

    recon-all -i ${highres_file} \
                -subjid ${occ} \
                -sd ${SUBJECTS_DIR} \
                -deface \
		-all

fi

