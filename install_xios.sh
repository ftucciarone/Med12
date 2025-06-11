# Let's base ourselves in the base directory
source install_params.sh

# install what is needed
sudo apt-get -y update
sudo apt-get install -y openmpi-bin libmpich-dev libopenmpi-dev gcc g++ gfortran subversion libcurl4-openssl-dev wget make m4 git liburi-perl libxml2-dev


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
git clone -b xios-2.5 https://github.com/ftucciarone/XIOS.git xios-2.5
git clone -b arch-local https://github.com/ftucciarone/XIOS.git arch-local
cd xios-2.5
cp ../arch-local/arch-local.* arch/
./make_xios --arch local --job 32

