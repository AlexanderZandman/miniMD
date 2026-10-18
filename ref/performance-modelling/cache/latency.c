#include <stdio.h>
#include <stdlib.h>
#include <time.h>

/* Pointer chase over a random cycle of cache lines.
   Usage: ./latency <bytes> <loads> */
static double now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1e9 + t.tv_nsec;
}

int main(int argc, char **argv) {
    size_t bytes = strtoull(argv[1], NULL, 10);
    long loads   = atol(argv[2]);
    size_t n = bytes / 64;                 /* one pointer per 64-byte line */
    size_t *mem = aligned_alloc(64, n * 64);
    size_t *order = malloc(n * sizeof(size_t));

    for (size_t i = 0; i < n; i++) order[i] = i;     /* random single cycle */
    srand48(12345);
    for (size_t i = n - 1; i > 0; i--) {
        size_t j = (size_t)(lrand48() % (i + 1));
        size_t t = order[i]; order[i] = order[j]; order[j] = t;
    }
    for (size_t k = 0; k < n; k++)
        mem[order[k] * 8] = order[(k + 1) % n] * 8;  /* index in size_t units */

    size_t idx = 0;
    for (long k = 0; k < n; k++) idx = mem[idx];    /* warm-up pass */

    double t0 = now_ns();
    for (long k = 0; k < loads; k++) idx = mem[idx];
    double t1 = now_ns();

    printf("%zu bytes  %.2f ns/load  (idx=%zu)\n",
           bytes, (t1 - t0) / loads, idx);       /* idx prevents dead-code removal */
    return 0;
}