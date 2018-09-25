#!/bin/bash

#==============================================================================
# Combine stats measures of surface parcellations and segmentations for
# NSPN MPM and DTI data for all subjects
# Created by Kirstie Whitaker
# Contact kw401@cam.ac.uk
#
# Updated on 10 September 2018
# to parallelise across the different measures the code takes a really
# long time for longitudinal data and lots of MPM & DTI measures.
# by Kirstie Whitaker
#==============================================================================

#==============================================================================
# USAGE: NSPN_Report_ROIstats_Allsubs_Parallel.sh <data_dir> <measure>
#==============================================================================
function usage {

    echo "USAGE: NSPN_Report_ROIstats_Allsubs.sh <data_dir> <measure>"
    echo "Note that data dir expects to find SUB_DATA within it"
    echo "and then the standard NSPN directory structure"
    echo "Measure is one of MT R1 R2s A FA MD L1 L23 MO freesurfer"
    echo ""
    echo "DESCRIPTION: This code looks for the output of NSPN_ExtractRois.sh"
    echo "in each subject's directory and then combines the information"
    echo "for a given measure into the FS_ROIS folder within DATA_DIR"
    echo ""
    echo "Note that the measure 'freesufer' (quotes not included in the command)"
    echo "corresponds to pulling out the standard morphometric measures"
    echo "created by freesurfer such as thickness, curvature, area etc."
    exit
}

#=============================================================================
# READ IN COMMAND LINE ARGUMENTS
#=============================================================================

data_dir=$1
measure=$2

if [[ ! -d ${data_dir} ]]; then
    "Data dir doesn't exist. Check: ${data_dir}"
    usage
fi

if [[ -z ${measure} ]]; then
    "No measure given"
    usage
fi

#=============================================================================
# SET UP SOME USEFUL INFORMATION
#=============================================================================

# Set up a list of the different segmentations we're going to loop over
# This is hard coded but could be adjusted in future iterations
seg_list=(aseg wmparc lobesStrict)

# Set up a list of the different parcellations we're going to loop over
# This is hard coded but could be adjusted in future iterations
parc_list=(aparc 500.aparc lobesStrict HCP Yeo2011_7Networks_N1000 economo)

#=============================================================================
# GET STARTED
#=============================================================================

mkdir -p ${data_dir}/FS_ROIS/

