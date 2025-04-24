#!/bin/bash

# BIDS rawdata directory
RAWDATA_DIR="/mnt/c/Users/kramerlab/Documents/freesurfer_SCI_extra_subjects/rawdata"

# Target derivatives directory
DERIVATIVES_DIR="/mnt/c/Users/kramerlab/Documents/freesurfer_SCI_extra_subjectsI/derivatives"
mkdir -p "$DERIVATIVES_DIR"

# Loop through all subject folders in the rawdata directory
for SUBJECT_DIR in "$RAWDATA_DIR"/sub-*; do
  if [ -d "$SUBJECT_DIR" ]; then
    # Extract subject ID
    SUBJECT_ID=$(basename "$SUBJECT_DIR")

    # Try to find T1w NIFTI file (either .nii or .nii.gz)
    NIFTI_FILE=$(find "$SUBJECT_DIR/" -name "*_T1.nii" -type f | head -n 1)
    GZ_NIFTI_FILE=$(find "$SUBJECT_DIR/" -name "*_T1.nii.gz" -type f | head -n 1)

    if [ -z "$NIFTI_FILE" ] && [ -n "$GZ_NIFTI_FILE" ]; then
      # Unzip the .nii.gz file to a temporary .nii file
      TEMP_NIFTI_FILE="${GZ_NIFTI_FILE%.gz}"
      echo "Unzipping $GZ_NIFTI_FILE to $TEMP_NIFTI_FILE"
      gunzip -c "$GZ_NIFTI_FILE" > "$TEMP_NIFTI_FILE"
      NIFTI_FILE="$TEMP_NIFTI_FILE"
    fi

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

      # Clean up temporary unzipped file if it was created
      if [ "$NIFTI_FILE" == "$TEMP_NIFTI_FILE" ]; then
        echo "Removing temporary file $TEMP_NIFTI_FILE"
        rm "$TEMP_NIFTI_FILE"
      fi
    else
      echo "No T1w NIFTI file found for $SUBJECT_ID in rawdata. Skipping recon-all."
    fi
  fi
done


echo "Recon-all processing complete. Outputs are in $DERIVATIVES_DIR."
