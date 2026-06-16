#!/usr/bin/env bash
set -euo pipefail

# Convert the joined FreeSurfer table into BrainCharts-compatible column names
# and optionally merge participant metadata required by the normative model.

usage() {
  cat <<'USAGE'
Usage:
  make_brainchart_outputs.sh --joined _dbg_joined_all.csv --dict keys_lifespan57K_82sites.csv --outdir outputs [options]

Options:
  --joined PATH              Joined FreeSurfer table from build_freesurfer_sheet.sh.
  --dict PATH                CSV with columns joined_header,template_match.
  --metadata PATH            Participant metadata CSV. Recommended.
  --metadata-subject COL     Subject ID column in metadata. Default: auto-detect.
  --outfile PATH             Final output CSV. Default: <outdir>/braincharts_all_subjects.csv.
  --outdir PATH              Output directory. Default: directory containing --joined.
  --help                     Show this help.

Metadata should include at least:
  subject, age, sex, site, sitenum, cohort

The subject values must match the FreeSurfer subject directory names in the
joined table, for example sub-CON1003_ses-BASE.
USAGE
}

JOINED="${JOINED:-}"
DICT="${DICT:-}"
METADATA="${METADATA:-}"
METADATA_SUBJECT_COL="${METADATA_SUBJECT_COL:-}"
OUTDIR="${OUTDIR:-}"
OUTFILE="${OUTFILE:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --joined) JOINED="$2"; shift 2 ;;
    --dict) DICT="$2"; shift 2 ;;
    --metadata) METADATA="$2"; shift 2 ;;
    --metadata-subject) METADATA_SUBJECT_COL="$2"; shift 2 ;;
    --outdir) OUTDIR="$2"; shift 2 ;;
    --outfile) OUTFILE="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERROR: Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

: "${JOINED:?Set --joined or JOINED}"
: "${DICT:?Set --dict or DICT}"

[[ -f "$JOINED" ]] || { echo "ERROR: Joined CSV not found: $JOINED" >&2; exit 1; }
[[ -f "$DICT" ]] || { echo "ERROR: Header dictionary not found: $DICT" >&2; exit 1; }

if [[ -z "$OUTDIR" ]]; then
  OUTDIR="$(dirname "$JOINED")"
fi
mkdir -p "$OUTDIR"

if [[ -z "$OUTFILE" ]]; then
  OUTFILE="$OUTDIR/braincharts_all_subjects.csv"
fi

TMP_BRAIN="$OUTDIR/_dbg_braincharts_features_only.csv"
MAP_REPORT="$OUTDIR/_dbg_braincharts_column_mapping.csv"

awk -F',' -v OFS=',' -v MAP_REPORT="$MAP_REPORT" '
  function trim(x) {
    gsub(/\r$/, "", x)
    sub(/^[[:space:]]+/, "", x)
    sub(/[[:space:]]+$/, "", x)
    if (x ~ /^".*"$/) {
      sub(/^"/, "", x)
      sub(/"$/, "", x)
    }
    return x
  }

  NR == FNR {
    if (FNR == 1) {
      h1 = tolower(trim($1))
      if (h1 == "joined_header") next
    }
    req = trim($1)
    ren = trim($2)
    if (req == "") next
    dict_req[++nreq] = req
    dict_out[nreq] = (ren == "" || ren == "NA" || ren == "na" ? req : ren)
    next
  }

  FNR == 1 {
    for (i = 1; i <= NF; i++) {
      h = trim($i)
      idx[h] = i
    }

    print "dictionary_column,output_column,joined_column_found" > MAP_REPORT
    out = ""
    for (i = 1; i <= nreq; i++) {
      req = dict_req[i]
      name_out = dict_out[i]
      found = (req in idx ? req : "")
      print req, name_out, found > MAP_REPORT
      out = (i == 1 ? name_out : out OFS name_out)
    }
    print out
    next
  }

  {
    for (i = 1; i <= NF; i++) row[i] = $i
    out = ""
    for (k = 1; k <= nreq; k++) {
      req = dict_req[k]
      v = ""
      if (req in idx) {
        j = idx[req]
        if (j <= NF) v = row[j]
      }
      out = (k == 1 ? v : out OFS v)
    }
    print out
  }
' "$DICT" "$JOINED" > "$TMP_BRAIN"

if [[ -n "$METADATA" ]]; then
  [[ -f "$METADATA" ]] || { echo "ERROR: Metadata CSV not found: $METADATA" >&2; exit 1; }

  awk -F',' -v OFS=',' -v SUBJECT_COL="$METADATA_SUBJECT_COL" '
    function trim(x) {
      gsub(/\r$/, "", x)
      sub(/^[[:space:]]+/, "", x)
      sub(/[[:space:]]+$/, "", x)
      if (x ~ /^".*"$/) {
        sub(/^"/, "", x)
        sub(/"$/, "", x)
      }
      return x
    }
    function lower(x) {
      return tolower(trim(x))
    }

    NR == FNR {
      if (FNR == 1) {
        nbrain = NF
        for (i = 1; i <= NF; i++) brain_header[i] = $i
        next
      }
      key = trim($1)
      brain_row[key] = $0
      brain_seen[key] = 1
      next
    }

    FNR == 1 {
      nmeta = NF
      subject_idx = 0
      for (i = 1; i <= NF; i++) {
        meta_header[i] = $i
        h = lower($i)
        if (SUBJECT_COL != "" && trim($i) == SUBJECT_COL) subject_idx = i
        if (SUBJECT_COL == "" && (h == "subject" || h == "subject_id" || h == "subjectid" || h == "id" || h == "sub_id")) {
          subject_idx = i
        }
      }
      if (subject_idx == 0) {
        print "ERROR: Could not find subject column in metadata. Use --metadata-subject." > "/dev/stderr"
        exit 1
      }

      printf "%s", $0
      for (i = 2; i <= nbrain; i++) printf "%s%s", OFS, brain_header[i]
      printf "\n"
      next
    }

    {
      key = trim($subject_idx)
      if (!(key in brain_seen)) {
        print "WARNING: Metadata subject not found in FreeSurfer table: " key > "/dev/stderr"
        next
      }

      printf "%s", $0
      split(brain_row[key], b, ",")
      for (i = 2; i <= nbrain; i++) printf "%s%s", OFS, b[i]
      printf "\n"
      used[key] = 1
    }

    END {
      for (key in brain_seen) {
        if (!(key in used)) {
          print "WARNING: FreeSurfer subject had no metadata row: " key > "/dev/stderr"
        }
      }
    }
  ' "$TMP_BRAIN" "$METADATA" > "$OUTFILE"
else
  cp "$TMP_BRAIN" "$OUTFILE"
  echo "WARNING: No metadata supplied. Add subject, age, sex, site, sitenum, and cohort before running the split and normative model." >&2
fi

echo "Wrote:"
echo "  BrainCharts input:  $OUTFILE"
echo "  Feature-only table: $TMP_BRAIN"
echo "  Mapping report:     $MAP_REPORT"
echo "[OK] BrainCharts table preparation complete."
