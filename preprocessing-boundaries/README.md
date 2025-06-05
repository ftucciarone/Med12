## Preprocessing boundary conditions for the Med12 configuration
To download the data from the [Copernicus Marine Service](https://marine.copernicus.eu) and process it to create boundary files, the main scrpt is `copernicus_get-and-process.sh`. It can be invoked without arguments to show its usage. The list of arguments is:
```shell
Usage: ./copernicus_get-and-process.sh -dl true/false -pr true/false -fd YYYY-MM-DD -ld YYYY-MM-DD
      where
             -dl (true/false): option to download the files
             -pr (true/false): option to process the data
             -fd (YYYY-MM-DD): first day to process
             -ld (YYYY-MM-DD): last day to process
```
An example of usage would be
```shell
Usage: ./copernicus_get-and-process.sh -dl true -pr false -fd 2020-01-01 -ld 2020-01-31
```
to download the data from January 1st to January 31st 2020, without processing them, or
```shell
Usage: ./copernicus_get-and-process.sh -dl false -pr true -fd 2020-01-01 -ld 2020-01-31
```
to process data that has already been downloaded, or
```shell
Usage: ./copernicus_get-and-process.sh -dl true -pr true -fd 2020-01-01 -ld 2020-01-31
```
to download and process the data. For the script to run smoothly, one has to set the following parameters in two different files:
##### `Copernicus_credentials.sh`
In the file `copernicus_credentials.sh` we store the credentials to log in the [Copernicus Marine Service](https://marine.copernicus.eu). Once registration is completed and a username and password are attributed, they can be stored in this file (which by default is not updated by Git through the instruction `git update-index --assume-unchanged preprocessing-boundaries/copernicus_credentials.sh`), that is sourced by the processing files.
```shell
# ###############################################################################
# 
# Parameters:
#
#          username        : username to access the copernicus website
#          password        : password to access the copernicus website
#
# ###############################################################################

# Credentials to connect to the Copernicus Marine Service
username=***********
password=**********
``` 
#### `Copernicus_params.sh`
This file contains the main variables needed to run the download and process script. In particular we have:
* `firstDate` and `lastDate` are preset values that should be overridden via command line. If not, we download and process only one day (01/01/2020). Feel free to modify these parameters to bypass command line arguments.
* `dataset_id` is the reference of the Copernicus Marine dataset. We have chosen an [Ocean Reanalysis Dataset](https://data.marine.copernicus.eu/product/GLOBAL_MULTIYEAR_PHY_001_030) (and included the [supporting documentation](CMEMS-GLO-QUID-001-030.pdf)) as we need three dimensional ocean fields for the lateral boundary conditions.
* `dataset_type` is a string that might be useful if multiple products are contained in the same file and variables inside are differentiated (e.g. `thetao_oras` vs `thetao_glorys`). In this specific case, only `oras` variables are accounted.
* `data_filename` is the prefix of the downloaded data.
* `prefix` is a prefix to be given to the finished file.
* `variables` and `types` are two lists of variabels and dimension, in 1-1 relation, that include the name of the variable (without type) and its dimension. The script will automatically process all the variables listed.
* `work` is a scratch directory that is created when launching the program, then the program will `cd` inside and link all the necessary programs inside said directory. Copies of the data are also stored inside work. At last, when the final product is finished, it is moved outside of `work`. This directory will be very heavy.
* `archive` is the final destination fo the processed fields. 
```shell
# ###############################################################################
# 
# Parameters:
#
#    work_directory, (name): folder that is created and will contain all the
#                            temporary files. Deleting this folder should not
#                            cause any harm (after completion)
#    arch_directory, (name): this folder is the archive of the processed data
#            exe_nn, (exec): complete location of the nearest-neighbour executable
#           exe_rot, (exec): complete location of the rotation executable (SOSIE)
#           exe_bdy, (path): path (without executable) of the create_bdy executables
#          username        : username to access the copernicus website
#          password        : password to access the copernicus website
#  output_directory, (path):
#        dataset_id        : copernicus product id, consult the website
#      dataset_type        : either "_oras" or "_glorys", always with underscore
#      datafilename        : filename to give/read 
#        variables         : list of variables to process, do not include suffixes
#
#
# ###############################################################################

# Date initialization 
firstDate="2020-01-01"
lastDate="2020-01-01"

# DatasetID
dataset_id="cmems_mod_glo_phy-all_my_0.25deg_P1D-m"
dataset_type="_oras"
# Filename
datafilename=cmems_mod_glo_phy 

# Output boundary filename
prefix=grepv2_ORAS5

# Variables
variables=("thetao" "so" "vo" "uo" "zos" )
types=(3 3 3 3 2 )

# Set directories
work_directory="work"
arch_directory="archive"

# Fortran executables
exe_nn=../tools/fill_land/m2r_nn.x
exe_rot=../tools/sosie_new/bin/mycorr_vect.x
exe_bdy=../tools/create_bdy

# Debug flag (if true, only prints on screen the commands)
debug=false
```

## Pipeline overview
This section roughly explains the operations performed in the `copernicus_get-and-process.sh` script. 
#### Preparing the envirnoment
The first part of the script sources the relevant variables and a python environment. This latter is needed for the Copernicus command line to work. See [the Command Line Interface documentation](https://help.marine.copernicus.eu/en/articles/7972861-copernicus-marine-toolbox-cli-subset) for more information.

After sourcing, the `work` and `archive` directories are made (if not already existing, with the `mkdir -p` command), and the location is changed to `work`. Inside `work`, all the relevant executables are linked, along with the important static data (such as `mesh_mask.nc` and `coordinates.bdy.nc`, the latter being renamed due to a hardcoded name in the Fortran source). `startDate` and `endDate` are set, based on command line arguments or preset values.
```shell
# Source the parameters
source ~/python_env/bin/activate
source copernicus_params.sh
source copernicus_checks.sh
source copernicus_credentials.sh

# Create directories if not already existing
mkdir -p $work_directory
mkdir -p $arch_directory

# Move to work directory. This folder is supposed to be a container of all the 
# operations performed, containing links and byproducts of the operations. It 
# can be deleted or ignored by Git
cd $work_directory
echo " Moving to work directory: "$(pwd)


# If we process the files, we link the main things inside this folder
if $4 ; then

    # Link mesh_mask.nc inside this folder
    if [ -f ../../data-static/mesh_mask.nc ]; then
        ln -sf ../../data-static/mesh_mask.nc mesh_mask.nc
    else
	echo "../../data-static/mesh_mask.nc not found"
#	exit -3
    fi

    # Link coordinates.bdy.nc inside this folder and rename into coord_bdy.nc
    if [ -f ../../data-static/coordinates.bdy.nc ]; then
        ln -sf ../../data-static/coordinates.bdy.nc coord_bdy.nc
    else
	echo "../../data-static/coordinates.bdy.nc not found"
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

# Create ending date (the while construct is going to exit at endDate without processing it)
endDate=$($datecommand -d "$endDate + $addDays days" +%Y-%m-%d)
```

#### Time looping and folder organization
The program will run day by day from `startDate` to `endDate`. For each new year and new month it will create a new folder to store the scratch data and the final product. It also initialise a `dataloc_dir` where the interesting subset of the original data (in this case the Mediterranean sea) is retained, cropping all the rest (compare with the data in `dataglo_dir`, which is still global).
```shell
# Time range loop
while [[ "$startDate" != "$endDate" ]]; do

    # Slice the date to get Year, Month, Day
    yy=`echo $startDate | cut -c 1-4`
    mm=`echo $startDate | cut -c 6-7`
    dd=`echo $startDate | cut -c 9-10`

    # Locate data folder
    dataglo_dir=data_global/$yy/$mm
    dataloc_dir=data_local/$yy/$mm
    archive_dir=../$arch_directory/$yy/$mm


    # Create filenames
    filename_glo="cmems_mod_glo_phy${dataset_type}_$($datecommand -d "$startDate" +%Y-%m-%d).nc"

    # Create subfolder for single files
    mkdir -p $dataglo_dir
    mkdir -p $dataloc_dir
    mkdir -p $archive_dir

    [...Download and Process sections...] 

    # Update the startdate and go on
    startDate=$($datecommand -d "$startDate + $addDays days" +%Y-%m-%d)

done
    
# Cleanup
unlink input.nc
unlink m2r_nn.x
unlink corr_vect.x
unlink mesh_mask.nc
unlink coord_bdy.nc
```


#### Download section
```shell
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
```

#### Process section

```shell
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
            time ./m2r_nn.x ../namelists/namelist_${variables[$idv]}_b ${types[$idv]} || \
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

	# Finish statement and unlinking
        echo "End creation file: ${file_ou}"
        unlink file_in.nc

    fi
```
