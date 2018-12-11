#!/bin/bash

#====================================================================
# Created by Kirstie Whitaker on 25th April 2016
#
# DESCRIPTION:
#    This code takes a freesurfer directory (including the
#      transformed MPM and DTI measures) and extracts statistics
#      from the following segmentations and parcellations for all
#      MPM and DTI measures along with the standard freesurfer
#      morphological measures.
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
#    Recon-all, trac-all and quality control edits must have been
#      completed.
#    NSPN_TransformQuantitativeMaps.sh, NSPN_Parcellation.sh,
#      NSPN_AssignLobes.sh and NSPN_ResampleSurfaces.sh must also
#      have been completed.
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
    echo "DESCRIPTION: This code takes a freesurfer directory (including the,"
    echo "transformed MPM and DTI measures) and extracts statistics"
    echo "from the following segmentations and parcellations for all"
    echo "MPM and DTI measures along with the standard freesurfer"
    echo "morphological measures."
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
mpm_dir=${data_dir}/SUB_DATA/${sub}/MPM/${occ}/

SUBJECTS_DIR=${surfer_dir}/../
surf_sub=`basename ${surfer_dir}`


#====================================================================
# PRINT TO SCREEN WHAT WE'RE DOING
#====================================================================
echo "==== Extract ROIS ===="

#=============================================================================
# DON'T BOTHER IF THERE'S NO DATA!
#=============================================================================
if [[ ! -f ${surfer_dir}/mri/T1.mgz ]]; then
    echo "No T1.mgz file in surfer directory. Exiting"
    exit
fi

#=============================================================================
# EXTRACT THE STATS FROM THE SEGMENTATION FILES
#=============================================================================
# Specifically this will loop through the following segmentations:
#     wmparc
#     aseg
#     lobesStrict
#=============================================================================

for measure in MT R1 R2s A FA MD MO L1 L23; do
    if [[ -f ${surfer_dir}/mri/${measure}.mgz ]]; then

        echo -ne "  ${measure} segmentations:\t"
        #=== wmparc
        echo -n " wmparc"
        # Don't run the command if the file already exists
        # but DO run the command if the file that exists is OLDER
        # than the segmentation file 
        if [[ ! -s ${surfer_dir}/stats/${measure}_wmparc.stats \
                || ${surfer_dir}/mri/wmparc.mgz -nt \
                   ${surfer_dir}/stats/${measure}_wmparc.stats ]]; then
            mri_segstats --i ${surfer_dir}/mri/${measure}.mgz \
                         --seg ${surfer_dir}/mri/wmparc.mgz \
                         --ctab ${FREESURFER_HOME}/WMParcStatsLUT.txt \
                         --sum ${surfer_dir}/stats/${measure}_wmparc.stats \
                         --pv ${surfer_dir}/mri/norm.mgz
        fi
        echo -n " - done!"

        #=== aseg
        echo -n " aseg"
        # Don't run the command if the file already exists
        # but DO run the command if the file that exists is OLDER
        # than the segmentation file 
        if [[ ! -s ${surfer_dir}/stats/${measure}_aseg.stats \
                || ${surfer_dir}/mri/aseg.mgz -nt \
                   ${surfer_dir}/stats/${measure}_aseg.stats ]]; then
            mri_segstats --i ${surfer_dir}/mri/${measure}.mgz \
                         --seg ${surfer_dir}/mri/aseg.mgz \
                         --sum ${surfer_dir}/stats/${measure}_aseg.stats \
                         --pv ${surfer_dir}/mri/norm.mgz \
                         --ctab ${FREESURFER_HOME}/ASegStatsLUT.txt
        fi
        echo -n " - done!"

        #=== lobesStrict
        echo -n " lobesStrict"
        # Don't run the command if the file already exists
        # but DO run the command if the file that exists is OLDER
        # than the segmentation file 
        if [[ ! -s ${surfer_dir}/stats/${measure}_lobesStrict.stats \
                || ${surfer_dir}/mri/lobes+aseg.mgz -nt \
                   ${surfer_dir}/stats/${measure}_lobesStrict.stats ]]; then
            mri_segstats --i ${surfer_dir}/mri/${measure}.mgz \
                         --seg ${surfer_dir}/mri/lobes+aseg.mgz \
                         --sum ${surfer_dir}/stats/${measure}_lobesStrict.stats \
                         --pv ${surfer_dir}/mri/norm.mgz \
                         --ctab ${lobes_ctab}

        fi
        echo " - done!"

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
#     Yeo2011_7Networks_N1000
#     HCP
#     economo
#=============================================================================

