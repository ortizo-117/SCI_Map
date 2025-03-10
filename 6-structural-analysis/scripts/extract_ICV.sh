#!/bin/bash

# Define the path to the BIDS derivatives directory
BIDS_DIR="/path/to/derivatives"

# Define the output CSV file
OUTPUT_CSV="icv_data.csv"

# Initialize the CSV file with a header
echo "SubjectID,ICV" > "$OUTPUT_CSV"

# Loop through all subject directories
for SUBJECT_DIR in "$BIDS_DIR"/sub-*/; do
  # Extract the subject ID (e.g., sub-001)
  SUBJECT_ID=$(basename "$SUBJECT_DIR")

  # Define the path to the aseg.stats file
  ASEG_STATS_FILE="${SUBJECT_DIR}/stats/aseg.stats"

  # Check if the aseg.stats file exists
  if [[ -f "$ASEG_STATS_FILE" ]]; then
    # Extract the Intracranial Volume (ICV) from the aseg.stats file
    ICV=$(grep -m 1 "Estimated Total Intracranial Volume" "$ASEG_STATS_FILE" | awk '{print $(NF-1)}')

    # Append the SubjectID and ICV to the CSV file
    echo "${SUBJECT_ID},${ICV}" >> "$OUTPUT_CSV"
  else
    echo "aseg.stats file not found for ${SUBJECT_ID}. Skipping..."
  fi
done

echo "ICV extraction complete. Data saved in $OUTPUT_CSV"
