#!/bin/bash

#====================================================================
# Created by Kirstie Whitaker on 25th April 2016 
#
# DESCRIPTION:
#    This code takes a freesurfer directory and it's fellow MPM 
#      directory and extracts statistics from the following 
#      segmentations and parcellations for all MPM and DTI measures.
#    Segmentations:
#      
#    Parcellations:
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
#    Recon-all, trac-all (if appropriate) and quality control edits  
#      must have been completed.
#    NSPN_mpm_bet_mask.sh must also have been completed and the MPM
#      directory should be inside the subject's directory at the same
#      level as the SURFER dir.
#
# OUTPUTS:
#
#====================================================================

#====================================================================
# USAGE: NSPN_ExtractRois.sh <study_dir> <sub> <occ>
#====================================================================
function usage {

    echo "USAGE: NSPN_ExtractRois.sh <study_dir> <sub> <occ>"
    echo "Note that data dir expects to find SUB_DATA within it"
    echo "and then the standard NSPN directory structure"
    echo ""
    echo "DESCRIPTION: This code will register the DTI B0 file to freesurfer space,"
    echo "apply this registration to the DTI measures in the <dti_dir>/FDT folder,"
    echo "transform the MPM files to freesurfer space," 
    echo "and then create the appropriate <measure>_wmparc.stats and "
    echo "<measure>_aseg.stats files for each subject separately"
    echo "Finally, it will also extract surface stats from the parcellation schemes"
    exit
}

#====================================================================
# CHECK INPUTS
#====================================================================
data_dir=$1
sub=$2
occ=$3

# These colour look up tables need to be in the same directory as 
# this script. They're in the UCHANGE_ProcessingPipeline github 
# repository.
lobes_ctab=`dirname ${0}`/LobesStrictLUT.txt
parc500_ctab=`dirname ${0}`/parc500LUT.txt

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

if [[ ! -f ${lobes_ctab} ]]; then
    echo "Can't find lobes color look up table file"
    echo "Check that LobesStrictLUT.txt is in the same directory"
    echo "as this script"
    print_usage=1
fi

if [[ ! -f ${parc500_ctab} ]]; then
    echo "Can't find parc500 color look up table file"
    echo "Check that parc500LUT.txt is in the same directory"
    echo "as this script"
    print_usage=1
fi

if [[ ${print_usage} == 1 ]]; then 
    usage
fi

#=============================================================================
# SET A COUPLE OF USEFUL VARIABLES
#=============================================================================
surfer_dir=${data_dir}/SUB_DATA/${sub}/SURFER/${occ}/
mpm_dir=${data_dir}/SUB_DATA/${sub}/MPM/{occ}/

SUBJECTS_DIR=${surfer_dir}/../
surf_sub=`basename ${surfer_dir}`

#=============================================================================
# DON'T BOTHER IF THERE'S NO DATA!
#=============================================================================
if [[ ! -f ${surfer_dir}/mri/T1.mgz ]]; then
    exit
fi
    

#====================================================================
# TRANSFORM DTI MEASURES FILES TO FREESURFER SPACE
#====================================================================
# If the dti measure file doesn't exist yet in the 
# <surfer_dir>/mri folder then you have to make it
for measure in FA MD MO L1 L23; do

    measure_file_dti=${surfer_dir}/dmri/dtifit_${measure}.nii.gz
    
    # If the file doesn't exist, then skip on to the next one!
    if [[ ! -f ${measure_file_dti} ]]; then 
        echo "No ${measure} file in dmri folder - skipping"
        continue
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
                    --reg ${reg_dir}/diffB0_TO_surf.dat \
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

    if [[ -f ${mpm_file} ]]; then
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
            # Align the mgz file to "freesurfer" anatomical space
            mri_vol2vol --mov ${mpm_file} \
                        --targ ${surfer_dir}/mri/T1.mgz \
                        --regheader \
                        --o ${surfer_dir}/mri/${mpm}.mgz \
                        --no-save-reg
        fi
    fi
done

exit
    
#=============================================================================
# EXTRACT THE STATS FROM THE SEGMENTATION FILES
#=============================================================================
# Specifically this will loop through the following segmentations:
#     wmparc
#     aseg
#     lobesStrict
#     500.aparc_cortical_consecutive
#     500.aparc_cortical_expanded_consecutive_WMoverlap
#=============================================================================

