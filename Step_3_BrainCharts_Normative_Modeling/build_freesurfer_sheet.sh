#!/usr/bin/env bash
set -euo pipefail

# Build a wide FreeSurfer table for BrainCharts preparation.
#
# The BrainCharts cortical-thickness lifespan model expects Destrieux
# (aparc.a2009s) cortical thickness columns plus selected aseg volumes. This
# script extracts those tables from a FreeSurfer SUBJECTS_DIR-like tree, a BIDS
# derivatives tree, or a longitudinal FreeSurfer output folder.

usage() {
  cat <<'USAGE'
Usage:
  build_freesurfer_sheet.sh --derivs /path/to/freesurfer_outputs --outdir /path/to/outputs [options]

Options:
  --derivs PATH          Directory containing FreeSurfer subject folders.
  --outdir PATH          Output directory for extracted CSV files.
  --parc NAME            FreeSurfer cortical parcellation. Default: aparc.a2009s.
  --subject-regex REGEX  Optional grep -E regex used to keep only matching subject folders.
  --help                 Show this help.

Outputs:
  _dbg_aseg.volume.csv
  _dbg_lh.<parc>.thickness.csv
  _dbg_rh.<parc>.thickness.csv
  _dbg_lh.<parc>.area.csv
  _dbg_rh.<parc>.area.csv
  _dbg_joined_all.csv
USAGE
}

DERIVS="${DERIVS:-}"
OUTDIR="${OUTDIR:-}"
PARC="${PARC:-aparc.a2009s}"
SUBJECT_REGEX="${SUBJECT_REGEX:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --derivs) DERIVS="$2"; shift 2 ;;
    --outdir) OUTDIR="$2"; shift 2 ;;
    --parc) PARC="$2"; shift 2 ;;
    --subject-regex) SUBJECT_REGEX="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERROR: Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

: "${DERIVS:?Set --derivs or DERIVS to your FreeSurfer output path}"
: "${OUTDIR:?Set --outdir or OUTDIR to your output path}"

if [[ ! -d "$DERIVS" ]]; then
  echo "ERROR: FreeSurfer output directory not found: $DERIVS" >&2
  exit 1
fi

command -v aparcstats2table >/dev/null 2>&1 || {
  echo "ERROR: aparcstats2table not found. Source FreeSurfer first." >&2
  exit 1
}
command -v asegstats2table >/dev/null 2>&1 || {
  echo "ERROR: asegstats2table not found. Source FreeSurfer first." >&2
  exit 1
}

mkdir -p "$OUTDIR"

WRK="$(mktemp -d)"
trap 'rm -rf "$WRK"' EXIT
FARM="$WRK/fs_subjects"
mkdir -p "$FARM"

echo "Scanning FreeSurfer outputs under: $DERIVS"

found=0
while IFS= read -r aseg_file; do
  subj_dir="$(dirname "$(dirname "$aseg_file")")"
  subject_name="$(basename "$subj_dir")"

  if [[ -n "$SUBJECT_REGEX" ]] && ! grep -Eq "$SUBJECT_REGEX" <<<"$subject_name"; then
    continue
  fi

  [[ -e "$FARM/$subject_name" ]] || ln -s "$subj_dir" "$FARM/$subject_name"
  found=1
done < <(find "$DERIVS" -type f -path "*/stats/aseg.stats" 2>/dev/null | sort)

if [[ "$found" -eq 0 ]]; then
  echo "ERROR: No FreeSurfer subjects with stats/aseg.stats were found under $DERIVS" >&2
  exit 1
fi

find "$FARM" -mindepth 1 -maxdepth 1 -type l -printf '%f\n' | sort > "$WRK/subjects.txt"
export SUBJECTS_DIR="$FARM"

echo "SUBJECTS_DIR farm: $SUBJECTS_DIR"
echo "Subjects included: $(wc -l < "$WRK/subjects.txt")"

run_aparc_table() {
  local hemi="$1"
  local meas="$2"
  local outfile="$3"

  aparcstats2table \
    --hemi "$hemi" \
    --parc "$PARC" \
    --meas "$meas" \
    --subjectsfile "$WRK/subjects.txt" \
    --skip \
    --delimiter comma \
    --tablefile "$outfile"
}

echo "Extracting aseg volumes and ${PARC} cortical thickness/surface area tables..."

asegstats2table \
  --subjectsfile "$WRK/subjects.txt" \
  --meas volume \
  --skip \
  --delimiter comma \
  --tablefile "$OUTDIR/_dbg_aseg.volume.csv"

run_aparc_table lh thickness "$OUTDIR/_dbg_lh.${PARC}.thickness.csv"
run_aparc_table rh thickness "$OUTDIR/_dbg_rh.${PARC}.thickness.csv"
run_aparc_table lh area "$OUTDIR/_dbg_lh.${PARC}.area.csv"
run_aparc_table rh area "$OUTDIR/_dbg_rh.${PARC}.area.csv"

for f in \
  "$OUTDIR/_dbg_aseg.volume.csv" \
  "$OUTDIR/_dbg_lh.${PARC}.thickness.csv" \
  "$OUTDIR/_dbg_rh.${PARC}.thickness.csv" \
  "$OUTDIR/_dbg_lh.${PARC}.area.csv" \
  "$OUTDIR/_dbg_rh.${PARC}.area.csv"; do
  awk -F, 'BEGIN{OFS=","} NR==1{$1="subject_id"} {print}' "$f" > "${f}.tmp"
  mv "${f}.tmp" "$f"
done

JOINED="$OUTDIR/_dbg_joined_all.csv"

echo "Joining extracted tables into: $JOINED"

awk -F, -v OFS=',' '
  FNR == 1 {
    file++
    nfields[file] = NF
    for (i = 1; i <= NF; i++) {
      header[file,i] = $i
    }
    next
  }
  {
    key = $1
    if (!(key in seen)) {
      seen[key] = 1
      order[++nkeys] = key
    }
    for (i = 2; i <= nfields[file]; i++) {
      values[file,key,i] = $i
    }
  }
  END {
    printf "subject_id"
    for (f = 1; f <= file; f++) {
      for (i = 2; i <= nfields[f]; i++) {
        printf "%s%s", OFS, header[f,i]
      }
    }
    printf "\n"

    for (k = 1; k <= nkeys; k++) {
      key = order[k]
      printf "%s", key
      for (f = 1; f <= file; f++) {
        for (i = 2; i <= nfields[f]; i++) {
          printf "%s%s", OFS, values[f,key,i]
        }
      }
      printf "\n"
    }
  }
' \
  "$OUTDIR/_dbg_lh.${PARC}.thickness.csv" \
  "$OUTDIR/_dbg_rh.${PARC}.thickness.csv" \
  "$OUTDIR/_dbg_aseg.volume.csv" \
  "$OUTDIR/_dbg_lh.${PARC}.area.csv" \
  "$OUTDIR/_dbg_rh.${PARC}.area.csv" \
  > "$JOINED"

echo "Wrote:"
echo "  $OUTDIR/_dbg_aseg.volume.csv"
echo "  $OUTDIR/_dbg_lh.${PARC}.thickness.csv"
echo "  $OUTDIR/_dbg_rh.${PARC}.thickness.csv"
echo "  $OUTDIR/_dbg_lh.${PARC}.area.csv"
echo "  $OUTDIR/_dbg_rh.${PARC}.area.csv"
echo "  $JOINED"
echo "[OK] FreeSurfer extraction complete."
