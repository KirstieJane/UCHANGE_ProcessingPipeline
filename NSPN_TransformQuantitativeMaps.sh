#!/bin/bash

#====================================================================
# Created by Kirstie Whitaker on 25th April 2016 
#
# DESCRIPTION:
#    This code takes a freesurfer directory and it's fellow MPM 
#      directory and transforms all MPM and DTI measures so they
#      are all in the same space.
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
#    NSPN_mpm_bet_mask.sh must also have been completed and the MPM
#      directory should be inside the subject's directory at the same
#      level as the SURFER dir.
#
# OUTPUTS:
#   At the end the ${sub_id}SURFER/${occ}/mri directory will contain:
#      A.mgz    MT.mgz  R1.mgz  R2s.mgz
#      FA.mgz   L1.mgz  L23.mgz MD.mgz  MO.mgz
#
#====================================================================

#====================================================================
# USAGE: NSPN_TransformQuantitativeMaps.sh <study_dir> <sub> <occ>
#====================================================================
function usage {

    echo "USAGE: NSPN_TransformQuantitativeMaps.sh <study_dir> <sub> <occ>"
    echo "Note that data dir expects to find SUB_DATA within it"
    echo "and then the standard NSPN directory structure"
    echo ""
    echo "DESCRIPTION: This code will register the DTI B0 file to freesurfer space,"
    echo "apply this registration to the DTI measures in the <dti_dir>/FDT folder,"
    echo "transform the MPM files to freesurfer space." 
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
mpm_dir=${data_dir}/SUB_DATA/${sub}/MPM/${occ}/

SUBJECTS_DIR=${surfer_dir}/../
surf_sub=`basename ${surfer_dir}`

#====================================================================
# PRINT TO SCREEN WHAT WE'RE DOING
#====================================================================
echo "==== Transform Quantitative Maps to Freesurfer Space ===="

#=============================================================================
# DON'T BOTHER IF THERE'S NO DATA!
#=============================================================================
if [[ ! -f ${surfer_dir}/mri/T1.mgz ]]; then
    echo "No T1.mgz file in surfer directory. Exiting"
    exit
fi
    
#====================================================================
# TRANSFORM DTI MEASURES FILES TO FREESURFER SPACE
#====================================================================
# If the dti measure file doesn't exist yet in the 
# <surfer_dir>/mri folder then you have to make it
for measure in FA MD MO L1 L23; do

    measure_file_dti=${surfer_dir}/dmri/dtifit_${measure}.nii.gz
    
    # If the file doesn't exist, then just skip this whole 
    # section!
    if [[ ! -f ${measure_file_dti} && ${measure} != "L23" ]]; then 
        echo "No ${measure} file in dmri folder - skipping"
        continue

    # If the measure you're looking for is L23 then you need to make
    # that one from L2 and L23. The first step is checking that those
    # two files exist! 
    elif [[ ! -f ${measure_file_dti} && ${measure} == "L23" ]]; then 
        if [[ -f ${measure_file_dti/L23.nii/L2.nii} && -f ${measure_file_dti/L23.nii/L3.nii} ]]; then
            fslmaths ${measure_file_dti/L23.nii/L2.nii} \
                 -add ${measure_file_dti/L23.nii/L3.nii} \
                 -div 2 \
                 ${measure_file_dti}
              
        else
            echo "Either L2 or L3 file in dmri folder is missing - skipping"
            continue
        fi
    fi
    
    # If the measure file has particularly small values
    # then multiply this file by 1000 first
    if [[ "MD L1 L23" =~ ${measure} ]]; then
        if [[ ! -f ${measure_file_dti/.nii/_mul1000.nii} ]]; then
            fslmaths ${measure_file_dti} \
                      -mul 1000 \
                      ${measure_file_dti/.nii/_mul1000.nii}
        fi
        measure_file_dti=${measure_file_dti/.nii/_mul1000.nii}
    fi
    
    # Now transform this file to freesurfer space
    if [[ ! -f ${surfer_dir}/mri/${measure}.mgz ]]; then
        
        echo "    Registering ${measure} file to freesurfer space"
        mri_vol2vol --mov ${measure_file_dti} \
                    --targ ${surfer_dir}/mri/T1.mgz \
                    --o ${surfer_dir}/mri/${measure}.mgz \
                    --fsl ${surfer_dir}/dmri/xfms/diff2anatorig.bbr.mat \
                    --no-save-reg

    else
        echo "    ${measure} file already in freesurfer space"
       
    fi
done


#=============================================================================
# TRANSFORM MPM MEASURES FILES TO FREESURFER SPACE
#=============================================================================
# If the mpm measure file doesn't exist yet in the <surfer_dir>/mri folder
# then you have to make it

# Loop through the mpm outputs that you're interested in
for mpm in R1 MT R2s A; do
    mpm_file=${mpm_dir}/${mpm}_head.nii.gz

    # If the file doesn't exist, then just skip this whole 
    # section!
    if [[ ! -f ${mpm_file} ]]; then 
        echo "No ${mpm}_head.nii.gz file in MPM folder - skipping"
        continue

    else
        # If the measure file has particularly small values
        # then multiply this file by 1000 first
        if [[ ${mpm} == "R2s" || ${mpm} == "MT" ]]; then
            if [[ ! -f ${mpm_file/.nii/_mul1000.nii} ]]; then
                fslmaths ${mpm_file} \
                         -mul 1000 \
                         ${mpm_file/.nii/_mul1000.nii}
            fi
            mpm_file=${mpm_file/.nii/_mul1000.nii}
        fi
        
        if [[ ! -f ${surfer_dir}/mri/${mpm}.mgz ]]; then
            echo "    Registering ${mpm} file to freesurfer space"
            # Align the mgz file to "freesurfer" anatomical space
            mri_vol2vol --mov ${mpm_file} \
                        --targ ${surfer_dir}/mri/T1.mgz \
                        --regheader \
                        --o ${surfer_dir}/mri/${mpm}.mgz \
                        --no-save-reg
        else
            echo "    ${mpm} file already in freesurfer space"
        fi
    fi
done

#=============================================================================
# Well done. You're all finished :)
#=============================================================================
