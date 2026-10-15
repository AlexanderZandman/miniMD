import csv
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

ROOFS = {
    'core': dict(title='Single core (1 rank)', ps=5.2, pv=20.8, bw=15.17,
                 note='1-thread STREAM Triad, node 0',
                 fname='roofline_single_core.png'),
    'socket1': dict(title='64 ranks (STREAM, nodes 0-1)', ps=332.8, pv=1331.2, bw=113.6,
                    note='64-thread STREAM Triad; point lies on roof by construction',
                    fname='roofline_64ranks.png'),
    'node2': dict(title='Baseline, 128 ranks (1 node)', ps=665.6, pv=2662.4, bw=253.4,
                  note='128-thread STREAM Triad',
                  fname='roofline_baseline_128ranks.png'),
}

COLORS  = {'1rank_small': 'C0', '1rank_large': 'C1',
           '64rank_large': 'C2', 'baseline_128rank': 'C3'}
OFFSETS = {'1rank_small': (5, 8), '1rank_large': (5, -12)}

with open('measurements/roofline_points.csv') as fh:
    rows = list(csv.DictReader(fh))

ai = np.logspace(-2, 1.5, 400)

for key, r in ROOFS.items():
    fig, ax = plt.subplots(figsize=(6, 5))
    ax.loglog(ai, np.minimum(r['ps'], r['bw'] * ai), 'k-', label='Scalar DP roof')
    ax.loglog(ai, np.minimum(r['pv'], r['bw'] * ai), 'k--', label='Vector DP roof')
    ax.set_title(r['title'])
    ax.set_xlabel('Arithmetic intensity (FLOP/byte)')
    ax.set_ylabel('Performance (GFLOP/s)')
    ax.grid(True, which='both', alpha=0.3)

    for row in rows:
        if row['roofs'] != key:
            continue
        lo, hi = float(row['AI_low']), float(row['AI_high'])
        y = float(row['gflops'])
        style = '-' if row['source'].startswith('lower bound') else ':'
        ax.plot([lo, hi], [y, y], style, marker='o', lw=3,
                color=COLORS[row['label']], label=row['label'])
        ax.annotate(row['label'], (hi, y), textcoords='offset points',
                    xytext=OFFSETS.get(row['label'], (5, 5)),
                    color=COLORS[row['label']])

    extra = [Line2D([0], [0], ls=':', color='gray', label='AI analytical only'),
             Line2D([0], [0], ls='-', color='gray', label='AI bounded by data')]
    h, l = ax.get_legend_handles_labels()
    ax.legend(handles=h + extra, loc='upper left', fontsize=8)
    ax.text(0.02, 0.02, r['note'], transform=ax.transAxes, fontsize=7, color='gray')

    fig.tight_layout()
    fig.savefig(f"plots/{r['fname']}", dpi=200, bbox_inches='tight')
    plt.close(fig)
    print(f"saved plots/{r['fname']}")