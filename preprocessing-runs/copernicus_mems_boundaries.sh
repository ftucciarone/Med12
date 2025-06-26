#!/bin/bash
# Source the parameters
source ~/python_env/bin/activate
source copernicus_mems_params.sh
source copernicus_mems_checks.sh
source copernicus_mems_credentials.sh


# Create directories if not already existing
mkdir -p $work_dir
mkdir -p $arch_dir

# Move to work directory. This folder is supposed to be a container of all the 
# operations performed, containing links and byproducts of the operations. It 
# can be deleted or ignored by Git
cd $work_dir
echo " Moving to work directory: "$(pwd)


# If we process the files, we link the main things inside this folder
if $4 ; then

    # Link mesh_mask.nc inside this folder
    if [ -f $mesh_mask ]; then
        ln -sf $mesh_mask mesh_mask.nc
    else
	echo "$mesh_mask not found"
#	exit -3
    fi

    # Link coordinates.bdy.nc inside this folder and rename into coord_bdy.nc
    if [ -f $coord_bdy ]; then
        ln -sf $coord_bdy coord_bdy.nc
    else
	echo "$coord_bdy not found"
#	exit -3
    fi

    # Link nearest-neighbour procedure inside this folder
    if [ -f $exe_nn ]; then
        ln -sf $exe_nn m2r_nn.x 
    else
	echo "$exe_nn not found"
#	exit -3
    fi

    # Link correction vector (from SOSIE) inside this folder
    if [ -f $exe_rot ]; then
        ln -sf $exe_rot corr_vect.x 
    else
	echo "$exe_rot not found"
#	exit -3
    fi

fi


# Date initialization (always use one leaginf zero)
startDate=$($datecommand -d $firstDate +%Y-%m-%d)
endDate=$($datecommand -d $lastDate +%Y-%m-%d)


# Time step
addDays=1

# Time range loop
while [[ "$startDate" != "$endDate" ]]; do

    # Slice the date to get Year, Month, Day
    yy=`echo $startDate | cut -c 1-4`
    mm=`echo $startDate | cut -c 6-7`
    dd=`echo $startDate | cut -c 9-10`

    # Locate data folder
    dataglo_dir=data_global/$yy/$mm
    dataloc_dir=data_local/$yy/$mm
    archive_dir=../$arch_dir/$yy/$mm


    # Create filenames
    filename_glo="cmems_mod_glo_phy${dataset_type}_$($datecommand -d "$startDate" +%Y-%m-%d).nc"

    # Create subfolder for single files
    mkdir -p $dataglo_dir
    mkdir -p $dataloc_dir
    mkdir -p $archive_dir

    # Create download command 
    command="copernicusmarine subset \
    --username=$username \
    --password=$password \
    --dataset-id $dataset_id \
    $( printf " -v %s$dataset_type " "${variables[@]}" ) \
    --start-datetime \"$startDate\" \
    --end-datetime \"$startDate\" \
    --output-directory $dataglo_dir \
    --output-filename $filename_glo"
    
    # ###############################################################################################################
    # 
    # Download section 
    #
    # ###############################################################################################################
    # if -dl true then download the arguments
    if $2 ; then
        echo " -dl true: downloading the files"
	    echo -e "=============== Date: $yy-$mm-$dd ==================== \n $command \n============="
        if ! $debug ; then
            eval "$command"
            echo "=========== Download completed! ==========="
        fi
    fi

    # ###############################################################################################################
    # 
    # Processing section 
    #
    # ###############################################################################################################
    # if -pr true then process the raw data
    if $4 ; then

        # Link original file inside this folder
        if [ -f $dataglo_dir/$filename_glo ]; then
            ln -sf $dataglo_dir/$filename_glo input.nc
        else
	        echo "$dataglo_dir/$filename_glo not found"
	        exit -3
        fi
    
        filename_loc=$dataloc_dir/"cmems_mod_glo_phy_$($datecommand -d "$startDate" +%Y-%m-%d).nc"
        filename_unrot=$dataloc_dir/"cmems_mod_glo_phy_unrot_$($datecommand -d "$startDate" +%Y-%m-%d).nc"

	    # Process each variable in the $variables array
        for idv in `seq 0 4`; do
            # Perform Nearest-Neighbour interpolation from global grid to taget grid. Original Script by Andrea Storto.
            time ./m2r_nn.x $nams_dir/namelist_${variables[$idv]}_b ${dimensions[$idv]} || \
		{ echo "$exe_nn failed, exiting!" ; exit 2 ; }
            # Move the output to the folder: if it's the first field we create a new file, if its not we append
   	        if [ $idv -eq 0 ]; then
                mv output.nc $filename_loc || { echo "No output, exiting!" ; exit 3 ; }
  	        else
  		        ncks -h output.nc -A $filename_loc || { echo "No output, exiting!" ; exit 3 ; }
  	        fi
	    done

        # Make a copy in case everything goes south
        cp $filename_loc $filename_unrot

        # Use Sosie to rotate the field
        echo time $exe_rot -m mesh_mask.nc \
	        -G U \
            -t time  \
            -i $filename_unrot $filename_unrot  \
            -v uo$dataset_type vo$dataset_type  \
            -o $filename_out $filename_out || exit -5

        # Rename the variables inside the local file 
        rename_command=$(for ((i=0; i< "${#variables[@]}"; i++)) do printf " -v %s$dataset_type,%s" "${variables[$i]}" "${variables[$i]}"; done)
    	ncrename -h $rename_command $filename_loc

        # Link the input file in this folder    
        ln -sf $filename_loc file_in.nc
         
        # Create boundary
        for grid in "T" "U" "V"; do
            file_ou=$archive_dir/${prefix}_bdy${grid}_y${yy}m${mm}d${dd}.nc
            $exe_bdy/bdy_${grid}.exe
            mv file_ou.nc ${file_ou} || exit -1
        done

	    # Finish statement, unlinking and cleanup of work files (to be made optional)
        echo "End creation file: ${file_ou}"
        echo "Unlinking file_in.nc"
        echo "Cleaning $dataglo_dir/$filename_glo"
        echo "Cleaning $filename_loc"
        echo "Cleaning $filename_unrot"
        unlink file_in.nc
        rm $dataglo_dir/$filename_glo
        rm $filename_loc
        rm $filename_unrot

    fi

    # Update the startdate and go on
    startDate=$($datecommand -d "$startDate + $addDays days" +%Y-%m-%d)

done
    
# Cleanup
unlink input.nc
unlink m2r_nn.x
unlink corr_vect.x
unlink mesh_mask.nc
unlink coord_bdy.nc
