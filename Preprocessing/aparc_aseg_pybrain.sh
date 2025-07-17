#!/bin/bash

# Default values
ROOT_DIR="/mnt/c/users/kramerlab/Documents/freesurfer_SCI"
OUTPUT_DIR="/mnt/c/users/kramerlab/Documents/freesurfer_SCI/results_pybrain"
APARC_OPTION="aparc.a2009s"

# Usage function
usage() {
    echo "Usage: $0 -r <BIDS_root> -o <output_dir> [-p <parc_scheme>]"
    exit 1
}


# Check if mandatory arguments are provided
if [[ -z "$ROOT_DIR" || -z "$OUTPUT_DIR" ]]; then
    echo "Error: Both -r (root folder) and -o (output folder) are required."
    usage
fi

# Set the derivatives directory
DERIVATIVES_DIR="$ROOT_DIR/derivatives"

# Check if the derivatives directory exists
if [[ ! -d "$DERIVATIVES_DIR" ]]; then
    echo "Error: The derivatives directory does not exist: $DERIVATIVES_DIR"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Get the list of subject IDs from the derivatives directory
#SUBJECTS=($(ls -d "$DERIVATIVES_DIR"/Sub_* 2>/dev/null | xargs -n 1 basename))
SUBJECTS=($(ls -d "$DERIVATIVES_DIR"/sub-* 2>/dev/null))

# Check if subjects were found
if [[ ${#SUBJECTS[@]} -eq 0 ]]; then
    echo "Error: No subjects found in $DERIVATIVES_DIR"
    exit 1
fi

echo "$SUBJECTS"
# Convert subjects array to space-separated string
SUBJECTS_LIST="${SUBJECTS[*]}"
#SUBJECTS_LIST=$(IFS=,; echo "${SUBJECTS[*]}")

echo "$SUBJECTS_LIST"


# Run aparcstats2table for left and right hemispheres, for thickness and surface area
for HEMI in lh rh; do
    for MEASURE in thickness; do
        COMMAND="aparcstats2table --subjects $SUBJECTS_LIST --hemi $HEMI --parc $APARC_OPTION --measure $MEASURE --tablefile $OUTPUT_DIR/${HEMI}_${MEASURE}.txt"
        echo "Executing: $COMMAND"
        eval "$COMMAND"

    done
done

# Construct and execute command for asegstats2table
ASEG_COMMAND="asegstats2table --subjects $SUBJECTS_LIST --tablefile $OUTPUT_DIR/aseg_stats.txt"
echo "Executing: $ASEG_COMMAND"
eval "$ASEG_COMMAND"

echo "Processing completed. Output files are in: $OUTPUT_DIR"




# File paths
LH_THICKNESS_FILE="$OUTPUT_DIR/lh_thickness.txt"
RH_THICKNESS_FILE="$OUTPUT_DIR/rh_thickness.txt"
ASEG_FILE="$OUTPUT_DIR/aseg_stats.txt"
CONCATENATED_FILE="$OUTPUT_DIR/concatenated_results.txt"
SUBJECTS_FILE="$OUTPUT_DIR/subject_ids.txt"

# Function to remove first column and last 3 columns from a file
clean_aparc_file() {
    local input_file="$1"
    local output_file="$2"

    # Get the total number of fields
    TOTAL_COLS=$(awk -F'\t' '{print NF; exit}' "$input_file")
    
    # Calculate the number of columns to keep (removing first and last 3)
    KEEP_COLS=$((TOTAL_COLS-2))

    # Ensure there are enough columns to remove
    if [[ $KEEP_COLS -gt 1 ]]; then
        cut -f2-"$KEEP_COLS" "$input_file" > "$output_file"
    else
        echo "Error: Not enough columns in $input_file to remove required columns."
        exit 1
    fi
}



clean_stat_file() {
    local input_file="$1"
    local output_file="$2"

    # Define the headers to be removed
    REMOVE_HEADERS=("5th-Ventricle" "WM-hypointensities" "Left-WM-hypointensities" "Right-WM-hypointensities"
                    "non-WM-hypointensities" "Left-non-WM-hypointensities" "Right-non-WM-hypointensities"
                    "Optic-Chiasm" "CC_Posterior" "CC_Mid_Posterior" "CC_Central" "CC_Mid_Anterior"
                    "CC_Anterior" "BrainSegVol" "BrainSegVolNotVent" "lhCortexVol" "rhCortexVol"
                    "CortexVol" "lhCerebralWhiteMatterVol" "rhCerebralWhiteMatterVol"
                    "CerebralWhiteMatterVol" "MaskVol" "BrainSegVol-to-eTIV" "MaskVol-to-eTIV"
                    "lhSurfaceHoles" "rhSurfaceHoles" "SurfaceHoles")

    # Read header line and determine which columns to keep
    awk -F'\t' -v OFS='\t' '
        BEGIN {
            split("'"${REMOVE_HEADERS[*]}"'", remove_headers, " ");  # Convert array to awk variable
        }
        NR == 1 {
            for (i = 2; i <= NF; i++) {  # Start from 2 to remove the first column
                keep[i] = 1;  # By default, keep all columns
                for (j in remove_headers) {
                    if ($i == remove_headers[j]) {
                        keep[i] = 0;  # Mark column for removal
                        break;
                    }
                }
            }
        }
        {
            first = 1;
            for (i = 2; i <= NF; i++) {  # Skip the first column
                if (keep[i]) {
                    if (!first) printf OFS;
                    printf "%s", $i;
                    first = 0;
                }
            }
            print "";
        }
    ' "$input_file" > "$output_file"
}



# Process aparcstats2table output (remove first column & last three columns)
clean_aparc_file "$LH_THICKNESS_FILE" "$OUTPUT_DIR/lh_thickness_filtered.txt"
clean_aparc_file "$RH_THICKNESS_FILE" "$OUTPUT_DIR/rh_thickness_filtered.txt"
clean_stat_file "$ASEG_FILE" "$OUTPUT_DIR/aseg_stats_filtered.txt"

# Save only the subject folder names to the subject IDs file
echo "ID" > "$SUBJECTS_FILE"


for subject in "${SUBJECTS[@]}"; do
    basename "$subject"
done >> "$SUBJECTS_FILE"  # Append results to the file

# Concatenate horizontally
paste "$OUTPUT_DIR/subject_ids.txt"\
      "$OUTPUT_DIR/lh_thickness_filtered.txt" \
      "$OUTPUT_DIR/rh_thickness_filtered.txt" \
      "$OUTPUT_DIR/aseg_stats_filtered.txt" > "$CONCATENATED_FILE"

echo "Concatenation complete. Results saved in: $CONCATENATED_FILE"
