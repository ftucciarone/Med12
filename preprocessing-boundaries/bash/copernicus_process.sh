#!/bin/bash

debug=false

# Credentials to connect to the Copernicus Marine Service
username=ftucciarone
password=Pata91vium

# Output directory
input_directory="/home/ftucciar/Med12/preprocessing-cmecs/work"
output_directory="/home/ftucciar/Med12/preprocessing-cmecs/archive"

# DatasetID
dataset_id="cmems_mod_glo_phy-all_my_0.25deg_P1D-m"

# Date initialization (always use one leaginf zero)
startDate=$(date -d "2020-01-01" +%Y-%m-%d)
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

    # Create subfolder for single files
    mkdir -p $output_directory/$yy/$mm

    # Move to work directory
    cd /home/ftucciar/Med12/preprocessing-cmecs/work
    #echo "pwd" $pwd
    # Set filename
    filename=$input_directory/$yy/$mm/"cmems_mod_glo_phy_$(date -d "$startDate" +%Y-%m-%d).nc"
    filename_out=$output_directory/$yy/$mm/"cmems_mod_glo_phy_$(date -d "$startDate" +%Y-%m-%d).nc"
    filename_unrot=$output_directory/$yy/$mm/"cmems_mod_glo_phy_unrot_$(date -d "$startDate" +%Y-%m-%d).nc"

    # Link original file inside this folder
    ln -sf $filename input.nc || exit -3

    # Link original file inside this folder
    ln -sf /home/ftucciar/Med12/data-static/mesh_mask.nc mesh_mask.nc || exit -3

    # Link executable inside this folder
    ln -sf $exe m2r_nn.x || exit -3
    ln -sf $exe_rot corr_vect.x || exit -3    

    for idv in `seq 0 4`; do
        #idv=2
        #echo time $exe /home/ftucciar/Med12/preprocessing-cmecs/namelists/namelist_${variables[$idv]}_b ${types[$idv]} || { echo "$exe failed, exiting!" ; exit 2 ; }
        time ./m2r_nn.x /home/ftucciar/Med12/preprocessing-cmecs/namelists/namelist_${variables[$idv]}_b ${types[$idv]} || { echo "$exe failed, exiting!" ; exit 2 ; }
    
        # Move the output to the folder: if it's the first field we create a new file, if its not we append

   	    if [ $idv -eq 0 ]; then
  		    mv output.nc $filename_out || { echo "No output, exiting!" ; exit 3 ; }
  	    else
  		    ncks -h output.nc -A $filename_out || { echo "No output, exiting!" ; exit 3 ; }
  	    fi       
    
    done

    unlink input.nc
    unlink m2r_nn.x
    
    # Use Sosie to rotate the field
    cp $filename_out $filename_unrot

    echo time $exe_rot -m mesh_mask.nc -G U -t time -i $filename_unrot $filename_unrot -v uo_oras vo_oras -o $filename_out $filename_out || exit -5

    unlink corr_vect.x
    unlink mesh_mask.nc

    startDate=$(date -d "$startDate + $addDays days" +%Y-%m-%d)

done

#echo "=========== Download completed! ==========="