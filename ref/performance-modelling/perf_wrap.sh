#!/bin/bash
# Runs under each MPI rank; writes one perf output file per rank.
EVENTS="VFP_SPEC,ASE_SPEC,L1D_CACHE_REFILL,L2D_CACHE_REFILL,LL_CACHE_MISS_RD,BR_MIS_PRED,INST_RETIRED,CPU_CYCLES"
exec perf stat -x, -e "$EVENTS" -o "$OUTDIR/perf_rank${OMPI_COMM_WORLD_RANK}.csv" "$@"
