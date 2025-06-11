# Let's base ourselves in the base directory
ROOT=$HOME

# Echo where we work
echo $ROOT

# compilers
export CC=/usr/bin/mpicc
export CXX=/usr/bin/mpicxx
export FC=/usr/bin/mpif90
export F77=/usr/bin/mpif77

# compiler flags (except for libraries)
export CFLAGS="-O3 -fPIC"
export CXXFLAGS="-O3 -fPIC"
export F90FLAGS="-O3 -fPIC"
export FCFLAGS="-O3 -fPIC"
export FFLAGS="-O3 -fPIC"
export LDFLAGS="-O3 -fPIC "

# FLAGS FOR F90  TEST-EXAMPLES
export FCFLAGS_f90="-O3 -fPIC "

# Create some environment variables
# directories
export WORKDIR=$ROOT/nemo-deps/sources
export INSTDIR=$ROOT/nemo-deps/installs
export XIOSDIR=$ROOT/nemo-deps/XIOS
export NEMODIR=$ROOT
mkdir -p $WORKDIR
mkdir -p $INSTDIR
mkdir -p $XIOSDIR
mkdir -p $NEMODIR


