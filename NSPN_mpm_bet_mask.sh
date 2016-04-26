#!/bin/bash

#==============================================================================
# Created by Kirstie Whitaker on 13th April 2016 
#
# DESCRIPTION:
#    This code conducts a brain and head extraction of the PDw image to which
#      the quantitative multiparametric mapping (MPM) images have been aligned.
#      It then uses the head mask to set all voxels outside of the head to 
#      zero for the quantitative MPM images and uses the brain mask to create
#      brain extracted versions of the MPM images (where all voxels outside of
#      the brain have been set to zero.
#
# USAGE:
#    NSPN_mpm_bet_mask.sh <pdw_file>
#
# INPUTS:
#    pdw_file : Proton density weighted file to which the MPM 
#                 quantitative maps are aligned.
#
# EXPECTS:
#    The following files should be in the same directory as the 
#      input file:
#
#        R1.nii.gz         MT.nii.gz
#        R1s.nii.gz        A.nii.gz
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
# Check the input file is there
#====================================================================
pdw_file=$1

if [[ ! -f ${pdw_file} ]]; then
    echo "PDw file does not exist"
    echo "Check ${pdw_file}"
    echo "USAGE: NSPN_mpm_bet_masking.sh <pdw_file>"
    exit    
fi 

#====================================================================
# Set a couple of variables
#====================================================================
mpm_dir=`dirname ${pdw_file}`

bet_dir=${mpm_dir}/PDw_BrainExtractionOutput/

orig_filename_list=(PDw)
calc_filename_list=(A MT R1 R2s)

#====================================================================
# First convert all the input files to .nii.gz
# and make sure they're in FSL standard orientation
# I don't know how to check this so we're going to do it for
# all the files, even if the directory has already been processed
#====================================================================
echo -n "  Reorienting"
for f_name in ${orig_filename_list[@]} ${calc_filename_list[@]}; do

    echo -n " - ${f_name}"
    mpm_file=(`ls -d ${mpm_dir}/*${f_name}.nii*`)
    
    fslreorient2std ${mpm_file} ${mpm_dir}/${f_name}.nii.gz    
    
done
echo ""

#====================================================================
# Do the brain extraction on the PDw file
#====================================================================
mkdir -p ${bet_dir}
  
echo "  Conducting brain and head extraction"

# Run brain extraction with the -A flag to get skull and
# scalp images too
if [[ ! -f ${mpm_dir}/PDw_brain.nii.gz ]]; then
    bet ${mpm_dir}/PDw.nii.gz ${bet_dir}/PDw_brain.nii.gz -A
fi

# Erode the brain mask by 3mm
if [[ ! -f ${mpm_dir}/PDw_brain_ero3.nii.gz ]]; then
    fslmaths ${bet_dir}/PDw_brain.nii.gz -ero ${bet_dir}/PDw_brain_ero3.nii.gz
fi
            
#====================================================================
# Now make the brain and head files for each of the
# calculated MPM files
#====================================================================
echo -n "  Applying masks"
for f_name in PDw ${calc_filename_list[@]}; do

    # Don't run if it's already complete!
    if [[ ! -f ${mpm_dir}/${f_name}_head.nii.gz ]]; then
        echo -n " - ${f_name}"
        fslmaths ${bet_dir}/PDw_brain_ero3.nii.gz \
                    -bin \
                    -mul ${mpm_dir}/${f_name}.nii.gz \
                    ${mpm_dir}/${f_name}_brain.nii.gz
                    
        fslmaths ${bet_dir}/ \
                    -bin \
                    -mul ${mpm_dir}/${f_name}.nii.gz \
                    ${mpm_dir}/${f_name}_head.nii.gz
    fi
done # Close the mpm calculated file loop
echo ""

#====================================================================
# All done!
#====================================================================