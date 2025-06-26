# Create a simulation, from forcings to NEMO subfolders.
This folder contains the pipeline to create atmospheric forcing and lateral boundary conditions for a given sequence of months. This pipeline is written in Bash and is contained in the script `build_runs_and_forcings.sh`. There are several steps to perform before launching this script. We will try to document all of them. In the following, we assume that the variable `$MED12` contains the path to the root folder of this project. It can be set, for convenience, as:
```shell
export MED12=/path/to/local/Med12/folder
```

### 1. Build tools
First, one needs to compile the Fortran codes that are invoked by the script. This process should be automatic. There are two main set of tools to be compiled, those to process the forcing and those to process the lateral boundaries.
#### Atmospheric forcing
```shell
cd $MED12/preprocessing-forcing/tools
chmod +x compiletools.sh
./compiletools.sh
```
If the compilation fails, open `compiletools.sh` to try resolve the problem. The code is organised as a simple list of compilation statements (bash do) and not as a makefile.
> [!TIP]
> This set of tools use NetCDF. Linking can be done with in the following section of `compiletools.sh`:
> ```shell
> nc_config__which=/home/$USER/nemo-dep/installs/bin/nc-config
> nf_config__which=/home/$USER/nemo-dep/installs/bin/nf-config
> nc_config__which=$( which nc-config ) || { echo "which nc-config failed: check syntax or specify directly the path."; exit ; }
> nf_config__which=$( which nf-config ) || { echo "which nf-config failed: check syntax or specify directly the path."; exit ; }
> ```
> It is important to locate `nc-config` and `nf-config`, they should be in the installation directory of your NetCDF library: this can be done either using `which nc-config` and `which nf-config`, or directly pointing the executable in the installation folder. Run 
> ```shell
> which nc-config
> which nf-config
> ```
> and if they do not return an installation path, locate the installation folder and modify `compiletools.sh` as:
> ```shell
> nc_config__which=NetCDF-installation-folder/bin/nc-config
> nf_config__which=NetCDF-installation-folder/bin/nf-config
> #nc_config__which=$( which nc-config ) || { echo "which nc-config failed: check syntax or specify directly the path."; exit ; }
> #nf_config__which=$( which nf-config ) || { echo "which nf-config failed: check syntax or specify directly the path."; exit ; }
> ```
#### Lateral boundary conditions
```shell
cd $MED12/preprocessing-boundaries/tools
chmod +x compile_bdy.sh; ./compile_bdy.sh
chmod +x compile_fill.sh; ./compile_fill.sh
```
This should compile the boundary generation scripts and the land filling algorithm. 
> [!TIP]
> This set of tools use NetCDF. Linking can be done, similarly to the previous section, in the `NetCDF.macro` file. In particular, pay attention to the lines:
> ```shell
> #nc_config__which=/usr/bin/nc-config
> nc_config__which=$( which nc-config ) || { echo "which nc-config failed: check syntax or specify directly the path."; exit ; }
> [...]
> #nf_config__which=/usr/bin/nf-config
> nf_config__which=$( which nf-config ) || { echo "which nf-config failed: check syntax or specify directly the path."; exit ; }
> ```
> and follow the same guidelines.
##### SOSIE
```shell
cd $MED12/preprocessing-boundaries/tools/sosie_new
make
```
> [!TIP]
> Again, there is the need to link NetCDF libraries. Here, we cannot use the previous trick as SOSIE is compiled through a makefile and not through shell scripting. However, it boils down to run
> ```shell
> nf-config --prefix
> ``` 
and to copy paste the path returned in the `make.macro` file for the following variable: 
> ```shell
> NETCDF_PATH=/path/to/NetCDF/prefix
> ```




### 2. Link the tools
The main script is `build_runs_and_forcings.sh`, and can be invoked simply as
```shell
chmod +x build_runs_and_forcings.sh # necessary only once
./build_runs_and_forcings.sh
```
In simple words, for each month between two dates this scripts downloads the necessary files to compute the atmospheric forcing and lateral boundary conditions, and then creates a NEMO subfolder to run the simulation.


