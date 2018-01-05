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

# Read in the regionIDs to a dictionary where the key is
# the value in the fsaverageSubP parcellation volume
# and the value is the counter value of the region.
# In other words, this dictionary contains the mapping of
# the original parcellation values, to the renumbered
# parcellation values.
regionIDs_dict = {}
with open(aparc_regionIDs_file) as f:
    lines = f.readlines()[1:]
    for i, line in enumerate(lines):
       (value, name) = line.split()
       regionIDs_dict[int(value)] = i+1

#=============================================================================
# SET ADDITIONAL REGIONS TO ZERO
#=============================================================================
# If there are any values in the parcellation volume file
# that do not map to any of the values in the regionIDs dictionary
# then set these values to zero.

# This command checks to see if there are any values in the
# parcellation volume (data) that are not in the regionIDs keys.
# If the sum is zero then all values in data are included in
# the regionIDs_dict set of keys. If the sum is greater
# than zero then there are some values that are not in the
# dictionary.
mask = np.in1d(data, regionIDs_dict.keys(), invert=False)

n_additional = np.sum(mask)

if n_additional > 0:
    print('Oh no! There are some extra labels!')
    print('  Setting these additional regions to zero')
    data[mask.reshape(data)] = 0

#=============================================================================
# MAP REGIONAL VALUES
#=============================================================================
# Here's the real magic: map all the values from the original ones
# to the new values as defined in regionIDs_dict.

new_data = np.copy(data)

print('Re-numbering data, this may take a while')
for orig, new in regionIDs_dict.items():
    new_data[data==orig] = new

#=============================================================================
# WRITE OUT THE RENUMBERED FILE
#=============================================================================
# As it says above, write out the file
new_img = nib.Nifti1Image(new_data, img.affine)
new_img.to_filename(parcellation_file.replace('.nii', '_renum.nii'))

#=============================================================================
# Done! Congratulations :)
#=============================================================================
