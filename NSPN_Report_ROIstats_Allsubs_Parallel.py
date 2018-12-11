#!/usr/bin/env python

"""
A python version of NSPN_Report_ROIstats_Allsubs_Parallel.sh
because it was being a freaking nightmare and causing all sorts
of problems!

THIS SCRIPT MUST BE RUN IN PYTHON 2 OTHERWISE IT WILL CRASH!

Silly freesurfer being all out of date boooooo.
"""

from __future__ import print_function

import argparse
import os
from glob import glob
import pandas as pd

#------------------------------------------------------------------------------
# Build the argparse so you can read in information from the command line
#------------------------------------------------------------------------------
parser = argparse.ArgumentParser(
            description=(('Merge together all the different stats files '),
                         ('across participants and time points')))

parser.add_argument('data_dir', 
                    metavar='data_dir',
                    type=str,
                    help='data directory (contains SUB_DATA)')

#------------------------------------------------------------------------------
# Define some useful functions
#------------------------------------------------------------------------------
def freesurfer_morphometric_measures(parc, subjects,
                                     data_dir, morph_measure_list):
    """
    This function wraps around run_aparcstats2table and loops over
    all the different freesurfer morphometric measures that we want to
    extract.
    """
    for stat in morph_measure_list:

        f_dict = {}
        for hemi in ['lh', 'rh']:

            output_f = os.path.join(data_dir, 
                                    'FS_ROIS', 
                                    'PARC_{parc}_{stat}.csv'.format(parc=parc,
                                                                    stat=stat))

            # Save this file name to the dictionary to pass
            # to the next function
            f_dict[hemi] = output_f

            run_aparcstats2table(subjects, 
                                 output_f,
                                 hemi=hemi,
                                 surf=parc,
                                 stat=stat)

        combine_hemispheres(parc, stat, f_dict)


def quantitative_map_measures(parc, subjects,
                                     data_dir, q_measure_list):
    """
    This function wraps around run_aparcstats2table and loops over
    all the different quantitative maps measures that we want to
    extract.
    """
    for measure in q_measure_list:

        stat = 'thickness'
        stat_name = 'mean'


        # Calculate the values averaged over the cortex
        f_dict = {}
        for hemi in ['lh', 'rh']:
            
            surf = '{parc}.{measure}_cortexAv'.format(parc=parc,
                                                      measure=measure)

            output_f = os.path.join(data_dir, 
                                    'FS_ROIS', 
                                    'PARC_{parc}_{measure}_cortexAv_{stat_name}_{hemi}.csv'.format(parc=parc,
                                                                                                   measure=measure,
                                                                                                   stat_name=stat_name,
                                                                                                   hemi=hemi))
            
            # Save this file name to the dictionary to pass
            # to the next function
            f_dict[hemi] = output_f

            run_aparcstats2table(subjects,
                                    output_f,
                                    hemi=hemi,
                                    surf=surf,
                                    stat=stat)

        combine_hemispheres(parc, measure, f_dict)

def read_stats_to_df(f):
    """
    Read in the output of aparcstats2table into a pandas dataframe.
    """
    df = pd.read_csv(f)
    df = df.rename(index=str, columns={df.columns[0]: 'nspn_id'})

    return df

def write_out_combined_df(df_dict, output_f):
    """
    Save out the combined left and right hemispheres.
    """
    merge_cols = ['nspn_id', 'eTIV', 'BrainSegVolNotVent']

    # Combine the left and right hemispheres
    df = df_dict['lh'].merge(df_dict['rh'], 
                             on=merge_cols,
                             how='outer')

    # Split the first column into nspn_id and occ
    df['tmp'], df['occ'] = df[df.columns[0]].str.split('/SURFER/', 1).str
    _, df['nspn_id'] = df['tmp'].str.split('/SUB_DATA/', 1).str
    
    df = df.drop(['tmp'], axis=1)

    # Save the file
    df.to_csv(output_f, index=False)


def combine_hemispheres(parc, measure, f_dict):
    """
    This function combines the left and right hemispheres after running
    aparcstats2table for a given measure and parcellation combo.
    """
    df_dict = {}

    for hemi in ['lh', 'rh']:
        f = f_dict[hemi]

        df_dict[hemi] = read_stats_to_df(f)

        # Delete the temporary file
        os.remove(f)

    output_f = '{}.csv'.format(f.split('_{hemi}'.format(hemi=hemi))[0])

    write_out_combined_df(df_dict, output_f)


def run_aparcstats2table(subjects, output_f, hemi='lh', surf='aparc', stat='thickness'):
    """
    This function collects together all the stats for a given measure
    and hemisphere across all subjects and writes out a combo file
    in the FS_ROIS directory.
    """
    command = ['aparcstats2table', 
                '--hemi', hemi,
                '--subjects', ' '.join(subjects),
                '--parc', surf,
                '--meas', stat,
                '-d', 'comma',
                '--skip',
                '-t',
                output_f]

    os.system(' '.join(command))

#------------------------------------------------------------------------------
# Lets go!
#------------------------------------------------------------------------------
if __name__ == '__main__':

    # Set up some important variables
    args = parser.parse_args()
    data_dir = args.data_dir
    occ_list = ['baseline', '6_month', '1st_follow_up']
    #parc_list = ['aparc', '500.aparc', 
    #             'lobesStrict', 'HCP',
    #             'Yeo2011_7Networks_N1000', 'economo']
    parc_list ['500.aparc']
    seg_list = ['aseg', 'wmparc', 'lobesStrict']
    morph_measure_list = ['area', 'volume', 'thickness', 'thicknessstd',
                          'meancurv', 'gauscurv', 'foldind', 'curvind']
    q_measure_list = ['MT']

    # Get a list of all the subjects who have data
    subjects = []
    for occ in occ_list:
        subjects += glob(os.path.join(data_dir, 
                                      'SUB_DATA',
                                      '*',
                                      'SURFER',
                                       occ))

    # Loop over all the parcellations
    for parc in parc_list:

        # Calculate the freesurfer morphometric measures
        #freesurfer_morphometric_measures(parc, subjects,
        #                                 data_dir, morph_measure_list)

        # Calculate the quantitative map measures
        quantitative_map_measures(parc, subjects, data_dir, q_measure_list)

