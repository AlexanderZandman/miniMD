Om het project te bouwen:
cd miniMD/ref
make openmpi -j AVX=no

Runnen:
./miniMD_openmpi -i in.lj.miniMD

-i is de input, deze hebben de prefix "in" en zijn verschillende scenarios die gedraaid kunnen worden.

Result outputs staan in miniMD/ref/performance-analysis/reports
De makefile gebruikt om analysis te doen staat in miniMD/ref/performance-analysis/make-files