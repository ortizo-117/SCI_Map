#!/bin/bash

# === Config ===
DERIVATIVES_DIR="/path/to/derivatives"
OUTPUT_FILE="wm_volumes.csv"

# === Get structure names from first valid wmparc ===
for SUBJECT_DIR in "$DERIVATIVES_DIR"/sub-*; do
    WMPARC="$SUBJECT_DIR/stats/wmparc.stats"
    if [[ -f "$WMPARC" ]]; then
        mapfile -t STRUCT_NAMES < <(awk '
            BEGIN {in_table=0}
            /^# ColHeaders/ {in_table=1; next}
            in_table && $0 !~ /^#/ && NF >= 5 {print $5}
        ' "$WMPARC")
        break
    fi
done

if [[ ${#STRUCT_NAMES[@]} -eq 0 ]]; then
    echo "❌ Could not extract structure names from any wmparc file."
    exit 1
fi

# === Write CSV header ===
{
    echo -n "subjectID,TotalCerebralWM,RightCerebralWM,LeftCerebralWM"
    for NAME in "${STRUCT_NAMES[@]}"; do
        echo -n ",$NAME"
    done
    echo
} > "$OUTPUT_FILE"

# === Process each subject ===
for SUBJECT_DIR in "$DERIVATIVES_DIR"/sub-*; do
    SUBJECT_ID=$(basename "$SUBJECT_DIR")
    WMPARC="$SUBJECT_DIR/stats/wmparc.stats"

    if [[ -f "$WMPARC" ]]; then
        # Extract white matter volumes from '# Measure' lines (4th field in CSV)
        TOTAL_WM=$(awk -F',' '/# Measure CerebralWhiteMatter/ {gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}' "$WMPARC")
        RH_WM=$(awk -F',' '/# Measure rhCerebralWhiteMatter/ {gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}' "$WMPARC")
        LH_WM=$(awk -F',' '/# Measure lhCerebralWhiteMatter/ {gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}' "$WMPARC")

        # Build volume map: structure → volume
        declare -A VOLS
        while read -r _ _ _ VOLUME NAME _; do
            VOLS["$NAME"]="$VOLUME"
        done < <(awk '
            BEGIN {in_table=0}
            /^# ColHeaders/ {in_table=1; next}
            in_table && $0 !~ /^#/ && NF >= 5
        ' "$WMPARC")

        # Output subject row
        {
            echo -n "$SUBJECT_ID,${TOTAL_WM:-0},${RH_WM:-0},${LH_WM:-0}"
            for NAME in "${STRUCT_NAMES[@]}"; do
                echo -n ",${VOLS[$NAME]:-0}"
            done
            echo
        } >> "$OUTPUT_FILE"

        unset VOLS
    else
        echo "⚠️ Missing wmparc for $SUBJECT_ID" >&2
    fi
done

echo "✅ Done! Output saved to: $OUTPUT_FILE"
