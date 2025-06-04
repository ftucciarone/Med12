> [!WARNING]
> This configuration is based upon the configuration described in: 
> > Storto A., Essa Y, de Toma V., Anav A., Sannino G., Santoleri R., Yang C., (2023): MESMAR v1: A new regional coupled climate model for downscaling, predictability, and data assimilation studies in the Mediterranean region. [doi](https://doi.org/10.5194/gmd-16-4811-2023). 
>
> that was provided to the owner of this repository (Francesco Tucciarone) by the original author, Andrea Storto. 
>
> The owner of this repository (Francesco Tucciarone) was not involved in the development of such configuration, thus he shall not be cited when citing the MESMAR configuration. 
>
> The data published under zenodo is a minimal set of data necessary to run the configuration and to create the forcing and boundary conditions with the scripts included in this repository. These scripts were provided by Andrea Storto and were modified by Francesco Tucciarone. This repository includes only the modified version and not the originals.
>
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
