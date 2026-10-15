#!/bin/bash
OUT=$HOME/miniMD/ref/performance-modelling/perf_64rank
mkdir -p "$OUT"
cd $HOME/miniMD/ref_count     # check this path with: ls ~/miniMD
OMP_NUM_THREADS=1 mpirun -np 64 --bind-to core ./miniMD_openmpi \
  -i in.lj.miniMD --half_neigh 1 -nx 40 -ny 40 -nz 40 > "$OUT/run_count.out" 2>&1

awk '/PAIRCOUNT/ {p += $3} END {print "total pairs", p}' "$OUT/run_count.out"