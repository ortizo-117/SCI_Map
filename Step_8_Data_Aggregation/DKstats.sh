#!/bin/bash

# Set the base path to the derivatives folder from your recon-all output
DERIV_DIR="/path/to/derivatives"            
OUT_CSV="dk_all_stats.csv"          # File name for your output

# Temporary files
TMP_HEADER="tmp_header.txt"
TMP_ROW="tmp_row.txt"

# Clear output if exists
rm -f "$OUT_CSV" "$TMP_HEADER"

# Function to extract stats from aparc.stats
extract_aparc_stats() {
    hemi=$1
    stats_file=$2
    awk -v hemi="$hemi" '
    BEGIN { found=0 }
    /^# ColHeaders/ { found=1; next }
    found && NF >= 10 {
        region = $1
        gsub(/ /, "_", region)
        print hemi "_" region "_NumVert," $2
        print hemi "_" region "_SurfArea," $3
        print hemi "_" region "_GrayVol," $4
        print hemi "_" region "_ThickAvg," $5
        print hemi "_" region "_ThickStd," $6
        print hemi "_" region "_MeanCurv," $7
        print hemi "_" region "_GausCurv," $8
        print hemi "_" region "_FoldInd," $9
        print hemi "_" region "_CurvInd," $10
    }' "$stats_file"
}


# Function to extract stats from aseg.stats
extract_aseg_stats() {
    stats_file=$1
    grep -E '^ *[0-9]' "$stats_file" | awk '
    {
        gsub(/ /, "_", $5)
        print $5 "," $4
    }'
}

# Loop through subjects
for SUBJ_DIR in "$DERIV_DIR"/sub-*; do          # May need to change sub- based on on your subject folder naming scheme
    [ -d "$SUBJ_DIR" ] || continue
    SUBJ_ID=$(basename "$SUBJ_DIR")

    STATS_DIR="$SUBJ_DIR/stats"

    # Check necessary files exist
    LH_FILE="$STATS_DIR/lh.aparc.stats"
    RH_FILE="$STATS_DIR/rh.aparc.stats"
    ASEG_FILE="$STATS_DIR/aseg.stats"

    if [[ ! -f "$LH_FILE" || ! -f "$RH_FILE" || ! -f "$ASEG_FILE" ]]; then
        echo "Missing stats for $SUBJ_ID, skipping..."
        continue
    fi

    # Collect stats
    {
        echo "subject,$SUBJ_ID"
        extract_aparc_stats lh "$LH_FILE"
        extract_aparc_stats rh "$RH_FILE"
        extract_aseg_stats "$ASEG_FILE"
    } > "$TMP_ROW"

    # First subject – make header
    if [[ ! -f "$OUT_CSV" ]]; then
        cut -d',' -f1 "$TMP_ROW" | paste -sd, - > "$TMP_HEADER"
        cut -d',' -f2 "$TMP_ROW" | paste -sd, - >> "$OUT_CSV"
    else
        cut -d',' -f2 "$TMP_ROW" | paste -sd, - >> "$OUT_CSV"
    fi
done

# Prepend header
cat "$TMP_HEADER" "$OUT_CSV" > tmp && mv tmp "$OUT_CSV"

# Cleanup
rm -f "$TMP_HEADER" "$TMP_ROW"

echo "✅ DK stats compiled into $OUT_CSV"
