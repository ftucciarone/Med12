#!/bin/bash

MedDir=/home/ftucciar/newMed12
runDir=/home/ftucciar/newMed12-runs/cfgs/MY_MED

datecommand=date

function dateDiffMonth() {
    local y1=$($datecommand -d "$1" '+%Y') # extract the year from your date1
    local y2=$($datecommand -d "$2" '+%Y') # extract the year from your date2
    local m1=$($datecommand -d "$1" '+%m') # extract the month from your date1
    local m2=$($datecommand -d "$2" '+%m') # extract the month from your date2
    # compute the months difference 12*year diff+ months diff
    # 10# force the shell to interpret the following number in base-10
    echo $(( ($y2 - $y1) * 12 + (10#$m2 - 10#$m1) ))
}

tStep=480 # seconds

# Date initialization
startDate=$($datecommand -d "2020-01-01" +%Y-%m-%d)
endDate=$($datecommand -d "2020-06-01" +%Y-%m-%d)

nMonths=`dateDiffMonth $startDate $endDate`

iStart=0
currentRestart=MED7km_20200101_restart
currentDate=$startDate
for i in $(seq 1 $nMonths);
do

    # Slice the datecommand to get Year, Month, Day
    yy=`echo $currentDate | cut -c 1-4`
    mm=`echo $currentDate | cut -c 6-7`
    dd=`echo $currentDate | cut -c 9-10`

    # Create directories
    mkdir -p $runDir/$yy$mm

    # Count the number of days in the current month
    nDays=$($datecommand -d "$currentDate + 1 month - 1 day" "+%d")

    # Compute the number of integration steps for this month
    iSteps=$(( $nDays*86400/$tStep ))

    # Compute the final step
    iStop=$(( $iStart + iSteps ))


    echo $yy $mm $nDays $iStep

    # Move the template namelist in
    cp namelist_tmp $runDir/$yy$mm/namelist_cfg

    # Update namelist_cfg with correct timestep
    sed -i "s|__timeStep__|${tStep}|g" $runDir/$yy$mm/namelist_cfg || exit 5

    # Update namelist_cfg with correct nn_it000
    sed -i "s|__firstStep__|$((${iStart} + 1))|g" $runDir/$yy$mm/namelist_cfg || exit 5

    # Update namelist_cfg with correct nn_itend
    sed -i "s|__lastStep__|${iStop}|g" $runDir/$yy$mm/namelist_cfg || exit 5

    # Update namelist_cfg with correct cn_ocerst_in
    sed -i "s|__restart_file__|${currentRestart}|g" $runDir/$yy$mm/namelist_cfg || exit 5

    # Update namelist_cfg with correct cn_ocerst_in
    sed -i "s|__restart_dir__|$runDir/$yy$(($mm-1))|g" $runDir/$yy$mm/namelist_cfg || exit 5

    # Update namelist_cfg with correct nn_date0
    sed -i "s|__first_day__|${yy}${mm}01|g" $runDir/$yy$mm/namelist_cfg || exit 5

    # Link static files necessary
    ln -s $MedDir/data-static/dist.coast.nc $runDir/$yy$mm/dist.coast.nc
    ln -s $MedDir/data-static/eddy_diffusivity_2D.nc $runDir/$yy$mm/eddy_diffusivity_2D.nc
    ln -s $MedDir/data-static/eddy_viscosity_2D.nc $runDir/$yy$mm/eddy_viscosity_2D.nc

    # Link folders
    ln -s $MedDir/preprocessing-boundaries/archive/$yy/$mm/ $runDir/$yy$mm/data-boundaries
    ln -s $MedDir/../test_clone/dynamic/                    $runDir/$yy$mm/data-dynamic
    ln -s $MedDir/preprocessing-forcings/archive            $runDir/$yy$mm/data-forcing
    ln -s $MedDir/data-restart/                             $runDir/$yy$mm/data-restart
    ln -s $MedDir/../test_clone/dynamic/                    $runDir/$yy$mm/data-restoring
    ln -s $MedDir/../test_clone/dynamic/                    $runDir/$yy$mm/data-runoff
    ln -s $MedDir/data-static                               $runDir/$yy$mm/data-static

    # Update initial step
    iStart=$iStop

    # Update currentDate
    currentDate=$($datecommand -d "$currentDate + 1 month" "+%Y-%m-%d")

    # Update CurrentRestart
    currentRestart=MED7km_${iStop}_restart.nc

done





exit
