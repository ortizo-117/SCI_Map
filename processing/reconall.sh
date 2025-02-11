#!/bin/bash

# BIDS rawdata directory
RAWDATA_DIR="/mnt/c/Users/kramerlab/Documents/freesurfer_SCI_extra_subjects/rawdata"

# Target derivatives directory
DERIVATIVES_DIR="/mnt/c/Users/kramerlab/Documents/freesurfer_SCI_extra_subjectsI/derivatives"
mkdir -p "$DERIVATIVES_DIR"

# Loop through all subject folders in the rawdata directory
for SUBJECT_DIR in "$RAWDATA_DIR"/Sub_*; do
  if [ -d "$SUBJECT_DIR" ]; then
    # Extract subject ID
    SUBJECT_ID=$(basename "$SUBJECT_DIR")

    # Find the T1w NIFTI file
    NIFTI_FILE=$(find "$SUBJECT_DIR/" -name "*_T1.nii" -type f | head -n 1)
    echo $NIFTI_FILE

    if [ -n "$NIFTI_FILE" ]; then
      # Define derivatives folder for the subject
      SUBJECT_DERIV_DIR="$DERIVATIVES_DIR/$SUBJECT_ID"

      # Check if subject directory already exists
      if [ -d "$SUBJECT_DERIV_DIR" ]; then
        echo "Subject $SUBJECT_ID already exists. Skipping..."
        continue
      fi

      # Run recon-all
      echo "Running recon-all for $SUBJECT_ID"
      recon-all -subject "$SUBJECT_ID" -i "$NIFTI_FILE" -sd "$DERIVATIVES_DIR" -all

      echo "Recon-all completed for $SUBJECT_ID. Output in $SUBJECT_DERIV_DIR"
    else
      echo "No T1w NIFTI file found for $SUBJECT_ID in rawdata. Skipping recon-all."
    fi
  fi
done

echo "Recon-all processing complete. Outputs are in $DERIVATIVES_DIR."
