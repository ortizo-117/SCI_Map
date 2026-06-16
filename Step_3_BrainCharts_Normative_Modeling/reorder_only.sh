#!/usr/bin/env bash
set -euo pipefail

# Reorder a joined FreeSurfer CSV to match the header order in a template CSV.
# This is useful for auditing against an existing BrainCharts input sheet.

usage() {
  cat <<'USAGE'
Usage:
  reorder_only.sh --joined _dbg_joined_all.csv --template adaptation_or_test_template.csv --outfile reordered.csv

Options:
  --joined PATH      Joined FreeSurfer CSV.
  --template PATH    CSV whose header defines the desired output order.
  --outfile PATH     Reordered output CSV.
  --report PATH      Optional text report. Default: <outfile>.report.txt.
  --mapping PATH     Optional mapping CSV. Default: <outfile>.mapping.csv.
  --help             Show this help.
USAGE
}

JOINED="${JOINED:-}"
TEMPLATE="${TEMPLATE:-}"
OUTFILE="${OUTFILE:-}"
REPORT="${REPORT:-}"
MAPPING="${MAPPING:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --joined) JOINED="$2"; shift 2 ;;
    --template) TEMPLATE="$2"; shift 2 ;;
    --outfile) OUTFILE="$2"; shift 2 ;;
    --report) REPORT="$2"; shift 2 ;;
    --mapping) MAPPING="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERROR: Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

: "${JOINED:?Set --joined or JOINED}"
: "${TEMPLATE:?Set --template or TEMPLATE}"
: "${OUTFILE:?Set --outfile or OUTFILE}"

[[ -f "$JOINED" ]] || { echo "ERROR: Missing joined CSV: $JOINED" >&2; exit 1; }
[[ -f "$TEMPLATE" ]] || { echo "ERROR: Missing template CSV: $TEMPLATE" >&2; exit 1; }

REPORT="${REPORT:-${OUTFILE}.report.txt}"
MAPPING="${MAPPING:-${OUTFILE}.mapping.csv}"
mkdir -p "$(dirname "$OUTFILE")"

awk -v TEMPLATE="$TEMPLATE" -v OFS="," -F',' '
  function canon(x, y) {
    gsub(/\r/, "", x)
    sub(/\.[0-9]+$/, "", x)
    gsub(/\+/, "", x)
    gsub(/G_and_S/, "G&S", x)
    gsub(/_and_/, "&", x)
    gsub(/Ins_lG/, "Ins_lg", x)
    y = tolower(x)
    gsub(/[^0-9a-z]+/, "_", y)
    sub(/^_+/, "", y)
    sub(/_+$/, "", y)
    return y
  }

  BEGIN {
    if ((getline tline < TEMPLATE) <= 0) {
      print "ERROR: cannot read template header" > "/dev/stderr"
      exit 1
    }
    nT = split(tline, T, ",")
    close(TEMPLATE)
  }

  NR == 1 {
    nJ = split($0, J, ",")
    for (i = 1; i <= nJ; i++) JIDX[canon(J[i])] = i

    print tline
    print "Template columns: " nT > "/dev/stderr"
    print "Joined columns:   " nJ > "/dev/stderr"

    for (i = 1; i <= nT; i++) {
      c = canon(T[i])
      if (c in JIDX || c == "subject" || c == "subject_id" || c == "session" || c == "ses") {
        matched++
      } else {
        missing++
        miss[missing] = T[i]
      }
    }
    print "Header matches:   " matched > "/dev/stderr"
    print "Header missing:   " missing > "/dev/stderr"
    for (i = 1; i <= missing && i <= 80; i++) print miss[i] > "/dev/stderr"
    next
  }

  {
    n = split($0, A, ",")
    fs_key = A[1]
    subj_id = fs_key
    ses_id = ""
    if (match(fs_key, /^sub-([^_]+)_ses-([A-Za-z0-9._-]+)/, m)) {
      subj_id = "sub-" m[1]
      ses_id = m[2]
    }

    for (i = 1; i <= nT; i++) {
      c = canon(T[i])
      val = ""
      if (c == "subject" || c == "subject_id") {
        val = fs_key
      } else if (c == "session" || c == "ses") {
        val = ses_id
      } else if (c in JIDX) {
        idx = JIDX[c]
        if (idx <= n) val = A[idx]
      }
      printf "%s%s", (i == 1 ? "" : OFS), val
    }
    printf "\n"
  }
' "$JOINED" > "$OUTFILE" 2> "$REPORT"

awk -F, -v TEMPLATE="$TEMPLATE" '
  function canon(x, y) {
    gsub(/\r/, "", x)
    sub(/\.[0-9]+$/, "", x)
    gsub(/\+/, "", x)
    gsub(/G_and_S/, "G&S", x)
    gsub(/_and_/, "&", x)
    gsub(/Ins_lG/, "Ins_lg", x)
    y = tolower(x)
    gsub(/[^0-9a-z]+/, "_", y)
    sub(/^_+/, "", y)
    sub(/_+$/, "", y)
    return y
  }
  NR == 1 {
    nJ = split($0, J, ",")
    for (i = 1; i <= nJ; i++) CJ[i] = canon(J[i])
    next
  }
  END {
    if ((getline line < TEMPLATE) <= 0) {
      print "ERROR: cannot read template header" > "/dev/stderr"
      exit 1
    }
    nT = split(line, T, ",")
    print "template_header,joined_match"
    for (i = 1; i <= nT; i++) {
      ct = canon(T[i])
      jm = ""
      for (j = 1; j <= nJ; j++) {
        if (CJ[j] == ct) {
          jm = J[j]
          break
        }
      }
      gsub(/"/, "\"\"", T[i])
      gsub(/"/, "\"\"", jm)
      printf "\"%s\",\"%s\"\n", T[i], jm
    }
  }
' "$JOINED" > "$MAPPING"

echo "Wrote:"
echo "  Reordered CSV: $OUTFILE"
echo "  Report:        $REPORT"
echo "  Mapping CSV:   $MAPPING"
