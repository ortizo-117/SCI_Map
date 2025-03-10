#!/bin/bash

# Define the path to the derivatives folder
DERIVATIVES_PATH="/path/to/derivatives"
OUTPUT_CSV="cortical_thickness.csv"

# Write the header to the CSV file
echo "subjectid,lh_thickness,rh_thickness" > "$OUTPUT_CSV"

# Loop through each subject directory
for subject_dir in "$DERIVATIVES_PATH"/sub-*; do
    if [ -d "$subject_dir" ]; then
        # Extract subject ID
        subject_id=$(basename "$subject_dir")
        
        # Paths to the stats files
        lh_stats_file="$subject_dir/stats/lh.aparc.a2009s.stats"
        rh_stats_file="$subject_dir/stats/rh.aparc.a2009s.stats"
        
        # Extract average thickness values using grep
        lh_thickness=$(grep -e "MeanThickness" "$lh_stats_file" | awk '{print $(NF-1)}')
        rh_thickness=$(grep -e "MeanThickness" "$rh_stats_file" | awk '{print $(NF-1)}')
        
        # Append the values to the CSV file
        echo "$subject_id,$lh_thickness,$rh_thickness" >> "$OUTPUT_CSV"
    fi
done

echo "Cortical thickness extraction complete. Results saved to $OUTPUT_CSV."
