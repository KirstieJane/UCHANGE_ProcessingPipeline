#!/usr/bin/env python

"""
CheckProcessing.py

Created on 15 October 2018
Updated on 22 October 2018
by Kirstie Whitaker
kw401@cam.ac.uk

This code loops over all subjects and all timepoints and reports back
which files that *should* exist DO in fact exist :)
"""

# =============================================================================
# IMPORTS
# =============================================================================
# Make this code python 2 and 3 compatible
from __future__ import print_function

from glob import glob
import itertools as it
import numpy as np
import pandas as pd
import os
import sys

# =============================================================================
# FUNCTIONS
# =============================================================================

def usage():
    """Print the usage function to the screen."""
    print("USAGE CheckProcessing.py <STUDY_DIR> <SUBLIST>")
    print("  ##All the output files will be written out into the same\n" +
          "   ##directory as the behav_file. Recommended usage is to put the\n" +
          "   ##behavioural file in a sensibly named subfolder so you don't\n" +
          "   ##fill up a parent folder with lots of versions of the files")
    sys.exit()

# =============================================================================
# READ IN COMMAND LINE ARGUMENTS
# =============================================================================

# Check that two arguments have been passed
if len(sys.argv) < 2:
    print("Not enough arguments passed")
    usage()

# Get the study_dir from the command line
if not sys.argv[1]:
    print("Can't find STUDY_DIR directory")
    usage()
else:
    study_dir = sys.argv[1]

# Get the full path to the behaviour csv file
if sys.argv[2]:
    sublist_f = sys.argv[2]
    if not os.path.isfile(sublist_f):
        print("Can't find SUBLIST")
        usage()
else:
    print("Can't find SUBLIST")
    usage()


# =============================================================================
# READ IN SUBJECT LIST
# =============================================================================

with open(sublist_f, 'r') as f:
    sublist = [ line.strip() for line in f ]

occlist = [ 'baseline', '6_month', '1st_follow_up' ]

# =============================================================================
# MAKE THE OUTPUT DIR
# =============================================================================

output_dir = os.path.join(study_dir, 'CheckProcessingResults')

if not os.path.isdir(output_dir):
    os.makedirs(output_dir)

# =============================================================================
# CHECK NSPN_Parcellations_PostEdits.sh
# =============================================================================
# 
# This section of the code looks for the annot files and parcellation volumes
# from the four parcellations. It is expecting to find 16 files in total.

columns = ['nspn_id', 'occ',
           '500.aparc', 'Yeo2011_7Networks_N1000', 'HCP', 'economo']

df = pd.DataFrame(columns=columns)

for sub, occ in it.product(sublist, occlist):

    # Create path to data for this subject and this occasion
    sub_path = os.path.join(study_dir,
                            'SUB_DATA',
                            sub,
                            'SURFER',
                            occ)

    # Don't check if the T1.mgz file doesn't exist!
    if not os.path.isfile(os.path.join(sub_path, 'mri', 'T1.mgz')):
        continue

    # Otherwise start a row to enter into the data frame
    df_row = { 'nspn_id' : sub,
               'occ' : occ }

    # Check all the parcellations in turn
    for parcellation in columns[2:]:

        counter=0

        # Loop through the four different files you're expecting to find
        if os.path.isfile(os.path.join(sub_path,
                                       'label',
                                       'lh.{}.annot'.format(parcellation))):
            counter+=1
        if os.path.isfile(os.path.join(sub_path,
                                       'label',
                                       'rh.{}.annot'.format(parcellation))):
            counter+=1
        if os.path.isfile(os.path.join(sub_path,
                                       'parcellation',
                                       '{}.nii.gz'.format(parcellation))):
            counter+=1
        if os.path.isfile(os.path.join(sub_path,
                                       'parcellation',
                                       '{}_renum.nii.gz'.format(parcellation))):
            counter+=1

        df_row[parcellation] = counter

    df = df.append(df_row, ignore_index=True)

# Mark the ones that are missing information
mask = df.loc[:, columns[2:]].sum(axis=1) == 16

df['as_expected'] = 0
df.loc[mask, 'as_expected'] = 1

df.to_csv(os.path.join(output_dir, 'NSPN_Parcellations_PostEdits.csv'),
          index=False)

