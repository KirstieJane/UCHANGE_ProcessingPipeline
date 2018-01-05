#!/usr/bin/env python

'''
NSPN_RenumberParcellationVolume.py
Created on 12th September 2017
by Kirstie Whitaker
kw401@cam.ac.uk

This code renumbers the output of mri_aparc2aseg so that all values are
consecutive integers and that they match with the volume in fsaverageSubP
space.

For example, the 500.aparc.nii.gz file has 349 unique values. The labels
for the 500.aparc parcellation are contained in the 500.names.txt file
that is saved inside FS_SUBJECTS/fsaverageSubP/parcellation.
'''

#=============================================================================
# IMPORTS
#=============================================================================
# Make this code python 2 and 3 compatible
from __future__ import print_function

import numpy as np
import nibabel as nib
import pandas as pd
import os
import sys

#=============================================================================
# FUNCTIONS
#=============================================================================

def usage():
    print ("USAGE NSPN_RenumberParcellationVolume.py subject_parcellation_file aparc_regionIDs_file")
    sys.exit()

#=============================================================================
# READ IN COMMAND LINE ARGUMENTS
#=============================================================================
# Check that two arguments have been passed
if len(sys.argv) < 2:
    print ("Not enough arguments passed")
    usage()

parcellation_file = sys.argv[1]
aparc_regionIDs_file = sys.argv[2]

if not os.path.isfile(parcellation_file):
    print ("parcellation file is not a file, check {}".format(parcellation_file))
    usage()

if not os.path.isfile(aparc_regionIDs_file):
    print ("aparc_regionIDs_file is not a file, check {}".format(aparc_regionIDs_file))
    usage()

#=============================================================================
# GET STARTED
#=============================================================================

# Read in the parcellation volume
img = nib.load(parcellation_file)
data = img.get_data()

# Read in the regionIDs to a dictionary
# where the
regionIDs_dict = {}
with open(aparc_regionIDs_file) as f:
    lines = f.readlines()[1:]
    for line in lines:
       (key, val) = line.split()
       regionIDs[int(key)] = val

print(regionIDS_dict)

#=============================================================================
# SEGMENTATIONS
#=============================================================================
# Loop through the various segmentations
for seg in aseg wmparc lobesStrict; do