#for measure in R1 MT R2s A FA MD MO L1 L23 sse synthetic; do
for measure in R1 MT R2s A FA MD MO L1 L23 sse; do
#for measure in MT; do
    if [[ -f ${surfer_dir}/mri/${measure}.mgz ]]; then
        
        echo "MEASURE: ${measure}"
        #=== wmparc
        if [[ ! -f ${surfer_dir}/stats/${measure}_wmparc.stats ]]; then
            mri_segstats --i ${surfer_dir}/mri/${measure}.mgz \
                         --seg ${surfer_dir}/mri/wmparc.mgz \
                         --ctab ${FREESURFER_HOME}/WMParcStatsLUT.txt \
                         --sum ${surfer_dir}/stats/${measure}_wmparc.stats \
                         --pv ${surfer_dir}/mri/norm.mgz
        fi
        
        #=== aseg
        if [[ ! -f ${surfer_dir}/stats/${measure}_aseg.stats ]]; then
            mri_segstats --i ${surfer_dir}/mri/${measure}.mgz \
                         --seg ${surfer_dir}/mri/aseg.mgz \
                         --sum ${surfer_dir}/stats/${measure}_aseg.stats \
                         --pv ${surfer_dir}/mri/norm.mgz \
                         --ctab ${FREESURFER_HOME}/ASegStatsLUT.txt 
        fi
        
        #=== lobesStrict
        if [[ ! -f ${surfer_dir}/stats/${measure}_lobesStrict.stats ]]; then
            mri_segstats --i ${surfer_dir}/mri/${measure}.mgz \
                         --seg ${surfer_dir}/mri/lobes+aseg.mgz \
                         --sum ${surfer_dir}/stats/${measure}_lobesStrict.stats \
                         --pv ${surfer_dir}/mri/norm.mgz \
                         --ctab ${lobes_ctab}
        
        fi
        
        #=== 500.aparc_cortical_consecutive.nii.gz
        # Extract measures from the cortical regions in the 500 parcellation
        if [[ ! -f ${surfer_dir}/stats/${measure}_500cortConsec.stats 
                && -f ${surfer_dir}/parcellation/500.aparc_cortical_consecutive.nii.gz ]]; then
            mri_segstats --i ${surfer_dir}/mri/${measure}.mgz \
                         --seg ${surfer_dir}/parcellation/500.aparc_cortical_consecutive.nii.gz  \
                         --sum ${surfer_dir}/stats/${measure}_500cortConsec.stats \
                         --pv ${surfer_dir}/mri/norm.mgz \
                         --ctab ${parc500_ctab}
        fi
        
        #=== 500.aparc_cortical_expanded_consecutive_WMoverlap
        # Only run this if there is a 500 cortical parcellation
        if [[ ! -f ${surfer_dir}/stats/${measure}_500cortExpConsecWMoverlap.stats \
                && -f ${surfer_dir}/parcellation/500.aparc_cortical_expanded_consecutive.nii.gz ]]; then
            
            # Create the overlap file if it doesn't already exist
            if [[ ! -f ${surfer_dir}/parcellation/500.aparc_cortical_expanded_consecutive_WMoverlap.nii.gz ]]; then
            
                fslmaths ${surfer_dir}/parcellation/500.aparc_whiteMatter.nii.gz \
                            -bin \
                            -mul ${surfer_dir}/parcellation/500.aparc_cortical_expanded_consecutive.nii.gz \
                            ${surfer_dir}/parcellation/500.aparc_cortical_expanded_consecutive_WMoverlap.nii.gz
            fi
            
            mri_segstats --i ${surfer_dir}/mri/${measure}.mgz \
                         --seg ${surfer_dir}/parcellation/500.aparc_cortical_expanded_consecutive_WMoverlap.nii.gz \
                         --sum ${surfer_dir}/stats/${measure}_500cortExpConsecWMoverlap.stats \
                         --pv ${surfer_dir}/mri/norm.mgz \
                         --ctab ${parc500_ctab}
        fi
        echo "===="
    else
        echo "${measure} file not transformed to Freesurfer space"
    fi
done
    
#=============================================================================
# EXTRACT THE STATS FROM THE SURFACE PARCELLATION FILES
#=============================================================================
# Specifically this will loop through the following segmentations:
#     aparc
#     500.aparc
#     lobesStrict
#=============================================================================