# Now lets report back the rows that don't have what we though

# =============================================================================
# CHECK NSPN_AssignLobes.sh
# =============================================================================
#
# This section of the code is looking for the lobes annot and volume files.
# It is looking for 3 files in total.

columns = ['nspn_id', 'occ', 'lobes']

df = pd.DataFrame(columns=columns)

for sub, occ in it.product(sublist, occlist):

    # Create path to data for this subject and this occasion
    sub_path = os.path.join(study_dir,
                            'SUB_DATA',
                            sub,
                            'SURFER',
                            occ)

    # Don't check if the T1.mgz file doesn't exist!
    if not os.path.isfile(os.path.join(sub_path, 'mri', 'T1.mgz')):
        continue

    # Otherwise start a row to enter into the data frame
    df_row = { 'nspn_id' : sub,
               'occ' : occ }

    # Check that the three expected files are there
    counter=0

    # Loop through the four different files you're expecting to find
    if os.path.isfile(os.path.join(sub_path,
                                    'label',
                                    'lh.lobesStrict.annot')):
        counter+=1
    if os.path.isfile(os.path.join(sub_path,
                                    'label',
                                    'rh.lobesStrict.annot')):
        counter+=1
    if os.path.isfile(os.path.join(sub_path,
                                    'mri',
                                    'lobes+aseg.mgz')):
        counter+=1

    df_row['lobes'] = counter

    df = df.append(df_row, ignore_index=True)

# Mark the ones that are missing information
mask = df.loc[:, 'lobes'] == 3

df['as_expected'] = 0
df.loc[mask, 'as_expected'] = 1

df.to_csv(os.path.join(output_dir, 'NSPN_AssignLobes.csv'),
          index=False)

# Now lets report back the rows that don't have what we though

# =============================================================================
# CHECK NSPN_ResampleSurfaces.sh
# =============================================================================
#
# This section of the code is looking for all the fractional and distance
# projected surfaces. It is looking for 62 files in total.

columns = ['nspn_id', 'occ', 'lh_frac', 'rh_frac', 'lh_dist', 'rh_dist']

df = pd.DataFrame(columns=columns)

for sub, occ in it.product(sublist, occlist):

    # Create path to data for this subject and this occasion
    sub_path = os.path.join(study_dir,
                            'SUB_DATA',
                            sub,
                            'SURFER',
                            occ)

    # Don't check if the T1.mgz file doesn't exist!
    if not os.path.isfile(os.path.join(sub_path, 'mri', 'T1.mgz')):
        continue

    # Otherwise start a row to enter into the data frame
    df_row = { 'nspn_id' : sub,
               'occ' : occ }

    # Check both hemispheres separately
    for hemi in ['lh', 'rh']:

        # Check the fractional depths
        counter=0
        for depth in np.arange(0, 1.01, 0.1):

            # Loop through the different files you're expecting to find
            if os.path.isfile(os.path.join(sub_path,
                                        'surf',
                                        '{}.white_frac{:+2.2f}_expanded'.format(hemi, depth))):
                counter+=1

            df_row['{}_frac'.format(hemi)] = counter

        # Check the dist depths
        counter=0
        for depth in np.arange(-0.1, -2.01, -0.1):

            # Loop through the different files you're expecting to find
            if os.path.isfile(os.path.join(sub_path,
                                        'surf',
                                        '{}.white_dist{:+2.2f}_expanded'.format(hemi, depth))):
                counter+=1

            df_row['{}_dist'.format(hemi)] = counter

    df = df.append(df_row, ignore_index=True)

# Mark the ones that are missing information
mask = df.loc[:, columns[2:]].sum(axis=1) == 62

df['as_expected'] = 0
df.loc[mask, 'as_expected'] = 1

df.to_csv(os.path.join(output_dir, 'NSPN_ResampleSurfaces.csv'),
          index=False)


# =============================================================================
# CHECK NSPN_TransformQuantitativeMaps.sh
# =============================================================================
#
# 

columns = ['nspn_id', 'occ', 'dti', 'mpm']

df = pd.DataFrame(columns=columns)

