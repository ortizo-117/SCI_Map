#!/bin/bash

# Directories
BIDS_DIR="/path/to/BIDS/directory"                     # Root BIDS dataset
DERIVATIVES_DIR="${BIDS_DIR}/derivatives" # FreeSurfer derivatives folder
SUBJECTS_DIR="${DERIVATIVES_DIR}"                    # FreeSurfer SUBJECTS_DIR
export SUBJECTS_DIR

# List of subjects
subjects=$(ls ${SUBJECTS_DIR} | grep "sub-")

# Extract subcortical statistics (aseg.stats) and transpose
echo "Extracting transposed subcortical volumes (subjects as rows, regions as columns)..."

asegstats2table --subjects $subjects \
                --meas volume \
                --tablefile ${DERIVATIVES_DIR}/subcortical_volumes.csv

echo "Subcortical volumes extracted:"
echo "- File: ${DERIVATIVES_DIR}/subcortical_volumes.csv"