#=============================================================================
# SEGMENTATIONS
#=============================================================================
if [[ ${measure} != "freesurfer" ]]; then

    # Loop through the various segmentations
    for seg in aseg wmparc lobesStrict; do

        # Find all the individual stats files for that segmentation
        inputs=(`ls -d ${data_dir}/SUB_DATA/*/SURFER/*/stats/${measure}_${seg}.stats 2> /dev/null `)

        if [[ ${#inputs[@]} -gt 0 ]]; then

            #===== NSPN_ID AND OCC VALUES ====================================
            # We need to edit the first two columns so they're nice and easily
            # readable with the nspn_ids etc
            echo "nspn_id,occ" > ${data_dir}/FS_ROIS/nspn_id_col_${measure}
            for fname in ${inputs[@]}; do
                fname_parts=(`echo "${fname/${data_dir}/}" | tr "/" " "`)
                sub=${fname_parts[1]}
                occ=${fname_parts[3]}

                echo ${sub},${occ} >> ${data_dir}/FS_ROIS/nspn_id_col_${measure}
            done

            # Write out each statistic
            # This is silly because it loops over volume many times
            # but to be honest, I think the code was looking super messy when
            # I had it being faster. So just be patient and don't worry about
            # speed ;)

            for stat in mean std volume; do
                # Now write out the mean values for the measure
                asegstats2table --inputs ${inputs[@]} \
                                -t ${data_dir}/FS_ROIS/SEG_${measure}_${seg}_${stat}_temp.csv \
                                -d comma \
                                --all-segs \
                                --meas ${stat}

                # Now paste the data together
                paste -d , ${data_dir}/FS_ROIS/nspn_id_col_${measure} \
                            ${data_dir}/FS_ROIS/SEG_${measure}_${seg}_${stat}_temp.csv \
                                > ${data_dir}/FS_ROIS/SEG_${measure}_${seg}_${stat}.csv

                # And replace all '-' with '_' because statsmodels in python
                # likes that more :P but only for the first line
                sed -i "1 s/-/_/g" ${data_dir}/FS_ROIS/SEG_${measure}_${seg}_${stat}.csv
                # And replace the : marker
                sed -i "s/://g" ${data_dir}/FS_ROIS/SEG_${measure}_${seg}_${stat}.csv

                # Remove the temporary files
                rm ${data_dir}/FS_ROIS/SEG_${measure}_${seg}_${stat}_temp.csv
            done

        # Get rid of the nspn_id_col_${measure} file ready for the next loop
        rm ${data_dir}/FS_ROIS/nspn_id_col_${measure}

        else
            echo "    No input files for ${measure}_${seg}!"
        fi
    done
fi

#=============================================================================
# PARCELLATIONS | Standard morphometric measures
#=============================================================================
# Loop through the various parcellations to extract the 
# morphometric values that are created by freesurfer's recon-all

subjects=(`ls -d ${data_dir}/SUB_DATA/*/SURFER/*/ 2> /dev/null`)

if [[ ${measure} == "freesurfer" ]]; then

    for parc in ${parc_list[@]}; do

        # Start by pulling out the standard measures
        for measure in area volume thickness thicknessstd meancurv gauscurv foldind curvind; do

            for hemi in lh rh; do

                # Combine stats for all subjects for each measure and for each
                # hemisphere separately
                aparcstats2table --hemi ${hemi} \
                                    --subjects ${subjects[@]} \
                                    --parc ${parc} \
                                    --meas ${measure} \
                                    -d comma \
                                    --skip \
                                    -t ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_${hemi}_temptemp.csv

                # Drop the first column because it isn't necessary
                cut -d, -f2- ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_${hemi}_temptemp.csv \
                        > ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_${hemi}_temp.csv

                # But save it for later!
                cut -d, -f1 ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_${hemi}_temptemp.csv \
                        > ${data_dir}/FS_ROIS/nspn_id_col_${measure}
            done

            sed -i "s|${data_dir}/SUB_DATA/||g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}
            sed -i "s|/SURFER/|,|g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}
            sed -i "s|/||g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}
            sed -i "s|${hemi}.${parc}.${measure}|nspn_id,occ|g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}

            # Now paste the data together
            paste -d , ${data_dir}/FS_ROIS/nspn_id_col_${measure} \
                    ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_lh_temp.csv \
                    ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_rh_temp.csv \
                        > ${data_dir}/FS_ROIS/PARC_${parc}_${measure}.csv

            # And replace all '-' with '_' because statsmodels in python
            # likes that more :P but only for the first line
            sed -i "1 s/-/_/g" ${data_dir}/FS_ROIS/PARC_${parc}_${measure}.csv
            # And replace the : marker
            sed -i "s/://g" ${data_dir}/FS_ROIS/PARC_${parc}_${measure}.csv

            # Remove the temporary files
            rm ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_*temp.csv
            rm ${data_dir}/FS_ROIS/nspn_id_col_${measure}

        done # Close the measure loop

        # Do one last measure - this one needs mean and std
        measure=sulcdepth

        # Next extract "thickness" and "thicknessstd"
        # values from the projected maps
        for stat in thickness thicknessstd; do

            # Come up with some readable names for the files
            if [[ ${stat} == thickness ]]; then
                stat_name=mean
            else
                stat_name=std
            fi

            for hemi in lh rh; do

                # Combine stats for all subjects for each measure and for each
                # hemisphere separately
                aparcstats2table --hemi ${hemi} \
                                    --subjects ${subjects[@]} \
                                    --parc ${parc}.${measure} \
                                    --meas ${stat} \
                                    -d comma \
                                    --skip \
                                    -t ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_${stat_name}_${hemi}_temptemp.csv

                # Drop the first column because it isn't necessary
                cut -d, -f2- ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_${stat_name}_${hemi}_temptemp.csv \
                        > ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_${stat_name}_${hemi}_temp.csv

                # But save it for later!
                cut -d, -f1 ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_${stat_name}_${hemi}_temptemp.csv \
                        > ${data_dir}/FS_ROIS/nspn_id_col_${measure}
            done # Close the hemi loop

            sed -i "s|${data_dir}/SUB_DATA/||g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}
            sed -i "s|/SURFER/|,|g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}
            sed -i "s|/||g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}
            sed -i "s|${hemi}.${parc}.${measure}.${stat}|nspn_id,occ|g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}

            # Now paste the data together
            paste -d , ${data_dir}/FS_ROIS/nspn_id_col_${measure} \
                    ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_${stat_name}_lh_temp.csv \
                    ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_${stat_name}_rh_temp.csv \
                        > ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_${stat_name}.csv

            # And replace all '-' with '_' because statsmodels in python
            # likes that more :P - but only on the first line!
            sed -i "1 s/-/_/g" ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_${stat_name}.csv
            # and get rid of the : marker
            sed -i "s/://g" ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_${stat_name}.csv

            # Remove the temporary files
            rm ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_*temp.csv
            rm ${data_dir}/FS_ROIS/nspn_id_col_${measure}

        done # Close the stat loop

    done # Close the parc loop


#=============================================================================
# PARCELLATIONS | QUANTITATIVE MAPS
# Extracting values from the quantitative maps at different depths
#=============================================================================

else # For all the other measure options we're going to extract mean and std

    for parc in ${parc_list[@]}; do

        # Extract "thickness" and "thicknessstd"
        # values from the projected maps
        # (This is a little "hack" for the aparcstats2table command
        # to be able to extract mean and standard deviation for 
        # quantitative maps)
        for stat in thickness thicknessstd; do

            # Come up with some readable names for the files
            if [[ ${stat} == thickness ]]; then
                stat_name=mean
            else
                stat_name=std
            fi

            if [[ ! -f ${subjects[0]}/mri/${measure}.mgz ]]; then
            echo "No ${measure} file - skipping"
                continue
            fi

            # Loop through 11 fractional depths from 1.0 to 0.0 in 
            # steps of 0.1 of the cortical thickness
            for frac in `seq -f %+02.2f 0 0.1 1`; do

                for hemi in lh rh; do

                    # Combine stats for all subjects for each measure and for each
                    # hemisphere separately
                    aparcstats2table --hemi ${hemi} \
                                        --subjects ${subjects[@]} \
                                        --parc ${parc}.${measure}_frac${frac}_expanded \
                                        --meas ${stat} \
                                        -d comma \
                                        --skip \
                                        -t ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_frac${frac}_${stat_name}_${hemi}_temptemp.csv

                    # Drop the first column because it isn't necessary
                    cut -d, -f2- ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_frac${frac}_${stat_name}_${hemi}_temptemp.csv \
                            > ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_frac${frac}_${stat_name}_${hemi}_temp.csv

                    # But save it for later!
                    cut -d, -f1 ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_frac${frac}_${stat_name}_${hemi}_temptemp.csv \
                            > ${data_dir}/FS_ROIS/nspn_id_col_${measure}
                done # Close the hemi loop

                sed -i "s|${data_dir}/SUB_DATA/||g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}
                sed -i "s|/SURFER/|,|g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}
                sed -i "s|/||g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}
                sed -i "s|${hemi}.${parc}.${measure}_frac${frac}_expanded.${stat}|nspn_id,occ|g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}

                # Now paste the data together
                paste -d , ${data_dir}/FS_ROIS/nspn_id_col_${measure} \
                        ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_frac${frac}_${stat_name}_lh_temp.csv \
                        ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_frac${frac}_${stat_name}_rh_temp.csv \
                            > ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_frac${frac}_${stat_name}.csv

                # And replace all '-' with '_' because statsmodels in python
                # likes that more :P - but only on the first line!
                sed -i "1 s/-/_/g" ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_frac${frac}_${stat_name}.csv
                # and get rid of the : marker
                sed -i "s/://g" ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_frac${frac}_${stat_name}.csv

                # Remove the temporary files
                rm ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_*temp.csv
                rm ${data_dir}/FS_ROIS/nspn_id_col_${measure}

            done # Close frac loop

            # Loop through 20 absolute depth steps from 0.1mm below cortex
            # to 2mm below cortex in steps of 0.1mm
            for dist in `seq -f %+02.2f -0.1 -0.1 -2`; do

                for hemi in lh rh; do

                    # Combine stats for all subjects for each measure and for each
                    # hemisphere separately
                    aparcstats2table --hemi ${hemi} \
                                        --subjects ${subjects[@]} \
                                        --parc ${parc}.${measure}_dist${dist}_expanded \
                                        --meas ${stat} \
                                        -d comma \
                                        --skip \
                                        -t ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_dist${dist}_${stat_name}_${hemi}_temptemp.csv

                    # Drop the first column because it isn't necessary
                    cut -d, -f2- ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_dist${dist}_${stat_name}_${hemi}_temptemp.csv \
                            > ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_dist${dist}_${stat_name}_${hemi}_temp.csv

                    # But save it for later!
                    cut -d, -f1 ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_dist${dist}_${stat_name}_${hemi}_temptemp.csv \
                            > ${data_dir}/FS_ROIS/nspn_id_col_${measure}
                done # Close the hemi loop

                sed -i "s|${data_dir}/SUB_DATA/||g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}
                sed -i "s|/SURFER/|,|g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}
                sed -i "s|/||g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}
                sed -i "s|${hemi}.${parc}.${measure}_dist${dist}_expanded.${stat}|nspn_id,occ|g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}

                # Now paste the data together
                paste -d , ${data_dir}/FS_ROIS/nspn_id_col_${measure} \
                        ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_dist${dist}_${stat_name}_lh_temp.csv \
                        ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_dist${dist}_${stat_name}_rh_temp.csv \
                            > ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_dist${dist}_${stat_name}.csv

                # And replace all '-' with '_' because statsmodels in python
                # likes that more :P but only on the first row
                sed -i "1 s/-/_/g" ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_dist${dist}_${stat_name}.csv
                # And replace the : marker
                sed -i "s/://g" ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_dist${dist}_${stat_name}.csv

                # Remove the temporary files
                rm ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_*temp.csv
                rm ${data_dir}/FS_ROIS/nspn_id_col_${measure}

            done # Close dist loop

            # Now calculate the values averaged over cortex
            for hemi in lh rh; do

                # Combine stats for all subjects for each measure and for each
                # hemisphere separately
                aparcstats2table --hemi ${hemi} \
                                    --subjects ${subjects[@]} \
                                    --parc ${parc}.${measure}_cortexAv \
                                    --meas ${stat} \
                                    -d comma \
                                    --skip \
                                    -t ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_cortexAv_${stat_name}_${hemi}_temptemp.csv

                # Drop the first column because it isn't necessary
                cut -d, -f2- ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_cortexAv_${stat_name}_${hemi}_temptemp.csv \
                        > ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_cortexAv_${stat_name}_${hemi}_temp.csv

                # But save it for later!
                cut -d, -f1 ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_cortexAv_${stat_name}_${hemi}_temptemp.csv \
                        > ${data_dir}/FS_ROIS/nspn_id_col_${measure}

            done # Close the hemi loop

            sed -i "s|${data_dir}/SUB_DATA/||g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}
            sed -i "s|/SURFER/|,|g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}
            sed -i "s|/||g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}
            sed -i "s|${hemi}.${parc}.${measure}_cortexAv.${stat}|nspn_id,occ|g" ${data_dir}/FS_ROIS/nspn_id_col_${measure}

            # Now paste the data together
            paste -d , ${data_dir}/FS_ROIS/nspn_id_col_${measure} \
                    ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_cortexAv_${stat_name}_lh_temp.csv \
                    ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_cortexAv_${stat_name}_rh_temp.csv \
                        > ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_cortexAv_${stat_name}.csv

            # And replace all '-' with '_' because statsmodels in python
            # likes that more :P but only on the first row
            sed -i "1 s/-/_/g" ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_cortexAv_${stat_name}.csv
            # And replace the : marker
            sed -i "s/://g" ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_cortexAv_${stat_name}.csv

            # Remove the temporary files
            rm ${data_dir}/FS_ROIS/PARC_${parc}_${measure}_*temp.csv
            rm ${data_dir}/FS_ROIS/nspn_id_col_${measure}

        done # Close stat loop
    done # Close parc loop
fi

# This has been commented out because I think it's going
# to create a bunch of problems for the parallelisation.
# This code *really* has to be re-written in python!!!
#
# # If there are any empty files delete them
# # otherwise they'll screw up the behaviour merge code
# for file in `ls -d ${data_dir}/FS_ROIS/*`; do

#     lines=(`cat ${file} | wc -l`)

#     if [[ ${lines} == 0 ]]; then
#         rm ${file}
#     fi
# done
