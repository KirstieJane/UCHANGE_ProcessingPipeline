#!/usr/bin/env python

"""
CheckProcessing.py

Created on 15 October 2018
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

import pandas as pd
from glob import glob
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
    sublist = f.readlines().strip()

print(sublist)