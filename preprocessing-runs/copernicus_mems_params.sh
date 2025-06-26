#!/bin/bash
# ###############################################################################
# 
# Parameters:
#
#    work_directory, (name): this is folder that is created and will contain all 
#                            the temporary files. Deleting this folder should not
#                            cause any harm
#    arch_directory, (name): this folder is the archive of the processed data
#            exe_nn, (exec): complete location of the nearest-neighbour executable
#           exe_rot, (exec): complete location of the rotation executable (SOSIE)
#           exe_bdy, (path): path (without executable) of the create_bdy executables
#  output_directory, (path):
#        dataset_id        : copernicus product id, consult the website
#      dataset_type        : either "_oras" or "_glorys", always with underscore
#      datafilename        : filename to give/read 
#        variables         : list of variables to process, do not include suffixes
#       dimensions         : physical dimensions of the variables
#
# ###############################################################################

# DatasetID
dataset_id="cmems_mod_glo_phy-all_my_0.25deg_P1D-m"
dataset_type="_oras"
# Filename
datafilename=cmems_mod_glo_phy 

# Output boundary filename
prefix=grepv2_ORAS5

# Variables
variables=("thetao" "so" "vo" "uo" "zos" )
dimensions=(3 3 3 3 2 )

# Directories set
base_dir=.
grib_dir=grib
run_dir=run
work_dir=work
arch_dir=../archive-boundaries
nams_dir=/home/ftucciar/finalMed12/preprocessing-boundaries/namelists
tools_dir=/home/ftucciar/finalMed12/preprocessing-boundaries/tools

# Files
coord_bdy=/home/ftucciar/newMed12/data-static/coordinates.bdy.nc
mesh_mask=/home/ftucciar/newMed12/data-static/mesh_mask.nc

# Fortran executables
exe_nn=$tools_dir/fill_land/m2r_nn.x
exe_rot=$tools_dir/sosie_new/bin/mycorr_vect.x
exe_bdy=$tools_dir/create_bdy

# Debug flag (if true, only prints on screen the commands)
debug=false