#!/bin/bash

debug=false


# Output directory
input_directory="/home/ftucciar/Med12/preprocessing-cmecs/archive"
output_directory="/home/ftucciar/Med12/preprocessing-cmecs/archive"

# DatasetID
dataset_id="cmems_mod_glo_phy-all_my_0.25deg_P1D-m"

# Date initialization (always use one leaginf zero)
startDate=$(date -d "2020-01-02" +%Y-%m-%d)
endDate=$(date -d "2020-01-31" +%Y-%m-%d)


#--- Executables
exe=/home/ftucciar/Med12/preprocessing-cmecs/tools/fill_land/m2r_nn.x
exe_rot=/home/ftucciar/Med12/preprocessing-cmecs/tools/sosie_new/bin/mycorr_vect.x

# Variables
variables=("so" \
    "thetao" \
    "uo" \
    "vo" \
    "zos" \
    )
types=(3 \
    3 \
    3 \
    3 \
    2 \
    )
# Time step
addDays=1

endDate=$(date -d "$endDate + $addDays days" +%Y-%m-%d)

mkdir -p $output_directory

# Time range loop
while [[ "$startDate" != "$endDate" ]]; do

    # Slice the date to get Year, Month, Day
    yy=`echo $startDate | cut -c 1-4`
    mm=`echo $startDate | cut -c 6-7`
    dd=`echo $startDate | cut -c 9-10`

    # for pref in grepv2_FOAM grepv2_ORAS5 grepv2_CGLORS; do
    for prefix in grepv2_ORAS5; do
         
        file_in=$input_directory/${yy}/${mm}/"cmems_mod_glo_phy_$(date -d "$startDate" +%Y-%m-%d).nc"
    	ncrename -h -v thetao_oras,thetao -v so_oras,so -v uo_oras,uo -v vo_oras,vo -v zos_oras,zos $file_in


        # Move to work directory
        cd /home/ftucciar/Med12/preprocessing-cmecs/work

        # Link the input file in this folder    
        ln -sf $file_in file_in.nc
         
        ln -sf /home/ftucciar/Med12/data-static/coordinates.bdy.nc coord_bdy.nc

        for grid in "T" "U" "V"; do
            file_ou=$output_directory/${prefix}_bdy${grid}_y${yy}m${mm}d${dd}.nc
            /home/ftucciar/Med12/preprocessing-cmecs/tools/create_bdy/bdy_${grid}.exe
            mv file_ou.nc ${file_ou} || exit -1
        done

        echo "End creation file: ${file_ou}"
        rm -f file_in.nc

        unlink coordinates.bdy.nc

	done

    startDate=$(date -d "$startDate + $addDays days" +%Y-%m-%d)

done

#echo "=========== Download completed! ==========="
