import csv
import statistics
from collections import defaultdict
import matplotlib.pyplot as plt

CSV_IN  = 'measurements/scaling_runs.csv'   # one row per run (see format below)
PNG_OUT = 'plots/scaling_ranks.png'
TABLE   = 'measurements/scaling_summary.csv'
FLOP    = 2.06e10   # FLOP for 256k atoms, 100 steps (29 x pairs)

# Read raw runs and group by rank count
runs = defaultdict(list)
with open(CSV_IN) as fh:
    for row in csv.DictReader(fh):
        runs[int(row['ranks'])].append(float(row['t_force']))

ranks = sorted(runs)
median = {n: statistics.median(runs[n]) for n in ranks}
t1 = median[ranks[0]]
ideal_t = [t1 / n for n in ranks]
speedup = [t1 / median[n] for n in ranks]
eff     = [100 * s / n for s, n in zip(speedup, ranks)]
gflops  = [FLOP / median[n] / 1e9 for n in ranks]

# Summary table, same values as the report
with open(TABLE, 'w', newline='') as fh:
    w = csv.writer(fh)
    w.writerow(['ranks', 't_force_median_s', 'speedup', 'efficiency_pct', 'gflops', 'n_runs'])
    for n, s, e, g in zip(ranks, speedup, eff, gflops):
        w.writerow([n, f'{median[n]:.4f}', f'{s:.2f}', f'{e:.1f}', f'{g:.2f}', len(runs[n])])

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11, 4.5))

# Panel 1: time-to-solution, log-log, ideal as dashed line
ax1.loglog(ranks, [median[n] for n in ranks], 'o-', label='measured (median)')
ax1.loglog(ranks, ideal_t, 'k--', label='ideal scaling')
ax1.set_xlabel('MPI ranks (one core each)')
ax1.set_ylabel('force time $t_{force}$ (s)')
ax1.set_xticks(ranks)
ax1.set_xticklabels([str(n) for n in ranks])
ax1.grid(True, which='both', alpha=0.3)
ax1.legend()
ax1.set_title('Strong scaling, 256k atoms')

# Panel 2: parallel efficiency
ax2.semilogx(ranks, eff, 'o-', color='C2')
ax2.axhline(100, color='k', ls='--', lw=1)
ax2.set_xlabel('MPI ranks')
ax2.set_ylabel('parallel efficiency (%)')
ax2.set_xticks(ranks)
ax2.set_xticklabels([str(n) for n in ranks])
ax2.set_ylim(80, 110)
ax2.grid(True, alpha=0.3)
ax2.set_title('Parallel efficiency')

fig.tight_layout()
fig.savefig(PNG_OUT, dpi=200, bbox_inches='tight')
print(f'saved {PNG_OUT} and {TABLE}')