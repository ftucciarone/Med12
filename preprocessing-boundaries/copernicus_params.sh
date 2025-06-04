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

# Date initialization (always use one leaginf zero)
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








# Check operating system 
# (shamelessly copied from https://stackoverflow.com/questions/394230/how-to-detect-the-os-from-a-bash-script )
echo " Operating system type is: "$OSTYPE
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # linux-type system
    datecommand=date
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    datecommand=gdate
elif [[ "$OSTYPE" == "cygwin" ]]; then
    # POSIX compatibility layer and Linux environment emulation for Windows
    datecommand=date
elif [[ "$OSTYPE" == "msys" ]]; then
    # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
    datecommand=date
elif [[ "$OSTYPE" == "win32" ]]; then
    # I'm not sure this can happen.
    datecommand=
elif [[ "$OSTYPE" == "freebsd"* ]]; then
    # FreeBSD
    datecommand=date
else
    echo " Operating system not recognized"
    exit -2
fi


