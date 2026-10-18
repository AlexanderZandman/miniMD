#!/bin/bash
# cache_stats.sh: single-rank cache, TLB and stall counters for compute_halfneigh
set -euo pipefail

REF=$HOME/miniMD/ref
OUT=$REF/performance-modelling/cache
mkdir -p "$OUT"
cd "$REF"
export OMP_NUM_THREADS=1

PASS_A="l1d_cache_rd,l1d_cache_refill_rd,l2d_cache_rd,l2d_cache_refill_rd,ll_cache_rd,ll_cache_miss_rd"
PASS_B="l1d_tlb_rd,l1d_tlb_refill_rd,dtlb_walk,mem_stall_l1miss,mem_stall_l2miss,inst_retired"

for box in 10 40; do
  for pass in A B; do
    if [[ $pass == A ]]; then EV=$PASS_A; else EV=$PASS_B; fi
    perf stat -x, -e "$EV" -o "$OUT/box${box}_pass${pass}.csv" -- \
      mpirun -np 1 ./miniMD_openmpi -i in.lj.miniMD --half_neigh 1 \
      -nx $box -ny $box -nz $box > "$OUT/box${box}_pass${pass}.out" 2>&1
  done
done

for f in "$OUT"/*.csv; do
  echo "== $(basename "$f") =="
  awk -F, '!/^#/ && NF>=3 {printf "%-22s %s\n", $3, $1}' "$f"
done