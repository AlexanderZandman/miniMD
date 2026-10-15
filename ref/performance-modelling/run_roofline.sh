#!/bin/bash
# run_roofline.sh: build miniMD_openmpi and run the half-neighbour force kernel
# for the roofline study. Results go to performance-modelling/measurements/.
#
# Usage:
#   ./run_roofline.sh build            # build only
#   ./run_roofline.sh run              # run all cases (build first if needed)
#   ./run_roofline.sh all              # build + run

set -euo pipefail

# ---- Configuration ---------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REF_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"          # the ref/ directory
MEAS_DIR="$SCRIPT_DIR/measurements"
BIN="$REF_DIR/miniMD_openmpi"
INPUT="in.lj.miniMD"
REPS=3                                           # repetitions per case

# Run launcher. Change to "srun -n" if the cluster uses Slurm.
LAUNCH="mpirun -np"
MAKE_TARGET="openmpi"

# Test cases: label, MPI ranks, box size (unit cells per dimension)
# Box 10 is small enough to fit in cache; box 40 (~256k atoms) does not.
CASES=(
  "1rank_small  1  10"
  "1rank_large  1  40"
  "64rank_large 64 40"
)

# ---- Functions -------------------------------------------------------------
build() {
  echo ">>> Building miniMD ($MAKE_TARGET) in $REF_DIR"
  (cd "$REF_DIR" && make "$MAKE_TARGET" -j 8)
  if [[ ! -x "$BIN" ]]; then
    echo "ERROR: $BIN not found after build" >&2
    exit 1
  fi
  echo ">>> Build OK: $BIN"
}

run_cases() {
  if [[ ! -x "$BIN" ]]; then
    echo "ERROR: $BIN missing. Run './run_roofline.sh build' first." >&2
    exit 1
  fi

  mkdir -p "$MEAS_DIR"
  local summary="$MEAS_DIR/summary.csv"
  echo "label,rep,ranks,box,t_total,t_force,t_neigh,t_comm,t_other,performance" > "$summary"

  # Force the single-threaded half-list path (compute_halfneigh, not the threaded one)
  export OMP_NUM_THREADS=1

  cd "$REF_DIR"

  for case in "${CASES[@]}"; do
    read -r label ranks box <<< "$case"

    for rep in $(seq 1 "$REPS"); do
      out="$MEAS_DIR/${label}_rep${rep}.out"
      echo ">>> $label rep $rep: $ranks ranks, box $box"

      $LAUNCH "$ranks" --bind-to core "$BIN" \
        -i "$INPUT" --half_neigh 1 \
        -nx "$box" -ny "$box" -nz "$box" \
        > "$out" 2>&1

      # Check the half-list path was actually used
      if ! grep -q "Half neighborlists: 1" "$out"; then
        echo "WARNING: 'Half neighborlists: 1' not found in $out" >&2
      fi

      # PERF_SUMMARY columns: proc omp nsteps natoms t_total t_force t_neigh t_comm t_other performance ...
      perf_line=$(grep "PERF_SUMMARY" "$out" | tail -n 1 || true)
      if [[ -z "$perf_line" ]]; then
        echo "WARNING: no PERF_SUMMARY line in $out (check for a crash)" >&2
        continue
      fi
      echo "$perf_line" | awk -v l="$label" -v r="$rep" -v n="$ranks" -v b="$box" \
        'BEGIN{OFS=","} {print l, r, n, b, $5, $6, $7, $8, $9, $10}' \
        >> "$summary"
    done
  done

  echo ">>> Done. Summary: $summary"
  column -s, -t "$summary"
}

# ---- Main ------------------------------------------------------------------
case "${1:-all}" in
  build) build ;;
  run)   run_cases ;;
  all)   build; run_cases ;;
  *)     echo "Usage: $0 {build|run|all}"; exit 1 ;;
esac