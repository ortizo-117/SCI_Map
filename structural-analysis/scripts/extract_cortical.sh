#!/bin/bash

# Directories
BIDS_DIR="/path/to/BIDS/directory" # Root BIDS dataset
DERIVATIVES_DIR="${BIDS_DIR}/derivatives"                # FreeSurfer derivatives folder
SUBJECTS_DIR="${DERIVATIVES_DIR}"                        # FreeSurfer SUBJECTS_DIR
export SUBJECTS_DIR

# List of subjects
subjects=$(ls ${SUBJECTS_DIR} | grep "sub-")

# Output file
OUTPUT_FILE="${DERIVATIVES_DIR}/cortical_stats_long.csv"

# Header for the output file
echo "Subject,Region,Hemisphere,Measure,Value" > $OUTPUT_FILE

# Loop through subjects and hemispheres
for subj in $subjects; do
    for hemi in lh rh; do
        # Path to the .stats file
        STATS_FILE="${SUBJECTS_DIR}/${subj}/stats/${hemi}.aparc.a2009s.stats"
        
        # Check if the file exists
        if [[ -f "$STATS_FILE" ]]; then
            # Extract the subject ID and hemisphere
            subject_id=$(echo $subj | cut -d '-' -f 2)

            # Parse the file to extract regions and measurements
            awk -v subject="$subject_id" -v hemisphere="$hemi" '
                BEGIN { FS="\\s+"; OFS="," }
                /^[^#]/ {  # Skip lines starting with #
                    region = $1;    # First column is the region name
                    # Map the correct measurements to columns
                    measure_names = "area,volume,thickness,thicknessstd,thickness.T1,meancurv,gauscurv,foldind,curvind";
                    split(measure_names, measures, ",");
                    for (i = 2; i <= NF; i++) {
                        print subject, region, hemisphere, measures[i-1], $i;
                    }
                }
            ' "$STATS_FILE" >> $OUTPUT_FILE
        else
            echo "Warning: File $STATS_FILE does not exist. Skipping."
        fi
    done
done

echo "Cortical statistics parsed and saved to long format:"
echo "- Output file: $OUTPUT_FILE"
