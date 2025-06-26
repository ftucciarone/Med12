#!/bin/sh
#set -x
#
# Netcdf stuff: to know how to add NetCDF links just run the command "nc-config --all"
#               and then take the following entries:
#               --fflags
#               --flink
#
#  --fflags    -> -I/usr/local/include -I/usr/local/include
#  --flibs     -> -L/usr/local/Cellar/netcdf-fortran/4.6.1/lib -lnetcdff
#
#

nc_config__which=/home/$USER/nemo-dep/installs/bin/nc-config
nf_config__which=/home/$USER/nemo-dep/installs/bin/nf-config
nc_config__which=$( which nc-config ) || { echo "which nc-config failed: check syntax or specify directly the path."; exit ; }
nf_config__which=$( which nf-config ) || { echo "which nf-config failed: check syntax or specify directly the path."; exit ; }

nc_config__fflags=$( $nf_config__which --fflags ) || { echo "nc-config --flags failed: check syntax."; exit ; }
nc_config__flibs=$( $nf_config__which --flibs) || { echo "nc-config --flibs failed:check syntax."; exit ; }
nc_config__fc=$( $nf_config__which --fc) || { echo "nc-config --fc failed:check syntax or specify the compiler."; exit ; }


COMP="$nc_config__fc -Ofast -fbounds-check -Wall -Wno-uninitialized -ffree-line-length-512 -fopenmp"

# Former "compile_fillLand.sh"

stt=""
for f in master_flandr.F90 read_field2dt_fillLand.F90 read_msk.F90 handlerr.F90 write_field2dt_fillLand.F90 fill_land.F90; do
   $COMP -c -g ${nc_config__fflags} $f || exit -1
   str="$str `echo $f | cut -d. -f1`.o"
done

$COMP -g $str ${nc_config__flibs} $ADD -o flandR.x

# Former "compile.new"
str=""
for f in merge.F90 handlerr.F90; do
   $COMP -c -g ${nc_config__fflags} $f || exit -1
   str="$str `echo $f | cut -d. -f1`.o"
done

$COMP -g $str ${nc_config__flibs} $ADD -o merge.x

str=""
for f in merge_prec.F90 handlerr.F90; do
   $COMP -c -g ${nc_config__fflags} $f || exit -1
   str="$str `echo $f | cut -d. -f1`.o"
done

$COMP -g $str ${nc_config__flibs} $ADD -o merge_prec.x

str=""
for f in merge_rad.F90 handlerr.F90; do
   $COMP -c -g ${nc_config__fflags} $f || exit -1
   str="$str `echo $f | cut -d. -f1`.o"
done

$COMP -g $str ${nc_config__flibs} $ADD -o merge_rad.x

str=""
for f in read_field2st.F90 write_field2st.F90 td2qs.F90 handlerr.F90; do
   $COMP -c -g ${nc_config__fflags} $f || exit -1
   str="$str `echo $f | cut -d. -f1`.o"
done

$COMP -g $str ${nc_config__flibs} $ADD -o td2qs.x

# Former "compile.decum"
str=""
for f in decum.F90 handlerr.F90; do
   $COMP -c -g ${nc_config__fflags} $f || exit -1
   str="$str `echo $f | cut -d. -f1`.o"
done

$COMP -g $str ${nc_config__flibs} -o decum.x


str=""
for f in decum2.F90 handlerr.F90; do
   $COMP -c -g ${nc_config__fflags} $f || exit -1
   str="$str `echo $f | cut -d. -f1`.o"
done

$COMP -g $str ${nc_config__flibs} -o decum2.x

rm *.o
