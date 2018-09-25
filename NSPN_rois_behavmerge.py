#!/usr/bin/env python

"""
NSPN_rois_behavmerge.py

Created on 22nd July 2014
by Kirstie Whitaker
kw401@cam.ac.uk

This code merges the output of freesurfer_combine_CT_stats.sh
with a csv file containing nspn_id and occ to create a
"behav_merge" file which is saved in a folder called FS_BEHAV
which is created in the same folder as the behavioural file
"""

# =============================================================================
# IMPORTS
# =============================================================================
# Make this code python 2 and 3 compatible
from __future__ import print_function

import pandas as pd
from glob import glob
import os
import sys

# =============================================================================
# FUNCTIONS
# =============================================================================


def usage():
    """Print the usage function to the screen."""
    print("USAGE freesurfer_rois_behavmerge.py <FS_ROIS_DIR> <BEHAV_FILE>")
    print("  All the output files will be written out into the same\n" +
          "   directory as the behav_file. Recommended usage is to put the\n" +
          "   behavioural file in a sensibly named subfolder so you don't\n" +
          "   fill up a parent folder with lots of versions of the files")
    sys.exit()

# =============================================================================
# READ IN COMMAND LINE ARGUMENTS
# =============================================================================


# Check that two arguments have been passed
if len(sys.argv) < 2:
    print("Not enough arguments passed")
    usage()

# Get the fs_rois_dir from the command line
if not sys.argv[1]:
    print("Can't find FS_ROIS directory")
    usage()
else:
    fs_rois_dir = sys.argv[1]

# Get the full path to the behaviour csv file
if sys.argv[2]:
    behav_file = sys.argv[2]
    if not os.path.isfile(behav_file):
        print("Can't find behav_file")
        usage()
else:
    print("Can't find behav_file")
    usage()

# =============================================================================
# READ IN BEHAVIOURAL FILE
# =============================================================================
df_behav = pd.read_csv(behav_file)

# Create the nspn_id column if it doesn't yet exist
# (if - for example - you're using redcap names)
if 'nspn_id' not in list(df_behav.columns):
    df_behav['nspn_id'] = df_behav['id_nspn']

# Rename the occ columns if you're using redcap names
mask = df_behav['occ'] == 'iua_baseline'
df_behav.loc[mask, 'occ'] = 'baseline'

mask = df_behav['occ'] == 'iua_6_month'
df_behav.loc[mask, 'occ'] = '6_month'

mask = df_behav['occ'] == 'iua_fu1'
df_behav.loc[mask, 'occ'] = '1st_follow_up'

# Drop rows in df_behav where nspn_id is missing
df_behav.dropna(subset=['nspn_id'], inplace=True)

suffix = os.path.basename(behav_file).split('.csv')[0]
print(suffix)

# =============================================================================
# MERGE MEASURES WITH BEHAV VALUES
# =============================================================================
# Create a list of the freesurfer measures
measure_list = ['mean', 'area',
                'volume', 'thickness',
                'thicknessstd',
                'meancurv', 'gauscurv',
                'foldind', 'curvind',
                'std']

# Create an empty file list
file_list = []

# Loop through all the measures, find all the files that end with
# those words and add them to the file list
for measure in measure_list:

    file_list += glob(os.path.join(fs_rois_dir, '*{}.csv'.format(measure)))

# Loop through the files
for f in sorted(file_list):
    print(f)
    # Check the number of lines that are in the file
    with open(f) as fid:
        num_lines = len(fid.readlines())

    # And only try to merge files that have content
    if num_lines > 0:

        # Read the csv roi file into a data frame
        df_meas = pd.read_csv(f)

        if 'nspn_id' in df_meas.columns:

            # Merge on 'nspn_id' and 'occ'
            df = df_behav.merge(df_meas, on=['nspn_id', 'occ'])

            # Sort into ascending nspn_id
            df.sort_values(by='nspn_id', inplace=True)

            # Drop the eTIV.1 and columns containing the word 'Measure' or
            # the words 'Unknown' or 'unknown' if they exist
            exclude_terms = ['Measure', 'Unknown', 'unknown',
                             'eTIV.1', 'BrainSegVolNotVent.1']
            c_drop = []

            for exclude_term in exclude_terms:
                c_drop += [x for x in df.columns if exclude_term in x]

            if c_drop:
                df.drop(c_drop, inplace=True, axis=1)

            # Rename the roi columns so they don't have
            # one of the various freesurfer measures at the end
            meas_suffix_list = [ 'area', 'curvind', 'foldind',
                                 'gauscurv', 'meancurv',
                                 'thickness', 'thicknessstd',
                                 'volume' ]
            # Get the columns names
            new_cols = df.columns
            # Figure out the suffix in this file
            # Note that this assumes that the last entry in the file
            # is one of the ROIs
            meas_suffix = new_cols[-1].rsplit('_', 1)[1]
            # If the suffix is in the list above, then strip it from
            # the column names
            if meas_suffix in meas_suffix_list:
                new_cols = [ col.rsplit('_{}'.format(meas_suffix), 1)[0] for col in new_cols ]
            # Put these columns back into the data frame
            df.columns = new_cols

            # Create an output file name that removes any '.' symbols
            # in the file name
            f_name = os.path.basename(f)
            f_out = f_name.replace('.', '')
            # and appends the name of the behavioural file
            f_out = f_out.rsplit('csv', 1)[0] + '_{}.csv'.format(suffix)

            # Put this file in the same folder as the behavioural file
            behav_dir = os.path.dirname(behav_file)
            f_out = os.path.join(behav_dir, f_out)
            df.to_csv(f_out, float_format='%.5f', index=False)
