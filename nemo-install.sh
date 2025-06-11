# Let's base ourselves in the base directory
ROOT=$HOME

# install what is needed
sudo apt-get -y update
sudo apt-get install -y openmpi-bin libmpich-dev libopenmpi-dev gcc g++ gfortran subversion libcurl4-openssl-dev wget make m4 git liburi-perl libxml2-dev

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
mkdir -p $WORKDIR
mkdir -p $INSTDIR
mkdir -p $XIOSDIR




#
# Install ZLib:
#

cd $WORKDIR
LIB_VERSION="zlib-1.3.1"
wget https://www.zlib.net/${LIB_VERSION}.tar.gz
tar xvfz ${LIB_VERSION}.tar.gz
cd $LIB_VERSION
./configure --prefix=$INSTDIR
make -j1
#make check
make install

#
# Install HDF5: https://support.hdfgroup.org/downloads/hdf5/hdf5_1_14_6.html
#

cd $WORKDIR
LIB_VERSION="hdf5_1.14.6"
wget https://github.com/HDFGroup/hdf5/archive/refs/tags/${LIB_VERSION}.tar.gz
tar xvfz ${LIB_VERSION}.tar.gz
cd hdf5-$LIB_VERSION
export HDF5_Make_Ignore=yes
# Configure
./configure --prefix=$INSTDIR \
   	    --enable-fortran  --enable-parallel --enable-hl --enable-shared  \
        --with-zlib=$INSTDIR
# Make and install
make -j1
#make check
make install

# install netcdf-c
cd $WORKDIR
LIB_VERSION="4.9.3"
wget https://github.com/Unidata/netcdf-c/archive/refs/tags/v${LIB_VERSION}.tar.gz
tar xvfz v${LIB_VERSION}.tar.gz
cd netcdf-c-${LIB_VERSION}
export CPPFLAGS="-I$INSTDIR/include -DpgiFortran"
export LDFLAGS="-Wl,-rpath,$INSTDIR/lib -L$INSTDIR/lib -lhdf5_hl -lhdf5"
export LIBS="-lmpi"
./configure --prefix=$INSTDIR --enable-netcdf-4 --enable-shared \
            --enable-parallel-tests
make -j1
#make check
make install

# Install netcdf-fortran
cd $WORKDIR
LIB_VERSION="4.6.2"
wget https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v${LIB_VERSION}.tar.gz
tar xvfz v${LIB_VERSION}.tar.gz
cd netcdf-fortran-${LIB_VERSION}
export LD_LIBRARY_PATH=${NCDIR}/lib:${LD_LIBRARY_PATH}
export CPPFLAGS="-I$INSTDIR/include -DpgiFortran"
export LDFLAGS="-Wl,-rpath,$INSTDIR/lib -L$INSTDIR/lib -lnetcdf -lhdf5_hl -lhdf5 -lz -lcurl"
export LIBS="-lmpi"
./configure --prefix=$INSTDIR \
            --enable-shared --enable-parallel-tests \
            --enable-parallel
make -j1
#make check
make install

cd $XIOSDIR
svn co -r 2481 http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/branchs/xios-2.5 xios-2.5
cd xios-2.5
./make_xios --arch local --job 32

