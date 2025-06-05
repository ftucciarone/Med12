## Preprocessing boundary conditions for the Med12 configuration



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
This file contains the main variables needed to run the download and process script. In particular we have
* `firstDate` and `lastDate` are preset values that should be overridden via command line. If not, we download and process only one day (01/01/2020)
* `dataset_id` is the reference of the Copernicus Marine dataset. We have chosen an [Ocean Reanalysis Dataset]() (and included the [supporting documentation]()) as we need three dimensional ocean fields for the lateral boundary conditions.
* `dataset_type` is a string that might be useful if multiple products are contained in the same file and variables inside are differentiated (e.g. `thetao_oras` vs `thetao_glorys`). In this specific case, only `oras` variables are accounted.
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
