#!/bin/bash
echo " Operating system type is: "$OSTYPE
source tools_date.sh
source tools_misc.sh


# Parameters
MedDir=/home/ftucciar/finalMed12
runDir=/home/ftucciar/newMed12-runs/cfgs/new_MED
baseDir=/home/ftucciar/newMed12/preprocessing-runs

# NEMO simulation parameters
NEMO_arch=local
NEMO_folder=/home/ftucciar/newMed12-runs
NEMO_config=MY_MED

tStep=480 # seconds

# Date initialization
startDate=$($datecommand -d "2020-01-01" +%Y-%m-%d)
endDate=$($datecommand -d "2021-01-01" +%Y-%m-%d)

# Compute number of months
nMonths=`dateDiffMonth $startDate $endDate`

echo " "
echo "Build MedSea runs"
echo "$tab Initial Date: " $startDate
echo "$tab   Final Date: " $endDate
echo "$tab  "
echo "$tab  NEMO folder: " $NEMO_folder; checkExistence $NEMO_folder "Folder does not exist." 
echo "$tab  NEMO config: " $NEMO_config; checkExistence $NEMO_folder/cfgs/$NEMO_config "Congifuration does not exist." 
echo "$tab  "


iStart=0
currentRestart=MED7km_20200101_restart
currentDate=$startDate

for i in $(seq 1 $nMonths);
do
    
    # Slice the datecommand to get Year, Month, Day
    yy=$($datecommand -d $currentDate +%Y)
    mm=$($datecommand -d $currentDate +%m)
    dd=$($datecommand -d $currentDate +%d)

    # Count the number of days in the current month
    nDays=$($datecommand -d "$currentDate + 1 month - 1 day" "+%d")

    # Compute the number of integration steps for this month
    iSteps=$(( $nDays*86400/$tStep ))

    # Compute the final step
    iStop=$(( $iStart + $iSteps ))

    # Print current month
    echoMonth $currentDate

    # Create Atmospheric Forcing
    echo "$tab Creating Atmospheric Forcing"
    #
    #  Usage: ./copernicus_cds_forcing.sh <long_name> <var_name> <out_name> <chr_id> <nts> <YYYY-MM> <nDays> <daymean> 
    #  
    #  Parameters depending on the field processed to be passed                          
    #   
    #    Refer to: https://confluence.ecmwf.int/display/CKB/ERA5%3A+data+documentation   
    #  
    #   long_name: Variable name in CDS, e.g. '10m_u_component_of_wind'
    #    var_name: ShortName, e.g. 'u10m'
    #    out_name: Output name of the variable, e.g. 'u10m'
    #      chr_id: paramID, e.g. '167'
    #         nts: number of time snapshots downloaded
    #     YYYY-MM: Year and Month to process
    #       nDays: Number of days in the month
    # 
    #  Optional parameters
    #          -d: dayavg, set to 1 to average over one day
    #          -u: unit change, if different from 1. it performs variable/input_value
    #          -f: fill land, set to 1 to run fill_land.exe
    #          -s: skipdownload, if set to 1 it does not download the files from cCDS
    #
    #  Examples:
    #
    #    10m_u_component_of_wind 10u u10m 165 24 2020-01 31
    #    10m_v_component_of_wind 10v v10m 166 24 2020-01 31
    #    
    echo "$tab $tab ./copernicus_cds_forcing.sh -dl true -pr true -fd $currentDate -ld $($datecommand -d "$currentDate + 1 month" "+%Y-%m-%d")"
    ./copernicus_cds_forcing.sh             10m_u_component_of_wind  10u   u10m 165 24 $yy-$mm $nDays -d 0 -u  1.   -f 1 #-s
    ./copernicus_cds_forcing.sh             10m_v_component_of_wind  10v   v10m 166 24 $yy-$mm $nDays -d 0 -u  1.   -f 1 #-s

    ./copernicus_cds_forcing.sh                      2m_temperature   2t    t2m 167 24 $yy-$mm $nDays -d 0 -u  1.   -f 1 #-s

    ./copernicus_cds_forcing.sh             mean_sea_level_pressure  msl    slp 151 24 $yy-$mm $nDays -d 0 -u  1.   -f 1 #-s
 
    ./copernicus_cds_forcing.sh                 total_precipitation   tp precip 228  1 $yy-$mm $nDays -d 1 -u  3.6  -f 1 #-s
    ./copernicus_cds_forcing.sh                            snowfall   sf   snow 144  1 $yy-$mm $nDays -d 1 -u  3.6  -f 1 #-s
    ./copernicus_cds_forcing.sh   surface_solar_radiation_downwards ssrd   swrd 169  1 $yy-$mm $nDays -d 1 -u 3600. -f 1 #-s
    ./copernicus_cds_forcing.sh surface_thermal_radiation_downwards strd   lwrd 175  1 $yy-$mm $nDays -d 1 -u 3600. -f 1 #-s
    ./copernicus_cds_humidity.sh $yy-$mm $nDays -f 1 #-s

    # Create Lateral Boundary Conditions
    echo "$tab Creating Lateral Boundary Conditions"
    #
    # Usage: ./copernicus_mems_boundaries.sh -dl true/false -pr true/false -fd YYYY-MM-DD -ld YYYY-MM-DD -cl
    #  
    #  Parameters to be passed   
    #
    #              -dl (true/false): option to download the files
    #              -pr (true/false): option to process the data
    #              -fd (YYYY-MM-DD): first day to process
    #              -ld (YYYY-MM-DD): last day to process
    #              -cl             : option to clean the data
    #
    #./copernicus_mems_boundaries.sh -dl true -pr true -fd $currentDate -ld $($datecommand -d "$currentDate + 1 month" "+%Y-%m-%d")

    # Create Simulation Folder
    # "$tab Creating Simulation Folder"
    #
    # "Usage: ./build_run_folder.sh <year-month> <base-dir> <nemo-dir> <nemo-conf> <tStep> <restart> <iStart>
    #
    # 
    #   year-month: Year and Month to process, e.g. '2020-01'
    #     base-dir: Base directory of the preprocessing tools
    #     nemo-dir: Base directory of NEMO installation
    #    nemo-conf: NEMO configuration name
    #        tStep: NEMO integration timestep (to set in namelist_cfg)
    #      restart: NEMO restart file name
    #       iStart: starting integration timestep
    #
    #   Example:
    #
    #  ./build_run_folder.sh 2020-01 /home/$USER/nemo-5.0 MY_MED 480 MED7km_20200101_restart 0
    #
    echo $tab $tab ./build_run_folder.sh $yy-$mm $baseDir $NEMO_folder $NEMO_config $tStep $currentRestart $iStart

    # Update initial step
    iStart=$iStop

    # Update currentDate
    currentDate=$($datecommand -d "$currentDate + 1 month" "+%Y-%m-%d")

    # Update CurrentRestart
    currentRestart=MED7km_`printf "%08d" ${iStop}`_restart.nc

    echo " "

done





exit

