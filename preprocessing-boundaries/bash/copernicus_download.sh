#!/bin/bash

debug=false

# Credentials to connect to the Copernicus Marine Service
username=ftucciarone
password=Pata91vium

# Output directory
output_directory="/home/ftucciar/Med12/preprocessing-cmecs/work"

# DatasetID
dataset_id="cmems_mod_glo_phy-all_my_0.25deg_P1D-m"

# Date initialization (always use one leaginf zero)
startDate=$(date -d "2020-01-01" +%Y-%m-%d)
endDate=$(date -d "2020-01-31" +%Y-%m-%d)

# Variables
variables=("thetao_oras" \
#           "thetao_glor" \
#           "thetao_cglo" \
           "so_oras" \
#           "so_glor" \
#           "so_cglo" \
           "vo_oras" \
#           "vo_glor" \
#           "vo_cglo" \
           "uo_oras" \
#           "uo_glor" \
#           "uo_cglo" \
           "zos_oras" \
#           "zos_glor" \
#           "zos_cglo" \
    )

# Time step
addDays=1

endDate=$(date -d "$endDate + $addDays days" +%Y-%m-%d)

# Time range loop
while [[ "$startDate" != "$endDate" ]]; do

    # Slice the date to get Year, Month, Day
    yy=`echo $startDate | cut -c 1-4`
    mm=`echo $startDate | cut -c 6-7`
    dd=`echo $startDate | cut -c 9-10`

    # Create subfolder for single files
    mkdir -p $output_directory/$yy/$mm

    echo "=============== Date: $yy-$mm-$dd ===================="
    
    command="copernicusmarine subset \
    --username=$username \
    --password=$password \
    --dataset-id $dataset_id \
    $( printf " -v %s " "${variables[@]}" ) \
    --start-datetime \"$startDate\" \
    --end-datetime \"$startDate\" \
    --output-directory $output_directory/$yy/$mm \
    --output-filename cmems_mod_glo_phy_$(date -d "$startDate" +%Y-%m-%d).nc"
    
    echo -e "$command \n============="

    if ! $debug ; then
        eval "$command"
    fi
    

    startDate=$(date -d "$startDate + $addDays days" +%Y-%m-%d)

done

echo "=========== Download completed! ==========="