# Loop over both left and right hemispheres
for hemi in lh rh; do
    # Loop over parcellations
    for parc in aparc 500.aparc lobesStrict; do
    #for parc in 500.aparc; do

        # First extract just the thickness & curvature values
        if [[ ! -f ${surfer_dir}/stats/${hemi}.${parc}.stats \
                && -f ${surfer_dir}/label/${hemi}.${parc}.annot ]]; then
            mris_anatomical_stats -a ${surfer_dir}/label/${hemi}.${parc}.annot \
                                    -f ${surfer_dir}/stats/${hemi}.${parc}.stats \
                                    ${surf_sub} \
                                    ${hemi}
        fi
        
        # Next loop through all the different MPM and DTI files
        #for measure in R1 MT R2s A FA MD MO L1 L23 sse synthetic; do
        for measure in R1 MT R2s A FA MD MO L1 L23 sse; do
        #for measure in MT; do

            # Loop through a bunch of different fractional depths 
            # from the white matter surface
            for frac in `seq -f %+02.2f -1 0.05 1`; do
            #for frac in `seq -f %+02.2f 0 0.1 1`; do

                # Project the values to the surface
                if [[ ! -f ${surfer_dir}/surf/${hemi}.${measure}_projfrac${frac}.mgh ]]; then
                
                    mri_vol2surf --mov ${surfer_dir}/mri/${measure}.mgz \
                                    --o ${surfer_dir}/surf/${hemi}.${measure}_projfrac${frac}.mgh \
                                    --regheader ${surf_sub} \
                                    --projfrac ${frac} \
                                    --interp nearest \
                                    --surf white \
                                    --hemi ${hemi} 
                fi

                # Calculate the stats
                if [[ ! -f ${surfer_dir}/stats/${hemi}.${parc}.${measure}_projfrac${frac}.stats \
                            && -f ${surfer_dir}/label/${hemi}.${parc}.annot ]]; then
                            
                    mris_anatomical_stats -a ${surfer_dir}/label/${hemi}.${parc}.annot \
                                            -t ${surfer_dir}/surf/${hemi}.${measure}_projfrac${frac}.mgh \
                                            -f ${surfer_dir}/stats/${hemi}.${parc}.${measure}_projfrac${frac}.stats \
                                            ${surf_sub} \
                                            ${hemi}
                fi
        
            done # Close the fraction of cortical thickness loop

            # Now loop through the different absolute depths
            # **from the pial surface**
            #for dist in `seq -f %+02.2f -5 0.1 0`; do
            for dist in `seq -f %+02.2f -0.1 0.1 0`; do

                if [[ ! -f ${surfer_dir}/surf/${hemi}.${measure}_projdist${dist}.mgh ]]; then
                
                    mri_vol2surf --mov ${surfer_dir}/mri/${measure}.mgz \
                                    --o ${surfer_dir}/surf/${hemi}.${measure}_projdist${dist}.mgh \
                                    --regheader ${surf_sub} \
                                    --projdist ${dist} \
                                    --interp nearest \
                                    --surf pial \
                                    --hemi ${hemi} 
                
                fi

                # Calculate the stats
                if [[ ! -f ${surfer_dir}/stats/${hemi}.${parc}.${measure}_projdist${dist}.stats \
                            && -f ${surfer_dir}/label/${hemi}.${parc}.annot ]]; then
                            
                    mris_anatomical_stats -a ${surfer_dir}/label/${hemi}.${parc}.annot \
                                            -t ${surfer_dir}/surf/${hemi}.${measure}_projdist${dist}.mgh \
                                            -f ${surfer_dir}/stats/${hemi}.${parc}.${measure}_projdist${dist}.stats \
                                            ${surf_sub} \
                                            ${hemi}
                fi
                
            done # Close the absolute distance loop
            
            # Now loop through the different absolute depths
            # **from the grey/white matter boundary**
            for dist in `seq -f %+02.2f -2 0.1 0`; do

                if [[ ! -f ${surfer_dir}/surf/${hemi}.${measure}_projdist${dist}_fromBoundary.mgh ]]; then
                
                    mri_vol2surf --mov ${surfer_dir}/mri/${measure}.mgz \
                                    --o ${surfer_dir}/surf/${hemi}.${measure}_projdist${dist}_fromBoundary.mgh \
                                    --regheader ${surf_sub} \
                                    --projdist ${dist} \
                                    --interp nearest \
                                    --surf white \
                                    --hemi ${hemi} 
                
                fi

                # Calculate the stats
                if [[ ! -f ${surfer_dir}/stats/${hemi}.${parc}.${measure}_projdist${dist}_fromBoundary.stats \
                            && -f ${surfer_dir}/label/${hemi}.${parc}.annot ]]; then
                            
                    mris_anatomical_stats -a ${surfer_dir}/label/${hemi}.${parc}.annot \
                                            -t ${surfer_dir}/surf/${hemi}.${measure}_projdist${dist}_fromBoundary.mgh \
                                            -f ${surfer_dir}/stats/${hemi}.${parc}.${measure}_projdist${dist}_fromBoundary.stats \
                                            ${surf_sub} \
                                            ${hemi}
                fi
            done # Close the absolute distance **from boundary** loop
        done # Close the measure loop
    done # Close parcellation loop
done # Close hemi loop


#=============================================================================
# Well done. You're all finished :)
#=============================================================================
