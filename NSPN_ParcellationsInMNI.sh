#!/bin/bash

#====================================================================
# Created by Kirstie Whitaker on 25th April 2016
#
# DESCRIPTION:
#    This code moves a given parcellation into MNI space.
#
# INPUTS:
#    subjects_dir : The directory containing the fsaverageSubP and MNI
#                     recon-all folders.
#    MNI_id       : The name of the MNI recon-all folder (eg: MNI152_T1_1mm).
#                     This folder should be inside the subjects_dir.
#    aparc_name   : The name of the parcellation you want to move.
#                     Eg: 500.aparc or HPC.aparc
#
# EXPECTS:
#    The fsaverageSubP folder must contain the left and right hemisphere
#      aparc files you'd like to move to MNI space.
#    The MNI brain has been run through recon-all.
#
# OUTPUTS:
#    The following files are created inside the parcellation directory
#      the MNI recon-all directory
#
#        parcellation/<aparc_name>.nii.gz
#        parcellation/<aparc_name>_origspace.nii.gz
#        label/lh.<aparc_name>.annot
#        label/rh.<aparc_name>.annot
#
#====================================================================

#====================================================================
# USAGE: NSPN_ParcellationsInMNI.sh <subjects_dir> <MNI_id> <aparc_name>
#====================================================================
function usage {

    echo "USAGE: NSPN_ParcellationsInMNI.sh <subjects_dir> <MNI_id> <aparc_name>"
    echo "       <subjects_dir> is directory containing the fsaverageSubP"
    echo "         and MNI recon-all folders"
    echo "       <MNI_id> is name of the MNI recon-all folder"
    echo "         (eg: MNI152_T1_1mm) which should be inside the subjects_dir."
    echo "       <aparc_name> is the name of the parcellation you want to move"
    echo "         (eg: 500.aparc or HPC.aparc)."
    echo ""
    echo "DESCRIPTION: This code moves a given parcellation into MNI space."
    exit
}

#====================================================================
# READ IN COMMAND LINE ARGUMENTS
#====================================================================

subjects_dir=$1
mni_id=$2
aparc_name=$3

if [[ ! -d ${subjects_dir} ]]; then
    echo "**** SUBJECTS DIRECTORY does not exist ****"
    usage
fi

if [[ ! -d ${subjects_dir}/${mni_id} ]]; then
    echo "**** MNI recon-all directory doesn't exist ****"
    usage
fi

if [[ ! -f ${subjects_dir}/fsaverageSubP/label/lh.${aparc_name}.annot \
      || ! -f ${subjects_dir}/fsaverageSubP/label/rh.${aparc_name}.annot ]]; then
    echo "**** ${aparc_name} annot files don't exist in fsaverageSubP folder ****"
    usage
fi

#====================================================================
# SET A COUPLE OF USEFUL VARIABLES
#====================================================================
fsaverage_subid=fsaverageSubP
SUBJECTS_DIR=${subjects_dir}

#====================================================================
# PRINT TO SCREEN WHAT WE'RE DOING
#====================================================================
echo "==== Transform parcellation to MNI space ===="

#====================================================================
# Transform the fsaverage parcellation to MNI surface space
#====================================================================
# Loop through both hemispheres
for hemi in lh rh; do

    if [[ ! -f ${SUBJECTS_DIR}/${mni_id}/label/${hemi}.${aparc_name}.annot ]]; then

        echo "    Creating parcellation in MNI space (${hemi})"
        # Transform the surface parcellation from fsaverage space
        # to MNI space
        mri_surf2surf --srcsubject ${fsaverage_subid} \
                        --sval-annot ${SUBJECTS_DIR}/${fsaverage_subid}/label/${hemi}.${aparc_name} \
                        --trgsubject ${mni_id}/ \
                        --trgsurfval ${SUBJECTS_DIR}/${mni_id}/label/${hemi}.${aparc_name} \
                        --hemi ${hemi}
    else
        echo "    ${hemi} ${aparc_name} parcellation already created"
    fi
done

#====================================================================
# Transform the MNI surface parcellation to MNI volume space
#====================================================================
if [[ ! -f ${SUBJECTS_DIR}/${mni_id}/parcellation/${aparc_name}.nii.gz ]]; then

    # Transform MNI surface parcellation to MNI volume parcellation
    echo "    Creating ${aparc_name} parcellation volume"
    mkdir -p ${SUBJECTS_DIR}/${mni_id}/parcellation/
    mri_aparc2aseg --s ${mni_id} \
                    --o ${SUBJECTS_DIR}/${mni_id}/parcellation/${aparc_name}.nii.gz \
                    --annot ${aparc_name} \
                    --rip-unknown \
                    --hypo-as-wm
else
    echo "    ${aparc_name} parcellation volume already created"

fi

#====================================================================
# Transform the MNI volume parcellation to original MNI volume space
#====================================================================
cd $SUBJECTS_DIR/<subjid>/mri
mri_label2vol --seg aseg.mgz --temp rawavg.mgz --o aseg-in-rawavg.mgz --regheader aseg.mgz

if [[ ! -f ${SUBJECTS_DIR}/${mni_id}/parcellation/${aparc_name}_origspace.nii.gz ]]; then

    # Transform volume parcellation to line up with original input MNI volume
    echo "    Moving ${aparc_name} parcellation volume to original space"
    mri_label2vol --seg ${SUBJECTS_DIR}/${mni_id}/parcellation/${aparc_name}.nii.gz \
                    --temp ${SUBJECTS_DIR}/${mni_id}/mri/rawavg.mgz \
                    --o ${SUBJECTS_DIR}/${mni_id}/parcellation/${aparc_name}_origspace.nii.gz \
                    --regheader ${SUBJECTS_DIR}/${mni_id}/mri/aseg.mgz

else
    echo "    ${aparc_name} parcellation volume already transformed to original space"

fi
#====================================================================
# All done!
#====================================================================
