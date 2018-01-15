#!/usr/bin/env python

'''
This script reports the number of MPM files that are available
for each of the different occasions. The output is split up by
the raw file (eg: MT.nii.gz), the head extracted file
(eg: MT_head.nii.gz), and the brain extracted file (MT_brain.nii.gz).

Two output files are created:
  * SubjectInfo-0-NumberMPMfiles-[DATE&TIME].csv
  * Summary-0-NumberMPMfiles-[DATE&TIME].csv

The summary info will tell you if everything looks ok, the subject info
file will allow you to go in and CHECK any of the problems that the summary
file highlights.
'''

#---------------------------------
# IMPORTS
#---------------------------------
from __future__ import print_function

import datetime
from glob import glob
import itertools as it
import os
import pandas as pd
import sys

#---------------------------------
# FUNCTIONS
#---------------------------------

def usage():
    """
    Print the usage and then exit
    """
    print ("USAGE report-0-number-mpm-files.py data_dir")
    sys.exit()


def read_in_arguments():
    """
    Read in the command line argument(s)

    If it is not equal to one, then print the usage
    and exit.

    If the data directory doesn't exist, print the usage
    and exit.
    """
    # Check that one argument has been passed
    if len(sys.argv) <> 2:
        print ("Not the right number of arguments passed")
        usage()

    data_dir = sys.argv[1]

    if not os.path.isdir(data_dir):
        print ("data_dir does not exist, check {}".format(data_dir))
        usage()

    return data_dir


def get_sub_list(data_dir):
    """
    Make a little list of all the different subject IDs in
    the SUB_DATA directory within data_dir.
    """

    sub_dir = os.path.join(data_dir, 'SUB_DATA')
    sub_list = [ os.path.basename(x) for x in glob('{}/*'.format(sub_dir)) ]

    sub_list.remove('fsaverageSubP')

    sub_list.sort()

    return sub_list


def get_occ_list(data_dir):

    sub_dir = os.path.join(data_dir, 'SUB_DATA')
    occ_list = [ os.path.basename(x) for x in glob('{}/*/MPM/*'.format(sub_dir)) ]

    occ_list = list(set(occ_list))

    return occ_list


def mpm_exist(data_dir, sub, occ, suffix=''):
    """
    For each subject, look to see if the five MPM files exist
    """
    mpm_list = []

    for mpm in [ 'R1', 'R2s', 'MT', 'A', 'PDw']:

        mpm_file = os.path.join(data_dir, 'SUB_DATA', sub,
                                   'MPM', occ, '{}{}.nii.gz'.format(mpm, suffix))

        if os.path.isfile(mpm_file):
            mpm_list += [mpm]

    return mpm_list


def create_report(mpm_exists_dict, mpm_head_exists_dict, mpm_brain_exists_dict):

    df_list = []

    columns = ['nspn_id', 'occ',
               'complete-mpm', 'part-mpm',
               'complete-mpm-head', 'part-mpm-head',
               'complete-mpm-brain', 'part-mpm-brain' ]

    for key, item in mpm_exists_dict.items():

        sub, occ = key.split('-')

        n_mpm = len(item)
        n_mpm_head = len(mpm_head_exists_dict[key])
        n_mpm_brain = len(mpm_brain_exists_dict[key])

        if n_mpm == 0:
            continue

        row_info = [ sub, occ ]

        if n_mpm == 5:
            row_info += [1, 0]

        elif n_mpm > 0:
            row_info += [0, 1]

        if n_mpm_head == 5:
            row_info += [1, 0]

        elif n_mpm_head > 0:
            row_info += [0, 1]

        if n_mpm_brain == 5:
            row_info += [1, 0]

        elif n_mpm_brain > 0:
            row_info += [0, 1]

        df_list += [tuple(row_info)]
    df = pd.DataFrame.from_records(df_list, columns=columns)

    df.sort_values(by=['nspn_id', 'occ'], inplace=True)
    print (df.head())

    return df


