Om het project te bouwen:
cd miniMD/ref
make openmpi -j AVX=no

Runnen:
./miniMD_openmpi -i in.lj.miniMD

-i is de input, deze hebben de prefix "in" en zijn verschillende scenarios die gedraaid kunnen worden.

Result outputs staan in miniMD/ref/performance-analysis/reports
De makefile gebruikt om analysis te doen staat in miniMD/ref/performance-analysis/make-files

Scalasca:
1. Set up the environment (every new session)
module load GCC/14.1.0 OpenMPI/5.0.3
export PATH=$HOME/opt/scorep-scalasca/bin:$PATH

2. Build the instrumented program

In ref/Makefile.openmpi, the compiler and linker must be prefixed with scorep, and the compilation rule must compile each .cpp file in a single step:

CC   = scorep mpicxx
LINK = scorep mpicxx

.cpp.o:
	$(CC) $(CCFLAGS) -c $*.cpp -o $*.o

Then build:
cd ~/performance-engineering/group-7/project/miniMD/ref
make clean
make openmpi -j AVX=no

3. Get a compute node
salloc -p cn-ib > -N 1 --ntasks=128 --cpus-per-task=1 --exclusive --time=01:00:00

Inside the allocation, load the environment from step 1 again if needed, then set:
export OMP_NUM_THREADS=1
export UCX_TLS=self,sm

4. Profile run (summary)
Scalasca won’t overwrite an existing experiment, so remove the old one first:
rm -rf scorep_miniMD_openmpi_128x1_sum
scalasca -analyze srun ./miniMD_openmpi -s <size> -n <steps>

5. Examine the profile
scalasca -examine -s scorep_miniMD_openmpi_128x1_sum
cat scorep_miniMD_openmpi_128x1_sum/scorep.score