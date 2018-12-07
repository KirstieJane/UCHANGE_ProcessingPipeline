#!/usr/bin/env python
"""
A little function for a subject and occasion to find out which
surfaces are not the same size as the pial surface for that scan.

If a surface is deleted the downstream stats files are then also deleted
as these will need to be recreated with the new surfaces.

The use case is if you've quality controlled a subject and re-run recon all
such that the surfaces have changed. This will tell you which files you need
to delete so they can be remade.
"""

import argparse
import numpy as np 
import nibabel as nib 
import os
from glob import glob 

#------------------------------------------------------------------------------
# Build the argparse so you can read in information from the command line
#------------------------------------------------------------------------------
parser = argparse.ArgumentParser(
            description=('Find surfaces that have a different number of ',
                         'vertices compared to the pial surface for ',
                         'that hemisphere'))

parser.add_argument('data_dir', 
                    metavar='data_dir',
                    type=str,
                    help='data directory (contains SUB_DATA)')

parser.add_argument('sub', 
                    metavar='sub',
                    type=str,
                    help='the subject ID')

parser.add_argument('occ', 
                    metavar='occ',
                    type=str,
                    help='the timepoint (occasion)')

parser.add_argument('--delsurf',
                     dest='delsurf',
                     action='store_true',
                     help='delete the surfaces that are misaligned')

#------------------------------------------------------------------------------
# Define some functions
#------------------------------------------------------------------------------
def build_surf_dir_path(args):
    """
    Build the path to the surface directory from the sub and occ
    """
    surf_dir = os.path.join(args.data_dir, 
                            'SUB_DATA',
                            args.sub,
                            'SURFER',
                            args.occ,
                            'surf')
    
    return surf_dir

def get_n_vertices_pial(surf_dir):
    """
    Create a dictionary that lists the number of vertices in the
    pial surface for the left and right hemispheres.
    """
    n_pial_d = {}

    for hemi in ['lh', 'rh']:
        coords, _ = nib.freesurfer.read_geometry(os.path.join(surf_dir,
                                                    '{hemi}.pial'.format(hemi=hemi)))

        n_pial_d[hemi] = len(coords)

    return n_pial_d

def test_surfaces_in_dir(surf_dir, args):
    """
    Test all the surfaces in a directory for each hemisphere separately
    to compare them to the number of vertices that the pial surface has
    """

    # First, get the number of vertices in the pial surface
    n_pial_d = get_n_vertices_pial(surf_dir)

    for hemi in ['lh', 'rh']:
        
        # Make a list of all the surfaces in the directory
        # for that hemisphere
        surf_list = glob(os.path.join(surf_dir,
                                     '{hemi}.*'.format(hemi=hemi)))

        # Remove the ".nofix" surfaces as they *should not*
        # correspond to the pial surfaces after correction
        surf_list = [ surf for surf in surf_list if not surf.endswith('.nofix')]

        for surf in surf_list:

            # Check the number of vertices in each surface against
            # the number of vertices in the pial surface
            # (unless this isn't a real surface!)
            try:
                coords, _ = nib.freesurfer.read_geometry(surf)
                if not len(coords) == n_pial_d[hemi]:
                    print ('MISMATCH: {}'.format(surf))
                    if args.delsurf:
                        os.remove(surf)

            except ValueError:
                pass

def test_f_dates():
    """
    The point of this 
    """

if __name__ == '__main__':

    args = parser.parse_args()
    surf_dir = build_surf_dir_path(args)
    test_surfaces_in_dir(surf_dir, args)

