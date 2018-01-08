#!/usr/bin/env python

'''
This script reports the number of MPM files that are available
for each of the different occasions
'''

#---------------------------------
# IMPORTS
#---------------------------------
from __future__ import print_function

from glob import glob
import os
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

def mpm_exist(data_dir, sub, occ):
    """
    For each subject, look to see if the R1 file exists
    """
    missing_list = []
    for mpm in [ 'R1', 'R2s', 'MT', 'A', 'PDw']:
        if not os.path.isfile(mpm_file):
            missing_list += [mpm]
    return missing_list

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


#---------------------------------
# HERE WE GO!
#---------------------------------

if __name__ == "__main__":

    read_in_arguments()
