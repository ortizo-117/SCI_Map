#!/usr/bin/env bash
# file: recon_all.sh
#
# This script discovers BIDS‑style subject folders (Sub_*) within a *rawdata*
# directory, locates each subject’s first T1‑weighted NIfTI, and executes
# FreeSurfer’s recon‑all in parallel across hemispheres **and** subjects.
#
# Revision History:
#
# 20250424 (YQ): initial version
#
#***************************************************************************
#
# usage:
#   recon_all.sh [-r <rawdata_dir>] [-d <derivatives_dir>]
#                [-t <threads>] [-q <queue_size>]
#
# arguments:
#   -r          Root rawdata folder containing Sub_* directories
#               (default: /mnt/c/Users/kramerlab/Documents/freesurfer_SCI_extra_subjects/rawdata).
#   -d          Target FreeSurfer SUBJECTS_DIR / derivatives folder
#               (default: /mnt/c/Users/kramerlab/Documents/freesurfer_SCI_extra_subjectsI/derivatives).
#   -t          Total OpenMP threads per *subject*  (default: 8).
#   -q          Maximum subjects processed concurrently (default: 2).
#   -h, --help  Show this help.
#
# description:
#   1.  For each Sub_* directory inside <rawdata_dir> the script searches for a
#       file matching *_T1.nii (modify pattern below if needed).
#   2.  If <derivatives_dir>/<Sub_*> already exists, that subject is skipped.
#   3.  Eligible subjects are placed in a FIFO queue of length <queue_size>.
#   4.  Each subject is executed as:
#          recon-all -subject <Sub_ID> -i <T1.nii> -sd <derivatives_dir> \
#                    -all -parallel -openmp <threads>
#       where recon-all internally assigns <threads>/2 to each hemisphere.
#
#   Logs go to:
#       <derivatives_dir>/<Sub_ID>/scripts/recon-all.<timestamp>.log
#
# environment:
#   * FreeSurfer and recon-all must be available in PATH.
#   * <derivatives_dir> will also become $SUBJECTS_DIR for child processes.
#
#***************************************************************************

set -euo pipefail

# -------- defaults --------
RAWDATA_DIR="/path/to/rawdata"        # change as needed
DERIVATIVES_DIR="path/to/derivatives"
THREADS=6                           # can alter based on system hardware
QUEUE_SIZE=2
T1_PATTERN="*_T1w.nii.gz"           # Ending of T1w anatomical image file name (change as needed)

print_usage () {
  grep -E '^#( usage:|   -)' "$0" | sed 's/^# //'
}

# -------- parse CLI --------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r) RAWDATA_DIR="$2"; shift 2 ;;
    -d) DERIVATIVES_DIR="$2"; shift 2 ;;
    -t) THREADS="$2"; shift 2 ;;
    -q) QUEUE_SIZE="$2"; shift 2 ;;
    -h|--help) print_usage; exit 0 ;;
    *) echo "Unknown option $1"; print_usage; exit 1 ;;
  esac
done

# -------- sanity checks ----
[[ -d "$RAWDATA_DIR" ]]        || { echo "Rawdata dir not found: $RAWDATA_DIR"; exit 1; }
mkdir -p "$DERIVATIVES_DIR"
command -v recon-all &>/dev/null || { echo "recon-all not in PATH"; exit 1; }

export SUBJECTS_DIR="$DERIVATIVES_DIR"
export OMP_NUM_THREADS="$THREADS"
 
# -------- helper: run single subject ----
process_subject () {
  local subj_dir="$1"
  local subj_id
  subj_id=$(basename "$subj_dir")

  local t1_file
  t1_file=$(find "$subj_dir" -type f -name "$T1_PATTERN" | head -n 1)

  echo "[$(date '+%F %T')] Subject: $subj_id"
  echo "Looking for T1 file using pattern: $T1_PATTERN"
  echo "Found T1 file: $t1_file"

  if [[ -z "$t1_file" ]]; then
    echo "[$(date '+%F %T')] $subj_id: no T1 NIfTI found, skipping."
    return
  fi

  local subj_out="$DERIVATIVES_DIR/$subj_id"
  local done_flag="$subj_out/scripts/recon-all.done"

  # Check if recon-all already completed
  if [[ -f "$done_flag" ]]; then
    echo "[$(date '+%F %T')] $subj_id already processed, skipping."
    return
  fi

  # If subject directory exists but no .done file, remove it entirely
  if [[ -d "$subj_out" ]]; then
    echo "[$(date '+%F %T')] WARNING: Found incomplete folder for $subj_id. Removing it."
    rm -rf "$subj_out"
  fi

  # Log file (stored *outside* of recon-all's early setup)
  local log_tmp="$DERIVATIVES_DIR/${subj_id}_recon-all.$(date +%Y%m%d_%H%M%S).log"

  echo "[$(date '+%F %T')] Starting $subj_id (threads=$THREADS)" | tee "$log_tmp"
  echo "Running recon-all..." | tee -a "$log_tmp"
  echo "recon-all path: $(which recon-all)" | tee -a "$log_tmp"

  # Let recon-all create everything itself
  recon-all -subject "$subj_id" -i "$t1_file" -sd "$DERIVATIVES_DIR" \
            -all -parallel -openmp "$THREADS" &>> "$log_tmp"

  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    echo "[$(date '+%F %T')] Finished $subj_id successfully." | tee -a "$log_tmp"
    mkdir -p "$subj_out/scripts"
    mv "$log_tmp" "$subj_out/scripts/"
    touch "$done_flag"
  else
    echo "[$(date '+%F %T')] ERROR: recon-all failed for $subj_id (exit code $exit_code)" | tee -a "$log_tmp"
    mv "$log_tmp" "$DERIVATIVES_DIR/${subj_id}_FAILED.log"
  fi
}

# -------- main queue loop ----
running=0
for subj_path in "$RAWDATA_DIR"/sub-*; do         #May need to change sub-* to fit your subject folder naming scheme
  echo "subj_path: $subj_path"
  [[ -d "$subj_path" ]] || continue
  process_subject "$subj_path" &
  ((running+=1))
  if (( running >= QUEUE_SIZE )); then
    wait -n
    ((running-=1))
  fi
done

wait
echo "All recon-all jobs completed. Outputs located in $DERIVATIVES_DIR"