def write_subject_level_report(data_dir, df):

    now = datetime.datetime.now()
    report_name = now.strftime('SubjectInfo-0-NumberMPMfiles-%Y%m%d-%H%M.csv')

    if not os.path.isdir(os.path.join(data_dir, 'data-check-reports')):
        os.makedirs(os.path.join(data_dir, 'data-check-reports'))

    df.to_csv(os.path.join(data_dir, 'data-check-reports', report_name),
                index=False)


def write_summary_report(data_dir, df):

    now = datetime.datetime.now()
    report_name = now.strftime('Summary-0-NumberMPMfiles-%Y%m%d-%H%M.md')

    if not os.path.isdir(os.path.join(data_dir, 'data-check-reports')):
        os.makedirs(os.path.join(data_dir, 'data-check-reports'))

    # Set up the markdown table
    summary_info_list = [ '## Summary Report',
                          '',
                          'Report on number of MPM files at different stages of processing',
                          '',
                          'Data Directory: **{}**'.format(os.path.abspath(data_dir)),
                          'Run on: **{}**'.format(now.strftime('%Y %m %d at %H:%M')),
                          '',
                          '| Category | Occ |  N  | Check |',
                          '| -------- | --- | ---:|:-----:|' ]

    preferred_order_occ_list = [ 'baseline', '6_month', '1st_follow_up']

    occ_list = [ occ for occ in preferred_order_occ_list if occ in set(df['occ'].values) ]
    occ_list += [ occ for occ in set(df['occ'].values) if occ not in preferred_order_occ_list ]

    col_text_dict = { 'complete-mpm'       : 'complete MPM',
                      'part-mpm'           : 'partial MPM',
                      'complete-mpm-head'  : 'complete head extracted MPM',
                      'part-mpm-head'      : 'partial head extracted MPM',
                      'complete-mpm-brain' : 'complete brain extracted MPM',
                      'part-mpm-brain'     : 'partial brain extracted MPM' }

    for col, occ in it.product(df.columns[2:], occ_list):
        mask = (df['occ']==occ) & (df[col]==1)
        n = df.loc[mask, col].count()
        col_text = col_text_dict[col]
        check_text = ''

        if col.startswith('part') & (n > 0):
            check_text = ':x:'

        # Don't bother to repeat the column text over
        # and over, just leave the second (and later)
        # cells blank to make the table more readable
        if not occ == occ_list[0]:
            col_text = ''

        summary_info_list += [ '| {} | {} | {:>3.0f} | {} |'.format(col_text, occ, n, check_text) ]

    summary_info_list += [' ']

    # Write each of these items onto a new row in the output file
    with open(os.path.join(data_dir, 'data-check-reports', report_name), "w") as f:
        f.write('\n'.join(summary_info_list))

#---------------------------------
# HERE WE GO!
#---------------------------------

if __name__ == "__main__":

    data_dir = read_in_arguments()

    # Create the subject list
    sub_list = get_sub_list(data_dir)

    # Create the occasion list
    occ_list = get_occ_list(data_dir)

    # Set up three different dictionary for all the subjects
    mpm_exists_dict = {}
    mpm_head_exists_dict = {}
    mpm_brain_exists_dict = {}

    # Loop through all the subjects to see which
    # MPM files exist
    for sub, occ in it.product(sub_list, occ_list):

        mpm_list = mpm_exist(data_dir, sub, occ, suffix='')
        mpm_exists_dict['{}-{}'.format(sub, occ)] = mpm_list

        mpm_head_list = mpm_exist(data_dir, sub, occ, suffix='_head')
        mpm_head_exists_dict['{}-{}'.format(sub, occ)] = mpm_head_list

        mpm_brain_list = mpm_exist(data_dir, sub, occ, suffix='_brain')
        mpm_brain_exists_dict['{}-{}'.format(sub, occ)] = mpm_brain_list

    # Create a dataframe for the report
    df = create_report(mpm_exists_dict, mpm_head_exists_dict, mpm_brain_exists_dict)

    # Write out the subject level report
    write_subject_level_report(data_dir, df)

    # Write out the summary report
    write_summary_report(data_dir, df)
