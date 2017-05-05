#!/bin/bash

#====================================================================
# Created by Kirstie Whitaker on 26th May 2016 
#
# DESCRIPTION:
#    This code runs freesurfer's trac-all command on the DTI data, 
#      processing it, registering it to the reconstrucution, running
#      bedpostx and then creating standard tracts for the individuals.
#
# INPUTS:
#    data_dir : The directory containing the SUB_DATA folder which
#                  itself contains directories named by sub_id.
#    sub_id    : Subject ID. These folders should be inside SUB_DATA
#                  and themselves contain two directories: SURFER
#                  DTI.
#    occ       : The scan occasion. One of baseline, 6_month, 
#                  1st_follow_up, CBSU, UCL, WBIC, t1 or t2. Both the 
#                  SURFER and DTI directory should contain this
#                  folder.
#
# EXPECTS:
#    NSPN_Reconall_MPM or NSPN_Reconall_MPRAGE must have been
#      completed.
#    DTI files dti.nii.gz, bvals and bvecs_orig must exist.
#
# OUTPUTS:
#
#====================================================================

#====================================================================
# USAGE: NSPN_Tracall.sh <data_dir> <sub> <occ>
#====================================================================
function usage {

    echo "USAGE: NSPN_Tracall_MPM.sh <data_dir> <sub> <occ>"
    echo "       <data_dir> is the parent directory to the SUB_DATA"
    echo "         directory and expects to find SUB_DATA inside it"
    echo "         and then the standard NSPN directory structure."
    echo "       <sub> is the subject ID that corresponds to a"
    echo "          folder in the SUB_DATA directory."
    echo "       <occ> is the scan occasion and is one of baseline,"
    echo "         6_month, 1st_follow_up, CBSU, WBIC, UCL, t1 or t2"
    echo ""
    echo "DESCRIPTION: This code runs freesurfer's trac-all command"
    echo "               on the DTI data, processing it, registering"
    echo "               it to the reconstrucution, running bedpostx"
    echo "               and then creating standard tracts for the"
    echo "               individuals."
    exit
} 
#====================================================================
# READ IN COMMAND LINE ARGUMENTS
#====================================================================
data_dir=$1
sub=$2
occ=$3

if [[ ! -d ${data_dir} ]]; then
    echo "**** DATA DIRECTORY does not exist ****"
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
dti_dir=${data_dir}/SUB_DATA/${sub}/DTI/${occ}/
surfer_dir=${data_dir}/SUB_DATA/${sub}/SURFER/${occ}/

if [[ ! -f ${dti_dir}/dti.nii.gz ]]; then
    echo "DTI file doesn't exist - CHECK ${dti_dir}/dti.nii.gz"
    exit
fi

if [[ ! -f ${dti_dir}/bvals ]]; then
    echo "bvals file doesn't exist - CHECK ${dti_dir}/bvals"
    exit
fi

if [[ ! -f ${dti_dir}/bvecs_orig ]]; then
    echo "bvecs file doesn't exist - CHECK ${dti_dir}/bvecs_orig"
    exit
fi

template_dmrirc_file=`dirname ${0}`/TEMPLATE_dmrirc
if [[ ! -f ${template_dmrirc_file} ]]; then
    echo "template dmrirc file doesn't exist - CHECK ${template_dmrirc_file}"
    exit
fi


#====================================================================
# DEFINE VARIABLES
#====================================================================
# Set the subjects dir and subject id variables
SUBJECTS_DIR=`dirname ${surfer_dir}`
surf_sub=${occ}


#====================================================================
# SET UP THE dmrirc FILE
#====================================================================
# Copy the dmrirc.TEMPLATE file into SUBJECTS_DIR
cp ${template_dmrirc_file} ${SUBJECTS_DIR}/TravellingHeads_dmrirc_${occ}

# Replace the SUBJECTS_DIR references with this specific subjects' directory
sed -i "s|%%%%SUBJECTS_DIR%%%%|${SUBJECTS_DIR}|g" \
            ${SUBJECTS_DIR}/TravellingHeads_dmrirc_${occ}

# Replace the OCC (location) references with this specific subjects' directory
sed -i "s|%%%%LOC%%%%|${occ}|g" \
            ${SUBJECTS_DIR}/TravellingHeads_dmrirc_${occ}

# Replace the DTI_DIR references with this specific DTI directory
sed -i "s|%%%%DTI_DIR%%%%|${DTI_DIR}|g" \
            ${SUBJECTS_DIR}/TravellingHeads_dmrirc_${occ}


#====================================================================
# PRINT TO SCREEN WHAT WE'RE DOING
#====================================================================
echo "==== Running Trac-all ===="


#====================================================================
# AND GO!
#====================================================================
# If Recon-all has finished running then run the different steps of trac-all
if [[ -f ${SUBJECTS_DIR}/${occ}/scripts/recon-all.done ]]; then

    if [[ ! -f ${SUBJECTS_DIR}/${occ}/scripts/trac-preproc.done ]]; then
        trac-all -prep -c ${SUBJECTS_DIR}/TravellingHeads_dmrirc_${occ} -no-isrunning
    fi

    if [[ ! -f ${SUBJECTS_DIR}/${occ}/dmri.bedpostX/mean_fsumsamples.nii.gz ]]; then
        trac-all -bedp -c ${SUBJECTS_DIR}/TravellingHeads_dmrirc_${occ} -no-isrunning 
    fi

    if [[ ! -f ${SUBJECTS_DIR}/${occ}/scripts/trac-paths.done ]]; then
        trac-all -path -c ${SUBJECTS_DIR}/TravellingHeads_dmrirc_${occ} -no-isrunning
    fi

    trac-all -stat -c ${SUBJECTS_DIR}/TravellingHeads_dmrirc_${occ} -no-isrunning
fi

#====================================================================
# DONE! Way to go :)
#====================================================================

