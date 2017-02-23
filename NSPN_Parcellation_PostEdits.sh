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
#    occ       : The scan occasion. One of baseline, 6_month, 1st_follow_up,
#                  CBSU, UCL, WBIC, t1 and t2. This directory contains the
#                  output of recon-all and is found inside the subject's SURFER
#                  directory.
#
# EXPECTS:
#    All the output files from recon-all should exist in the
#      realavent occasion directory in the subject's SURFER
#      directory.
#    All quality control editing should have been conducted.
#    The fsaverageSubP directory containing the standard space
#      parcellation should exist inside the SUB_DATA directory.
#
# OUTPUTS:
#    The following files are created inside the relavent occasion
#      directory in the subject's SURFER directory
#
#        parcellation/500.aparc.nii.gz
#        label/lh.500.aparc.annot
#        label/rh.500.aparc.annot
#
#====================================================================

#====================================================================
# USAGE: NSPN_Parcellation_PostEdits.sh <study_dir> <sub> <occ>
#====================================================================
function usage {

    echo "USAGE: NSPN_Parcellation_PostEdits.sh <study_dir> <sub> <occ>"
    echo "       <study_dir> is the parent directory to the SUB_DATA"
    echo "         directory and expects to find SUB_DATA inside it"
    echo "         and then the standard NSPN directory structure."
    echo "       <sub> is the subject ID that corresponds to a"
    echo "          folder in the SUB_DATA directory."
    echo "       <occ> is the scan occasion and is one of baseline,"
    echo "          6_month, 1st_follow_up, CBSU, WBIC, UCL, t1 and t2"
    echo ""
    echo "DESCRIPTION: This code creates the parcellation for each"
    echo "             person in their freesurfer space, and should"
    echo "             be applied after recon-all edits have been"
    echo "             completed"
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
# SET A COUPLE OF USEFUL VARIABLES
#====================================================================
sub_data_dir=${study_dir}/SUB_DATA
fsaverage_subid=fsaverageSubP

#====================================================================
# PRINT TO SCREEN WHAT WE'RE DOING
#====================================================================
echo "==== Create individual parcellations ===="

#====================================================================
# Transform the fsaverage parcellations
#====================================================================

SUBJECTS_DIR=${sub_data_dir}
subjid=${occ}

# Loop through the different parcellations
# Specifically:
#    * 500.aparc is the NSPN500 parcellation which splits the brain
#        into 308 regions that are constrained to be within
#        Deskian-Killiany atlas regions and no more than 500mm^2
#        in surface area
#    * Yeo2001_7Networks_N1000 is the Yeo parcellation with 7 networks
#        that ships with freesurfer (Yeo, 2011, J Neurophysiol)
#    * HCP is the parcellation published by the Human Connectome
#        Project (Glasser et al, 2016, Nature)

for parcellation in 500.aparc Yeo2011_7Networks_N1000 HCP; do

    # Create the surface parcellations in subject space
    echo "    Transforming ${parcellation} parcellation"

    # Loop through both hemispheres
    for hemi in lh rh; do

        # Check to see if output file already exists
        if [[ ! -f ${SUBJECTS_DIR}/${sub}/SURFER/${subjid}/label/${hemi}.${parcellation}.annot ]]; then

            echo "        Creating ${hemi} ${parcellation} surface in subject space"
            # Transform the surface parcellation from fsaverage space
            # to indiviual native space
            mri_surf2surf --srcsubject ${fsaverage_subid} \
                            --sval-annot ${SUBJECTS_DIR}/${fsaverage_subid}/label/${hemi}.${parcellation} \
                            --trgsubject ${sub}/SURFER/${subjid} \
                            --trgsurfval ${SUBJECTS_DIR}/${sub}/SURFER/${subjid}/label/${hemi}.${parcellation} \
                            --hemi ${hemi}
        else
            echo "        ${hemi} ${parcellation} surface already in subject space"
        fi
    done

    # Check to see if volume parcellation file already exists
    if [[ ! -f ${SUBJECTS_DIR}/${sub}/SURFER/${subjid}/parcellation/${parcellation}.nii.gz ]]; then

        # Transform indivual surface parcellation to individual volume parcellation
        echo "        Creating ${parcellation} volume in subject space"
        mkdir -p ${SUBJECTS_DIR}/${sub}/SURFER/${subjid}/parcellation/
        mri_aparc2aseg --s ${sub}/SURFER/${subjid} \
                        --o ${SUBJECTS_DIR}/${sub}/SURFER/${subjid}/parcellation/${parcellation}.nii.gz \
                        --annot ${parcellation} \
                        --rip-unknown \
                        --hypo-as-wm
    else
        echo "        ${parcellation} volume in subject space already in subject space"

    fi

done
#====================================================================
# All done!
#====================================================================
