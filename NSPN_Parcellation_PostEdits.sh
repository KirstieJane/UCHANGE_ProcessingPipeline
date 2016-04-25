#!/bin/bash

#====================================================================
# Created by Kirstie Whitaker on 25th April 2016 
#
# DESCRIPTION:
#    This code creates the 308 parcellation for each person in their
#      freesurfer space, and should be applied after recon-all edits 
#      have been completed.
#
# INPUTS:
#    study_dir : The directory containing the SUB_DATA folder which
#                  itself contains directories named by sub_id.
#    sub_id    : Subject ID. These folders should be inside SUB_DATA
#                  and themselves contain directories called SURFER
#                  and MPM.
#    occ       : The scan occasion. One of baseline, CBSU, UCL and 
#                  WBIC.
#
# EXPECTS:
#    All the output files from recon-all should exist.
#    The fsaverageSubP directory containing the standard space 
#      parcellation should exist inside the SUB_DATA directory.
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
# USAGE: Parcellation_PostEdits.sh <study_dir> <sub> <occ>
#====================================================================
function usage {

    echo "USAGE: NSPN_Parcellation_PostEdits.sh <study_dir> <sub> <occ>"
    echo "       <study_dir> is the parent directory to the SUB_DATA"
    echo "         directory and expects to find SUB_DATA inside it"
    echo "         and then the standard NSPN directory structure."
    echo "       <sub> is the subject ID that corresponds to a folder"
    echo "         in the SUB_DATA directory."
    echo "       <occ> is the scan occasion and is one of baseline,"
    echo "         CBSU, WBIC and UCL"
    echo ""
    echo "DESCRIPTION: This code creates the parcellation for each person"
    echo "             in their freesurfer space, and should be applied"
    echo "             after recon-all edits have been completed"
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
    
#================================================================
# Set some useful variables
#================================================================
sub_data_dir=${study_dir}/SUB_DATA
fsaverage_subid=fsaverageSubP

#================================================================
# Transform the fsaverage parcellations
#================================================================
   
SUBJECTS_DIR=${sub_data_dir}
subjid=${occ}
    
# Loop through both hemispheres
for hemi in lh rh; do
    
    if [[ ! -f ${SUBJECTS_DIR}/${sub}/SURFER/${subjid}/label/${hemi}.500.aparc.annot ]]; then
    
        # Transform the surface parcellation from fsaverage space 
        # to indiviual native space
        mri_surf2surf --srcsubject ${fsaverage_subid} \
                        --sval-annot ${SUBJECTS_DIR}/${fsaverage_subid}/label/${hemi}.500.aparc \
                        --trgsubject ${sub}/SURFER/${subjid} \
                        --trgsurfval ${SUBJECTS_DIR}/${sub}/SURFER/${subjid}/label/${hemi}.500.aparc \
                        --hemi ${hemi}
    fi
done

if [[ ! -f ${SUBJECTS_DIR}/${sub}/SURFER/${subjid}/parcellation/500.aparc.nii.gz ]]; then
    # Transform indivual surface parcellation to individual volume parcellation
    mkdir -p ${SUBJECTS_DIR}/${sub}/SURFER/${subjid}/parcellation/
    mri_aparc2aseg --s ${sub}/SURFER/${subjid} \
                    --o ${SUBJECTS_DIR}/${sub}/SURFER/${subjid}/parcellation/500.aparc.nii.gz \
                    --annot 500.aparc \
                    --rip-unknown \
                    --hypo-as-wm
fi

#====================================================================
# All done!
#====================================================================
