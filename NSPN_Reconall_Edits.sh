#!/bin/bash

#====================================================================
# Created by Kirstie Whitaker on 26th May 2016 
#
# DESCRIPTION:
#    This code takes into account the control points and white matter
#      edits in the subjects SURFER directory (for a particular 
#      occasion) and runs auto-recon2 and auto-recon3 on the data.
#      It is suitable for use after either NSPN_Reconall_MPM.sh or 
#      NSPN_Reconall_MPRAGE.sh.
#
# INPUTS:
#    study_dir : The directory containing the SUB_DATA folder which
#                  itself contains directories named by sub_id.
#    sub_id    : Subject ID. These folders should be inside SUB_DATA
#                  and themselves contain a directory called SURFER.
#    occ       : The scan occasion. One of baseline, 6_month, 
#                  1st_follow_up, CBSU, UCL, WBIC, t1 or t2.
#                  This directory is found inside the subject's 
#                  SURFER directory.
#
# EXPECTS:
#    NSPN_Reconall_MPM.sh or NSPN_Reconall_MPRAGE.sh must have been
#      completed.
#
# OUTPUTS:
#
#====================================================================

#====================================================================
# USAGE: NSPN_Reconall_Edits.sh <study_dir> <sub_id> <occ>
#====================================================================
function usage {

    echo "USAGE: NSPN_Reconall_Edits.sh <study_dir> <sub_id> <occ>"
    echo "       <study_dir> is the directory containing the SUB_DATA"
    echo "         folder which itself contains directories named by sub_id"
    echo "       <sub_id> is the subject ID that corresponds to a"
    echo "          folder in the SUB_DATA directory."
    echo "       <occ> is the scan occasion and is one of baseline,"
    echo "         6_month, 1st_follow_up, CBSU, WBIC, UCL, t1 or t2"
    echo ""
    echo "DESCRIPTION: This code takes into account the control points"
    echo "               and white matter edits in the subjects SURFER"
    echo "               directory (for a particular occasion) and runs"
    echo "               auto-recon2 and auto-recon3 on the data."
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
nu_file=${study_dir}/SUB_DATA/${sub}/SURFER/${occ}/mri/nu.mgz

if [[ ! -f ${nu_file} ]]; then
    echo "nu.mgz file doesn't exist: ${nu_file}"
    echo "- CHECK to make sure recon-all has run"
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
echo "==== Running Reconall Edits ===="

#====================================================================
# AND GO!
#====================================================================
recon-all -subjid ${occ} -sd ${SUBJECTS_DIR} -autorecon2-cp -autorecon3 


