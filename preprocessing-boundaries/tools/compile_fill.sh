source netCDF.macro
#
# Compiler options and flags: 
#              
#
gFort_flags=" -Ofast -fbounds-check  -Wno-uninitialized -ffree-line-length-512 "
iFort_flags=""

comp_flags=
#$gFort_flags

COMP="$nf_config__fc $comp_flags" 

EXE=m2r_nn.x


cd fill_land

#rm -f *.o *.mod $EXE
str=""
for f in ncdf.F90 master_nn.F90 fill_land.F90 ; do
   (set -x
      $COMP -c -g ${nc_config__fflags} $f $netCDF_Libs|| { echo "Compilation error for $f" ; exit 1 ; }
   )
      str="$str `echo $f | cut -d. -f1`.o"
done

(set -x 
   $COMP $str -o $EXE $netCDF_Libs
)
rm -f *.o *.mod