# Loop over parcellations
for parc in aparc 500.aparc lobesStrict Yeo2011_7Networks_N1000 HCP economo; do
    echo "==== Parc: ${parc} ===="

    # Loop over both left and right hemispheres
    for hemi in lh rh; do
        echo "  -- Hemi: ${hemi} --"

        # First extract just the thickness & curvature values
        echo "    Standard parcellations"
        echo -n "      Extracting stats"
        # Don't run the command if the the annot file doesn't exist
        # and don't run the command if the output file already exists
        # but DO run the command if the file that exists is OLDER
        # than the annot file 
        if [[ -f ${surfer_dir}/label/${hemi}.${parc}.annot \
                && ( ! -s ${surfer_dir}/stats/${hemi}.${parc}.stats \
                   || ( ${surfer_dir}/label/${hemi}.${parc}.annot -nt \
                        ${surfer_dir}/stats/${hemi}.${parc}.stats ) ) ]]; then
            echo ""
            mris_anatomical_stats -a ${surfer_dir}/label/${hemi}.${parc}.annot \
                                    -f ${surfer_dir}/stats/${hemi}.${parc}.stats \
                                    ${surf_sub} \
                                    ${hemi}
        fi

        # Also extract sulcal depth
        # Don't run the command if the the annot file doesn't exist
        # and don't run the command if the output file already exists
        # but DO run the command if the file that exists is OLDER
        # than the annot file 
        if [[ -f ${surfer_dir}/label/${hemi}.${parc}.annot \
                && ( ! -s ${surfer_dir}/stats/${hemi}.${parc}.sulcdepth.stats \
                   || ( ${surfer_dir}/label/${hemi}.${parc}.annot -nt \
                        ${surfer_dir}/stats/${hemi}.${parc}.sulcdepth.stats ) ) ]]; then
            echo ""
            mris_anatomical_stats -a ${surfer_dir}/label/${hemi}.${parc}.annot \
                                    -f ${surfer_dir}/stats/${hemi}.${parc}.sulcdepth.stats \
                                    -t sulc \
                                    ${surf_sub} \
                                    ${hemi}
        fi
        echo " - done!"

        # Next loop through all the different MPM and DTI files
        for measure in MT R1 R2s A FA MD MO L1 L23; do
            if [[ ! -s ${surfer_dir}/mri/${measure}.mgz ]]; then
                echo "    ${measure} does not exist, skipping"
                continue
            fi

            echo "    ${measure} parcellations"

            # Take the average across all of cortex
            echo -n "      Average across cortex"
            if [[ ! -f ${surfer_dir}/surf/${hemi}.${measure}_cortexAv.mgh ]]; then

                echo ""
                mri_vol2surf --mov ${surfer_dir}/mri/${measure}.mgz \
                                --o ${surfer_dir}/surf/${hemi}.${measure}_cortexAv.mgh \
                                --regheader ${surf_sub} \
                                --projfrac-avg 0 1 0.1 \
                                --interp nearest \
                                --surf white \
                                --hemi ${hemi}
            else
                echo -n " - done!"
            fi

            # Calculate the stats
            echo -n " Extracting stats"
            # Don't run the command if the the annot file doesn't exist
            # and don't run the command if the output file already exists
            # but DO run the command if the file that exists is OLDER
            # than the annot file 
            if [[ -f ${surfer_dir}/label/${hemi}.${parc}.annot \
                    && ( ! -s ${surfer_dir}/stats/${hemi}.${parc}.${measure}_cortexAv.stats \
                    || ( ${surfer_dir}/label/${hemi}.${parc}.annot -nt \
                            ${surfer_dir}/stats/${hemi}.${parc}.${measure}_cortexAv.stats ) ) ]]; then

                echo ""
                mris_anatomical_stats -a ${surfer_dir}/label/${hemi}.${parc}.annot \
                                        -t ${surfer_dir}/surf/${hemi}.${measure}_cortexAv.mgh \
                                        -f ${surfer_dir}/stats/${hemi}.${parc}.${measure}_cortexAv.stats \
                                        ${surf_sub} \
                                        ${hemi}
            else
                echo " - done!"
            fi

            # Loop through a bunch of different fractional depths
            # from the white matter surface
            # for frac in `seq -f %+02.2f 0.0 0.1 1.0`; do
            # Commented out to make the scripts run a little faster
            # during testing. The line below only runs 0.0 0.3 1.0
            for frac in +0.00 +0.30 +1.00; do
                echo -n "      Frac: ${frac}"

                # Project the values to the surface
                echo -n " Projecting values to surface"
                if [[ ! -f ${surfer_dir}/surf/${hemi}.white_frac${frac}_expanded ]]; then
                    echo " -- Surface not resampled. Skipping this depth."
                    continue
                elif [[ ! -s ${surfer_dir}/surf/${hemi}.${measure}_frac${frac}_expanded.mgh ]]; then

                    echo ""
                    mri_vol2surf --mov ${surfer_dir}/mri/${measure}.mgz \
                                    --o ${surfer_dir}/surf/${hemi}.${measure}_frac${frac}_expanded.mgh \
                                    --regheader ${surf_sub} \
                                    --interp nearest \
                                    --surf white_frac${frac}_expanded \
                                    --hemi ${hemi}
                fi
                echo -n " - done!"

                # Calculate the stats
                echo -n " Extracting stats"
                # Don't run the command if the the annot file doesn't exist
                # and don't run the command if the output file already exists
                # but DO run the command if the file that exists is OLDER
                # than the annot file 
                if [[ -f ${surfer_dir}/label/${hemi}.${parc}.annot \
                        && ( ! -s ${surfer_dir}/stats/${hemi}.${parc}.${measure}_frac${frac}_expanded.stats \
                        || ( ${surfer_dir}/label/${hemi}.${parc}.annot -nt \
                                ${surfer_dir}/stats/${hemi}.${parc}.${measure}_frac${frac}_expanded.stats ) ) ]]; then

                    echo ""
                    mris_anatomical_stats -a ${surfer_dir}/label/${hemi}.${parc}.annot \
                                            -t ${surfer_dir}/surf/${hemi}.${measure}_frac${frac}_expanded.mgh \
                                            -f ${surfer_dir}/stats/${hemi}.${parc}.${measure}_frac${frac}_expanded.stats \
                                            ${surf_sub} \
                                            ${hemi}
                fi
                echo " - done!"

            done # Close the fraction of cortical thickness loop

            # Now loop through the different absolute depths
            # from the grey/white matter boundary
            # for dist in `seq -f %+02.2f -2 0.1 -0.1`; do
            # Commented out to make the scripts run a little faster
            # during testing. The line below only runs 1mm and 2mm.
            for dist in -1.00 -2.00; do
                echo -n "      Dist: ${dist}"

                # Project the values to the surface
                echo -n " Projecting values to surface"
                if [[ ! -f ${surfer_dir}/surf/${hemi}.white_dist${dist}_expanded ]]; then
                    echo -n " -- Surface not resampled. Skipping this depth."
                    continue
                elif [[ ! -s ${surfer_dir}/surf/${hemi}.${measure}_dist${dist}_expanded.mgh ]]; then

                    echo ""
                    mri_vol2surf --mov ${surfer_dir}/mri/${measure}.mgz \
                                    --o ${surfer_dir}/surf/${hemi}.${measure}_dist${dist}_expanded.mgh \
                                    --regheader ${surf_sub} \
                                    --interp nearest \
                                    --surf white_dist${dist}_expanded \
                                    --hemi ${hemi}
                fi
                echo -n " - done!"

                # Calculate the stats
                echo -n " Extracting stats"
                # Don't run the command if the the annot file doesn't exist
                # and don't run the command if the output file already exists
                # but DO run the command if the file that exists is OLDER
                # than the annot file 
                if [[ -f ${surfer_dir}/label/${hemi}.${parc}.annot \
                        && ( ! -s ${surfer_dir}/stats/${hemi}.${parc}.${measure}_dist${dist}_expanded.stats \
                        || ( ${surfer_dir}/label/${hemi}.${parc}.annot -nt \
                                ${surfer_dir}/stats/${hemi}.${parc}.${measure}_dist${dist}_expanded.stats ) ) ]]; then

                    echo ""
                    mris_anatomical_stats -a ${surfer_dir}/label/${hemi}.${parc}.annot \
                                            -t ${surfer_dir}/surf/${hemi}.${measure}_dist${dist}_expanded.mgh \
                                            -f ${surfer_dir}/stats/${hemi}.${parc}.${measure}_dist${dist}_expanded.stats \
                                            ${surf_sub} \
                                            ${hemi}
                fi
                echo " - done!"

            done # Close the absolute distance from grey/white matter boundary loop
        done # Close the measure loop
    done # Close hemi loop
done # Close parcellation loop

#=============================================================================
# Well done. You're all finished :)
#=============================================================================

