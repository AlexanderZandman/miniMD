#!/bin/bash
set -euo pipefail

REF=$HOME/miniMD/ref
REFC=$HOME/miniMD/ref_count
OUT=$REF/performance-modelling/baseline
mkdir -p "$OUT"

export OMP_NUM_THREADS=1
export UCX_TLS=sm,self
MPI_OPTS="--mca pml ob1 --mca btl self,vader"

# 1. Input file with 1000 steps
cp "$REF/in.lj.miniMD" "$OUT/in.lj.baseline"
sed -i -E 's/^[0-9]+ +timesteps/1000 timesteps/' "$OUT/in.lj.baseline"
grep -q "^1000 timesteps" "$OUT/in.lj.baseline" || { echo "ERROR: timesteps line not changed"; exit 1; }

# 2. Event list: all HHA instances on SCCL 1, 3, 5, 7
EV=""
for s in 1 3 5 7; do
  for h in $(ls /sys/bus/event_source/devices/ | grep "^hisi_sccl${s}_hha"); do
    for e in rd_ddr_64b rd_ddr_128b wr_ddr_128b; do
      EV+="${h}/${e}/,"
    done
  done
done
EV=${EV%,}

# 3. Timed run with uncore counters (uninstrumented binary)
cd "$REF"
perf stat -a -x, -o "$OUT/uncore.csv" -e "$EV" -- \
  mpirun -np 128 --bind-to core $MPI_OPTS ./miniMD_openmpi \
  -i "$OUT/in.lj.baseline" --half_neigh 1 -nx 64 -ny 64 -nz 64 \
  > "$OUT/run.out" 2>&1

# 4. Pair count (instrumented binary, same settings)
cd "$REFC"
mpirun -np 128 --bind-to core $MPI_OPTS ./miniMD_openmpi \
  -i "$OUT/in.lj.baseline" --half_neigh 1 -nx 64 -ny 64 -nz 64 \
  > "$OUT/run_count.out" 2>&1
awk '/PAIRCOUNT/ {p += $3} END {print "total pairs", p}' "$OUT/run_count.out" | tee "$OUT/pairs.txt"

# 5. Summaries
echo "--- PERF_SUMMARY (run.out) ---"
grep PERF_SUMMARY "$OUT/run.out" || echo "no PERF_SUMMARY"
echo "UCX lines in run.out: $(grep -c UCX "$OUT/run.out" || true)"
echo "--- uncore totals ---"
awk -F, '!/^#/ && NF>=3 && $1 ~ /^[0-9]/ {split($3,p,"/"); s[p[2]] += $1}
  END {for (t in s) printf "%-14s %.6e\n", t, s[t]}' "$OUT/uncore.csv"
grep "seconds time elapsed" "$OUT/uncore.csv" || true