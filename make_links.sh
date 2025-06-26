# Let's base ourselves in the base directory

# Link static and dynamic folders 
ln -s ../../../../newMed12/data-static .
ln -s ../../../../newMed12/data-restart/ .
ln -s ../../../../test_clone/dynamic/ data-boundaries
ln -s ../../../../test_clone/dynamic/ data-forcing 
ln -s ../../../../test_clone/dynamic/ data-runoff
ln -s ../../../../test_clone/dynamic/ data-restoring 



# These files has to be in the same folder as the run
ln -s data-static/dist.coast.nc .
ln -s data-static/eddy_diffusivity_2D.nc .
ln -s data-static/eddy_viscosity_2D.nc .
