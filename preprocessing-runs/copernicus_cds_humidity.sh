#!/bin/bash
source copernicus_cds_params.sh
source tools_date.sh
source tools_misc.sh

# 
long_name_msl=mean_sea_level_pressure
var_name_msl=msl
chr_id_msl=134
var_label_msl="var$chr_id_msl"
# 
long_name_dpt=2m_dewpoint_temperature
var_name_dpt=2d
chr_id_dpt=168
var_label_dpt="var$chr_id_dpt"

#
out_name=qs
nts=24
# Preset for skipdownload, will be overridden by commandline parameters
skipdownload=0

# Get Command Line Arguments
firstdayYearMonth=$1"-01"
nDays=$2
# Read optional parameters
# Careful that s does not require an entry parameter and 
# this is done by removing the colon
shift $((OPTIND + 1))
while getopts f:s flag
do
    case "${flag}" in
        f) filland=${OPTARG:-0};;
        s) skipdownload=1;;
    esac
done
filland=${filland:-0}

# Slice the datecommand to get Year, Month, Day
yy=$($datecommand -d $firstdayYearMonth +%Y)
mm=$($datecommand -d $firstdayYearMonth +%m)
dd=$($datecommand -d $firstdayYearMonth +%d)

# Set archive subdirectory
arch_sub=${arch_dir}/$yy/$mm

# Print a recap of what we are doing

echo "$tab Mean sea level pressure " 
echo "$tab  " 
echo "$tab         Long name: $long_name_msl"
echo "$tab     Variable name: $var_name_msl"
echo "$tab       Variable ID: $chr_id_msl"
echo "$tab " 
echo "$tab 2 metres dewpoint temperature " 
echo "$tab  " 
echo "$tab         Long name: $long_name_dpt"
echo "$tab     Variable name: $var_name_dpt"
echo "$tab       Variable ID: $chr_id_dpt"
echo "$tab  " 
echo "$tab         Fill Land: $filland (if 1, execute fortran code )"
echo "$tab  " 
echo "$tab    Grib directory: ${grib_dir}"
echo "$tab    Work directory: ${work_dir}"
echo "$tab     Run directory: ${run_dir}"
echo "$tab Archive directory: ${arch_sub}"
echo "$tab  " 

# Create directories if needed
mkdir -p ${grib_dir}
mkdir -p ${work_dir}
mkdir -p ${run_dir}
mkdir -p ${arch_sub}


# Now prepare download script based on python API   
gribfile_msl=${grib_dir}/${long_name_msl}_${yy}.grib
get_script_msl=${run_dir}/${long_name_msl}_${yy}.fetch
sed -e "s|_VARIABLE_|$long_name_msl|g" \
      -e "s|_YEAR_|${yy}|g" \
      -e "s|_LIST_MONTHS_|`printf "%02d" $mm`|g" \
      -e "s|_OUTPUT_|$gribfile_msl|g" \
      copernicusCDS_getMonth > $get_script_msl
chmod +x $get_script_msl
echo "Download script prepared: " $get_script_msl
echo "$tab  " 
# Launch the download of the files  
if [ $skipdownload -eq 0 ]; then
   $get_script_msl || exit -1
fi
# Convert grib file to NetCDF file
nctempfile_msl=${work_dir}/era5_${yy}_${mm}_${var_label_msl}.nc
echo $cdo -f nc copy $gribfile_msl $nctempfile_msl
echo "$tab  " 
$cdo -f nc copy $gribfile_msl $nctempfile_msl

# Now prepare download script based on python API   
gribfile_dpt=${grib_dir}/${long_name_dpt}_${yy}_${mm}.grib
get_script_dpt=${run_dir}/${long_name_dpt}_${yy}_${mm}.fetch
sed -e "s|_VARIABLE_|$long_name_dpt|g" \
      -e "s|_YEAR_|${yy}|g" \
      -e "s|_LIST_MONTHS_|`printf "%02d" $mm`|g" \
      -e "s|_OUTPUT_|$gribfile_dpt|g" \
      copernicusCDS_getMonth > $get_script_dpt
chmod +x $get_script_dpt
echo "Download script prepared: " $get_script_dpt
echo "$tab  " 
# Launch the download of the files  
if [ $skipdownload -eq 0 ]; then
   $get_script_dpt || exit -1
fi
# Convert grib file to NetCDF file
nctempfile_dpt=${work_dir}/era5_${yy}_${mm}_${var_label_dpt}.nc
echo $cdo -f nc copy $gribfile_dpt $nctempfile_dpt
echo "$tab  " 
$cdo -f nc copy $gribfile_dpt $nctempfile_dpt

# Compute specific humidity
nctempfile_qs=${work_dir}/era5_${yy}_${mm}_qs.nc

# First use dpt to create a target file
echo $ncks -h -d time,0,0 $nctempfile_dpt -O $nctempfile_qs
$ncks -h -d time,0,0 $nctempfile_dpt -O $nctempfile_qs

# Then rename the variable inside to the specific humidity name
echo $ncrename -h -v $var_name_dpt,$out_name $nctempfile_qs
$ncrename -h -v $var_name_dpt,$out_name $nctempfile_qs

# Compute the specific humidity with external fortran code
echo $qs_exe $nctempfile_dpt $var_name_dpt $nctempfile_msl $var_name_msl $nctempfile_qs $out_name $nx $ny $yy f f $nDays 24 
$qs_exe $nctempfile_dpt $var_name_dpt $nctempfile_msl $var_name_msl $nctempfile_qs $out_name $nx $ny $yy f f $nDays 24 || exit -3

# make a link here to the landsea mask because it is statically coded in 
# the fortran code
ln -sf $landseamask lsm.nc
   
   
# Set up the provisionary output file (mind the CAPS)		
fou=${arch_sub}/ERA5_${out_name}_y${yy}m${mm}.nc
ist=1
ien=$(( $nDays * $nts ))

echo $ncks -h -F -d time,${ist},${ien} $nctempfile_qs $fou
ncks -h -F -d time,${ist},${ien} $nctempfile_qs $fou || exit -1

echo $ncrename -h -v $out_name,q2m $fou 
$ncrename -h -v $out_name,q2m $fou || exit -2

if [ $filland -eq 1 ]; then
      echo "$tab Fill land"
      echo "$tab " 
      echo $flexe $fou q2m $nx $ny $(( $nDays * $nts )) lsm
      $flexe $fou q2m $nx $ny $(( $nDays * $nts )) lsm || exit -1
fi


# Remove Grib files
rm $gribfile_dpt 
rm $gribfile_msl

# Remove temporary NetCDF files
rm $nctempfile_dpt 
rm $nctempfile_msl

unlink lsm.nc