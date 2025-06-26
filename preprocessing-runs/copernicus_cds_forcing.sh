#!/bin/bash
source copernicus_cds_params.sh
source tools_date.sh
source tools_misc.sh

# Argument validation check
if [ "$#" -lt 8 ]; then
    echo " "
    echo "Usage: $0 <long_name> <var_name> <out_name> <chr_id> <nts> <YYYY-MM> <nDays> <daymean> "
    echo " "
    echo "Parameters depending on the field processed to be passed                          "
    echo " " 
    echo "  Refer to: https://confluence.ecmwf.int/display/CKB/ERA5%3A+data+documentation   "
    echo " "
    echo " long_name: Variable name in CDS, e.g. '10m_u_component_of_wind'                  "
    echo "  var_name: ShortName, e.g. 'u10m'                                                "
    echo "  out_name: Output name of the variable, e.g. 'u10m'                              "
    echo "    chr_id: paramID, e.g. '167'                                                   "
    echo "       nts: number of time snapshots downloaded                                   "
    echo "   YYYY-MM: Year and Month to process                                             "
    echo "     nDays: Number of days in the month                                           "
    echo " "
    echo "Optional parameters                                                               "
    echo "        -d: dayavg, set to 1 to average over one day                              "
    echo "        -u: unit change, if different from 1. it performs variable/input_value    "
    echo "        -f: fill land, set to 1 to run fill_land.exe                              "
    echo "        -s: skipdownload, if set to 1 it does not download the files from cCDS    "
    echo " "
    echo "  Examples:"
    echo " " 
    echo " 10m_u_component_of_wind 10u u10m 165 24 2020-01 31" 
    echo " 10m_v_component_of_wind 10v v10m 166 24 2020-01 31" 
    exit 1
fi

# Read positional parameters defining the field
long_name=$1
var_name=$2
out_name=$3
chr_id=$4
nts=$5
firstdayYearMonth=$6"-01"
nDays=$7

# Preset for skipdownload, will be overridden by commandline parameters
skipdownload=0
# Read optional parameters
# Careful that s does not require an entry parameter and 
# this is done by removing the colon
shift "$((OPTIND + 6))"
while getopts d:u:f:s flag
do
    case "${flag}" in
        d) dayavg=${OPTARG:-0};;
        u) uchng=${OPTARG:-1};;
        f) filland=${OPTARG:-0};;
        s) skipdownload=1;;
    esac
done
dayavg=${dayavg:-0}
uchng=${uchng:-1.}
filland=${filland:-0}


# Define variable label, useful for intermadiate step
var_label="var$chr_id"

# Slice the datecommand to get Year, Month, Day
yy=$($datecommand -d $firstdayYearMonth +%Y)
mm=$($datecommand -d $firstdayYearMonth +%m)
dd=$($datecommand -d $firstdayYearMonth +%d)

# Set archive subdirectory
arch_sub=${arch_dir}/$yy/$mm

# Print a recap of what we are doing
echo "$tab  " 
echo "$tab         Long name: $long_name"
echo "$tab     Variable name: $var_name"
echo "$tab    Variable label: $var_label"
echo "$tab       Output name: $out_name"
echo "$tab       Variable ID: $chr_id"
echo "$tab         Timesteps: $nts (downloaded with python script)"
echo "$tab  " 
echo "$tab     Daily average: $dayavg (if 1, True)"
echo "$tab      Change units: $uchng (if neq 1. performs var/coef, do not set to 0.)"
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
gribfile=${grib_dir}/${long_name}_${yy}_${mm}.grib
get_script=${run_dir}/${long_name}_${yy}_${mm}.fetch
sed -e "s|_VARIABLE_|$long_name|g" \
      -e "s|_YEAR_|${yy}|g" \
      -e "s|_LIST_MONTHS_|`printf "%02d" $mm`|g" \
      -e "s|_OUTPUT_|$gribfile|g" \
      copernicusCDS_getMonth > $get_script
chmod +x $get_script
echo "$tab Download script prepared:" $get_script
echo "$tab  " 
# Launch the download of the files  
if [ $skipdownload -eq 0 ]; then
   $get_script || exit -1
fi

# Conversion of the .grib file into netcdf
nctempfile=${work_dir}/era5_${yy}_${mm}_${var_label}.nc
echo $cdo -f nc copy $gribfile $nctempfile
$cdo -f nc copy $gribfile $nctempfile || exit -1

# If necessary, average over each day
if [ $dayavg -ne 0 ]; then
   echo "$tab Daymean"
   echo "$tab " 
   echo $cdo daymean $nctempfile $nctempfile || exit 3
   nts=1
fi

# If necessary, apply a scale factor and change the units
if [ "$(echo "$uchng != 1" | bc)" = 1 ] ; then
   echo "$tab Scale and change units"
   echo "$tab " 
   vt=$var_name
   echo $ncap2 -h -s "$vt = float ($vt / $uchng );" $nctempfile -O $nctempfile
   $ncap2 -h -s "$vt = float ($vt / $uchng );" $nctempfile -O $nctempfile || exit -1

   echo $ncks -h -F -d time,1,${ndays} $nctempfile -O $nctempfile
   $ncks -h -F -d time,1,${ndays} $nctempfile -O $nctempfile || exit -2

fi

# Slice the netcdf into months and execute fortran 
ncoutfile=${arch_sub}/ERA5_${out_name}_y${yy}m${mm}.nc

echo $cdo copy $nctempfile $ncoutfile
$cdo copy $nctempfile $ncoutfile || exit -1

# make a link here to the landsea mask because it is statically coded in 
# the fortran code
ln -sf $landseamask lsm.nc
echo  $tab $ncrename -h -v $var_name,$out_name $ncoutfile 
echo "$tab " 
$ncrename -h -v $var_name,$out_name $ncoutfile || exit -2

if [ $filland -eq 1 ]; then
   echo "$tab Fill land"
   echo "$tab " 
   echo $flexe $ncoutfile $out_name $nx $ny $(( $nDays * $nts )) lsm
   $flexe $ncoutfile $out_name $nx $ny $(( $nDays * $nts )) lsm || exit -1
fi

rm $gribfile
rm $nctempfile
unlink lsm.nc
