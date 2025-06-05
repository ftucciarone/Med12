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