for sub, occ in it.product(sublist, occlist):

    # Create path to data for this subject and this occasion
    sub_path = os.path.join(study_dir,
                            'SUB_DATA',
                            sub,
                            'SURFER',
                            occ)

    # Don't check if the T1.mgz file doesn't exist!
    if not os.path.isfile(os.path.join(sub_path, 'mri', 'T1.mgz')):
        continue

    # Otherwise start a row to enter into the data frame
    df_row = { 'nspn_id' : sub,
               'occ' : occ }

    # Check for the DTI volumes
    counter=0
    for dti_measure in ['FA', 'MD', 'L1', 'L23', 'MO']:

        # Loop through the different files you're expecting to find
        if os.path.isfile(os.path.join(sub_path,
                                    'mri',
                                    '{}.mgz'.format(dti_measure))):
            counter+=1

    df_row['dti'] = counter

    # Check for the MPM volumes
    counter=0
    for mpm_measure in ['R1', 'R2s', 'MT', 'A']:

        # Loop through the different files you're expecting to find
        if os.path.isfile(os.path.join(sub_path,
                                    'mri',
                                    '{}.mgz'.format(mpm_measure))):
            counter+=1

    df_row['mpm'] = counter

    df = df.append(df_row, ignore_index=True)

# Mark the ones that are missing information
mask = df.loc[:, columns[2:]].sum(axis=1) == 9

df['as_expected'] = 0
df.loc[mask, 'as_expected'] = 1

df.to_csv(os.path.join(output_dir, 'NSPN_TransformQuantitativeMaps.csv'),
          index=False)


# =============================================================================
# CHECK NSPN_ExtractRois.sh PARCELLATIONS
# =============================================================================
#
# This section of the code is looking for all the parcellation stats files!
# There are LOTS of them across the different parcellations & frac/dist depths.
# It is looking for 62 files in total.

cols = ['nspn_id', 'occ' ]

hemi_list = ['lh', 'rh']

parc_list = ['aparc', '500.aparc', 'lobesStrict',
             'Yeo2011_7Networks_N1000', 'HCP', 'economo']

measure_list = ['MT', 'R1', 'R2s', 'A',
                'FA', 'MD', 'L1', 'L23', 'MO']

columns = cols + [ '{}_{}_{}'.format(hemi, parc, measure) 
                    for hemi, parc, measure in it.product(hemi_list, parc_list, measure_list) ]

df = pd.DataFrame(columns=columns)

for sub, occ in it.product(sublist, occlist):

    # Create path to data for this subject and this occasion
    sub_path = os.path.join(study_dir,
                            'SUB_DATA',
                            sub,
                            'SURFER',
                            occ)

    # Don't check if the T1.mgz file doesn't exist!
    if not os.path.isfile(os.path.join(sub_path, 'mri', 'T1.mgz')):
        continue

    # Otherwise start a row to enter into the data frame
    df_row = { 'nspn_id' : sub,
               'occ' : occ }

    # Check for each hemisphere, parcellation and measure separately
    for hemi, parc, measure in it.product(hemi_list,
                                          parc_list,
                                          measure_list):

        counter=0

        # Check the fractional depths
        for depth in np.arange(0, 1.01, 0.1):

            # Loop through the different files you're expecting to find
            if os.path.isfile(os.path.join(sub_path,
                                'stats',
                                '{}.{}.{}_frac{:+2.2f}_expanded.stats'.format(hemi,
                                                                                parc,
                                                                                measure,
                                                                                depth))):
                counter+=1

        # Check the dist depths
        for depth in np.arange(-0.1, -2.01, -0.1):

            # Loop through the different files you're expecting to find
            if os.path.isfile(os.path.join(sub_path,
                                'stats',
                                '{}.{}.{}_dist{:+2.2f}_expanded.stats'.format(hemi,
                                                                                parc,
                                                                                measure,
                                                                                depth))):
                counter+=1

        df_row['{}_{}_{}'.format(hemi, parc, measure)] = counter

    df = df.append(df_row, ignore_index=True)

# Mark the ones that are missing information
mask = df.loc[:, columns[2:]].sum(axis=1) == 3348

df['as_expected'] = 0
df.loc[mask, 'as_expected'] = 1

df.to_csv(os.path.join(output_dir, 'NSPN_ExtractRois_Parcellations.csv'),
          index=False)
          
