> [!WARNING]
> The NEMO configuration in this repository is the ocean component of the regional climate model described in: 
> > Storto A., Essa Y, de Toma V., Anav A., Sannino G., Santoleri R., Yang C., (2023): MESMAR v1: A new regional coupled climate model for downscaling, predictability, and data assimilation studies in the Mediterranean region. [https://doi.org/10.5194/gmd-16-4811-2023](https://doi.org/10.5194/gmd-16-4811-2023). 
>
> It was provided to the owner of this repository (Francesco Tucciarone) by the original author of the paper, Andrea Storto. The owner of this repository (Francesco Tucciarone) was not involved in the development of such configuration, thus he shall not be cited when citing the MESMAR configuration. 
>
> The scripts to perform the preprocessing steps (i.e. the atmospheric forcing and lateral boundary conditions generation) were also provided by Andrea Storto, but here we report new routines, rewritten and adapted by Francesco Tucciarone.
>
> The data published under zenodo is a minimal set of data necessary to run the configuration and to create the forcing and boundary conditions with the scripts included in this repository. This data was provided by Andrea Storto. The owner of this repository was not involved in the construction of such data. 
>
> TL;DR: if you use this configuration without LU stochasticity, cite Andrea's paper, not me. <br/>
> Francesco L. Tucciarone

# MED12: a Mediterranean Sea configuration 

The nemo version is 4.0.7 and can be downloaded as
```shell
https://svn-mirror.nemo-ocean.eu/NEMO/releases/r4.0/r4.0.7/ nemo-4.0.7
```
> [!TIP]
> In my case, the compilation of `REBUILD_NEMO` does not work if I keep the source file as it is, I usually have to run
> ```shell
> sed "s|EXTERNAL|intrinsic|gI" nemo-4.0.7/tools/REBUILD_NEMO/src/rebuild_nemo.F90
> ```
> to change every `external` into `intrinsic`.
