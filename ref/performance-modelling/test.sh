OUT=~/miniMD/ref/performance-modelling/perf_64rank
cd ~/miniMD/ref

EV=""
for s in 1 3 5 7; do
  for h in $(ls /sys/bus/event_source/devices/ | grep "hisi_sccl${s}_hha"); do
    for e in rd_ddr_64b rd_ddr_128b wr_ddr_128b; do
      EV+="${h}/${e}/,"
    done
  done
done
EV=${EV%,}

OMP_NUM_THREADS=1 perf stat -a -x, -o "$OUT/uncore_v2.csv" -e "$EV" -- \
  mpirun -np 64 --bind-to core ./miniMD_openmpi -i in.lj.miniMD \
  --half_neigh 1 -nx 40 -ny 40 -nz 40 > "$OUT/run_uncore_v2.out" 2>&1