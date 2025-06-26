#!/bin/bash
source tools_date.sh
source tools_misc.sh

# Argument validation check
if [ "$#" -lt 7 ]; then
    echo " "
    echo "Usage: $0 <year-month> <base-dir> <nemo-dir> <nemo-conf> <tStep> <restart> <iStart> "
    echo " "
    echo " "
    echo "  year-month: Year and Month to process, e.g. '2020-01'                             "
    echo "    base-dir: Base directory of the preprocessing tools                             "
    echo "    nemo-dir: Base directory of NEMO installation                                   "
    echo "   nemo-conf: NEMO configuration name                                               "
    echo "       tStep: NEMO integration timestep (to set in namelist_cfg)                    "
    echo "     restart: NEMO restart file name                                                "
    echo "      iStart: starting integration timestep                                         "
    echo " "
    echo "  Examples:"
    echo " " 
    echo " $0 2020-01 /home/$USER/nemo-5.0 MY_MED 480 MED7km_20200101_restart 0                            " 
    echo " "
    exit 1
fi

baseDir=$2
nemoDir=$3
confDir=$3/cfgs/$4
tStep=$5
restart=$6
iStart=$7

# Date initialization
startDate=$($datecommand -d "$1-01" "+%Y-%m-%d")
endDate=$($datecommand -d "$1-01 + 1 month" "+%Y-%m-%d")

currentDate=$startDate
    
# Slice the datecommand to get Year, Month, Day
yy=$($datecommand -d $currentDate +%Y)
mm=$($datecommand -d $currentDate +%m)
dd=$($datecommand -d $currentDate +%d)

# Create directories
mkdir -p $confDir/$yy$mm

# Count the number of days in the current month
nDays=$($datecommand -d "$currentDate + 1 month - 1 day" "+%d")

# Compute the number of integration steps for this month
iSteps=$(( $nDays*86400/$tStep ))

# Compute the final step
iStop=$(( $iStart + iSteps ))

# Move the template namelist in
cp namelist_tmp $confDir/$yy$mm/namelist_cfg 

# Update namelist_cfg with correct timestep
sed -i "s|__timeStep__|${tStep}|g" $confDir/$yy$mm/namelist_cfg || exit 5

# Update namelist_cfg with correct nn_it000
sed -i "s|__firstStep__|$((${iStart} + 1))|g" $confDir/$yy$mm/namelist_cfg || exit 5

# Update namelist_cfg with correct nn_itend
sed -i "s|__lastStep__|${iStop}|g" $confDir/$yy$mm/namelist_cfg || exit 5

# Update namelist_cfg with correct cn_ocerst_in
sed -i "s|__restart_file__|${restart}|g" $confDir/$yy$mm/namelist_cfg || exit 5

# Update namelist_cfg with correct cn_ocerst_in
if [ $i == 1 ]; then
  sed -i "s|__restart_dir__|data-restart/|g" $confDir/$yy$mm/namelist_cfg || exit 5

else
  sed -i "s|__restart_dir__|$confDir/$($datecommand -d "$currentDate - 1 month" "+%Y%m")|g" $confDir/$yy$mm/namelist_cfg || exit 5
fi

# Update namelist_cfg with correct nn_date0
sed -i "s|__first_day__|${yy}${mm}01|g" $confDir/$yy$mm/namelist_cfg || exit 5

# Link namelist_ref from EXP00
ln -s $confDir/EXP00/namelist_ref $confDir/$yy$mm/

# Link .xml files
ln -s $confDir/EXP00/*.xml $confDir/$yy$mm/

# Link executable
ln -s $confDir/BLD/bin/nemo.exe $confDir/$yy$mm/

# Link static files necessary
ln -s $baseDir/data-static/dist.coast.nc $confDir/$yy$mm/dist.coast.nc
ln -s $baseDir/data-static/eddy_diffusivity_2D.nc $confDir/$yy$mm/eddy_diffusivity_2D.nc
ln -s $baseDir/data-static/eddy_viscosity_2D.nc $confDir/$yy$mm/eddy_viscosity_2D.nc

# Link folders
ln -s $baseDir/preprocessing-boundaries/archive/$yy/$mm/ $confDir/$yy$mm/data-boundaries
ln -s $baseDir/../test_clone/dynamic/                    $confDir/$yy$mm/data-dynamic
ln -s $baseDir/preprocessing-forcings/archive            $confDir/$yy$mm/data-forcing
ln -s $baseDir/data-restart/                             $confDir/$yy$mm/data-restart
ln -s $baseDir/../test_clone/dynamic/                    $confDir/$yy$mm/data-restoring
ln -s $baseDir/../test_clone/dynamic/                    $confDir/$yy$mm/data-runoff
ln -s $baseDir/data-static                               $confDir/$yy$mm/data-static
