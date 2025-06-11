# Let's base ourselves in the base directory
source install_params.sh
# This is a very ugly but pratic way to create the arch file for nemo

git clone -b nemo-4.0 https://github.com/ftucciarone/NEMO.git $NEMODIR/nemo-4.0

filename=$NEMODIR/nemo-4.0/arch/arch-local.fcm

#
# Creating architecture file
#
if [ -f $filename ]; then
   echo "File $filename exists. Removing..."
   rm $filename
else
   echo "File $filename does not exist."
fi

printf '# Arch file for container apptainer \n'                                                      >> ${filename}
printf '# romain.caneill@gu.se \n'                                                                   >> ${filename}
printf '#  \n'                                                                                       >> ${filename}
printf '# NCDF_HOME   root directory containing lib and include subdirectories for netcdf4 \n'       >> ${filename}
printf '# HDF5_HOME   root directory containing lib and include subdirectories for HDF5 \n'          >> ${filename}
printf '# XIOS_HOME   root directory containing lib for XIOS \n'                                     >> ${filename}
printf '# OASIS_HOME  root directory containing lib for OASIS \n'                                    >> ${filename}
printf '# \n'                                                                                        >> ${filename}
printf '# NCDF_INC    netcdf4 include file \n'                                                       >> ${filename}
printf '# NCDF_LIB    netcdf4 library \n'                                                            >> ${filename}
printf '# XIOS_INC    xios include file    (taken into accound only if key_iomput is activated) \n'  >> ${filename}
printf '# XIOS_LIB    xios library         (taken into accound only if key_iomput is activated) \n'  >> ${filename}
printf '# OASIS_INC   oasis include file   (taken into accound only if key_oasis3 is activated) \n'  >> ${filename}
printf '# OASIS_LIB   oasis library        (taken into accound only if key_oasis3 is activated) \n'  >> ${filename}
printf '# \n'                                                                                        >> ${filename}
printf '# FC          Fortran compiler command \n'                                                   >> ${filename}
printf '# FCFLAGS     Fortran compiler flags \n'                                                     >> ${filename}
printf '# FFLAGS      Fortran 77 compiler flags \n'                                                  >> ${filename}
printf '# LD          linker \n'                                                                     >> ${filename}
printf '# LDFLAGS     linker flags, e.g. -L<lib dir> if you have libraries \n'                       >> ${filename}
printf '# FPPFLAGS    pre-processing flags \n'                                                       >> ${filename}
printf '# AR          assembler \n'                                                                  >> ${filename}
printf '# ARFLAGS     assembler flags \n'                                                            >> ${filename}
printf '# MK          make \n'                                                                       >> ${filename}
printf '# USER_INC    complete list of include files \n'                                             >> ${filename}
printf '# USER_LIB    complete list of libraries to pass to the linker \n'                           >> ${filename}
printf '# CC          C compiler used to compile conv for AGRIF \n'                                  >> ${filename}
printf '# CFLAGS      compiler flags used with CC \n'                                                >> ${filename}
printf '# \n'                                                                                        >> ${filename}
printf '# Note that: \n'                                                                             >> ${filename}
printf '#  - unix variables '$...' are accepted and will be evaluated before calling fcm. \n'        >> ${filename}
printf '#  - fcm variables are starting with a %% (and not a $) \n'                                  >> ${filename}
printf '# \n'                                                                                        >> ${filename}
printf '%%NCDF_HOME           %s \n' "${INSTDIR}"                                                    >> ${filename}
printf '%%HDF5_HOME           %s \n' "${INSTDIR}"                                                    >> ${filename}
printf '%%XIOS_HOME           %s/xios-2.5 \n' "${XIOSDIR}"                                           >> ${filename}
printf '%%OASIS_HOME          \n'                                                                    >> ${filename}        
printf '  \n'                                                                                        >> ${filename}
printf '%%NCDF_INC            -I%%NCDF_HOME/include  \n'                                             >> ${filename}
printf '%%NCDF_LIB            -L%%NCDF_HOME/lib -lnetcdf -lnetcdff -L%%HDF5_HOME/lib -lhdf5_hl -lhdf5 -lcurl \n'  >> ${filename}
printf '%%XIOS_INC            -I%%XIOS_HOME/inc  \n'                                                 >> ${filename}
printf '%%XIOS_LIB            -L%%XIOS_HOME/lib -lxios -lstdc++ \n'                                  >> ${filename}
printf '%%OASIS_INC            \n'                                                                   >> ${filename}
printf '%%OASIS_LIB            \n'                                                                   >> ${filename}        
printf '  \n'                                                                                        >> ${filename}
printf '%%CPP	              cpp -Dkey_nosignedzero \n'                                             >> ${filename}
printf '%%FC                  mpif90 -c -cpp \n'                                                     >> ${filename}
printf '%%FCFLAGS             -O3 -fdefault-real-8 -ffree-line-length-none -fno-second-underscore -Dgfortran -funroll-all-loops -fcray-pointer -fallow-argument-mismatprintf ch \n'  >> ${filename}
printf '%%FFLAGS              %%FCFLAGS \n'                                                          >> ${filename}
printf '%%LD                  mpif90 \n'                                                             >> ${filename}
printf '%%LDFLAGS             -Wl,-rpath,$INSTDIR/lib \n'                                            >> ${filename}
printf '%%FPPFLAGS            -P -C -traditional \n'                                                 >> ${filename}
printf '%%AR                  ar \n'                                                                 >> ${filename}
printf '%%ARFLAGS             rs \n'                                                                 >> ${filename}
printf '%%MK                  make \n'                                                               >> ${filename}
printf '%%USER_INC            %%XIOS_INC %%OASIS_INC %%NCDF_INC \n'                                  >> ${filename}
printf '%%USER_LIB            %%XIOS_LIB %%OASIS_LIB %%NCDF_LIB \n'                                  >> ${filename}
printf '  \n'                                                                                        >> ${filename}
printf '%%CC                  gcc \n'                                                                >> ${filename}  
printf '%%CFLAGS               \n'                                                                   >> ${filename}




