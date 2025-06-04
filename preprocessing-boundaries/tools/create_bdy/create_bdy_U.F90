        ! ----------------------------------------------------------------------
        ! Code to create BDY data 
        ! S. Falchetti CMRE (2018)
        ! Read the zonal and meridional components from topaz, then rotate those
        ! components on the nemo U grid, and extract the u component on the boundary
        ! ----------------------------------------------------------------------

               program create_bdy_U

               use netcdf

               IMPLICIT NONE

               include 'netcdf.inc' 

               integer  stat,ncid,idvar,jpkdta,jpidta, jpjdta, jptdta, jpiout
               integer :: start(4), count(4), start2(3), count2(3), star(2), coun(2)
               integer :: kk,index(2)
               integer :: jpi,jpj,jpk,jpt,jpo
               integer :: iddep,idlat,ideof,idlon,idvardep,idvareta,idvarlat,idvarlon
               integer :: idvaru,idvarv
               INTEGER ::   ji, jj,j,i,jt,jz
               real(8),allocatable, dimension (:,:)      :: angle
               real(8) ::   a1,a2
               REAL(8), PARAMETER :: rpi = 3.141592653e0
               REAL(8), PARAMETER :: rad = rpi / 180.e0
               LOGICAL, PARAMETER :: ll_rotate = .false.
        ! ----------------------------------------------------------------------
        ! define input
        ! ----------------------------------------------------------------------
               real(8),allocatable, dimension (:,:,:,:)  ::  v,u,umodel,vmodel         !|
               real(8),allocatable, dimension (:,:,:)    ::  ssh             !|
        ! ----------------------------------------------------------------------
        ! Gemoetry input output
        ! ----------------------------------------------------------------------
               real(8),allocatable, dimension (:,:)      ::  lat_in,lon_in    !|
               real(8),allocatable, dimension (:)        ::  lat_ou,lon_ou    !|
               integer,allocatable, dimension (:)        ::  indi,indj        !|
        ! ----------------------------------------------------------------------
        ! Output variables
        ! ----------------------------------------------------------------------
               real(8),allocatable, dimension (:,:,:,:)   ::  u_ou,v_ou    !|
               real(8),allocatable, dimension (:,:,:)     ::  ssh_ou           !|
        ! ----------------------------------------------------------------------
        ! working arrays
        ! ----------------------------------------------------------------------
               real(8),allocatable, dimension (:,:)      ::  tmp              !|

        !                          START
        ! ------------------------------------------------------
        ! Reading input file
        ! ------------------------------------------------------
            stat = nf90_open('file_in.nc', NF90_NOWRITE, ncid)
            if (stat /= nf90_noerr) call netcdf_err(stat)
        ! ------------------------------------------------------
        ! Get dimensions
        ! ------------------------------------------------------
            stat = nf90_inq_dimid (ncid, 'z', idvar)
            if (stat /= nf90_noerr) call netcdf_err(stat)
            stat = nf90_inquire_dimension (ncid, idvar, len = jpkdta)

            stat = nf90_inq_dimid (ncid, 'x', idvar)
            if (stat /= nf90_noerr) call netcdf_err(stat)
            stat = nf90_inquire_dimension (ncid, idvar, len = jpidta)

            stat = nf90_inq_dimid (ncid, 'y', idvar)
            if (stat /= nf90_noerr) call netcdf_err(stat)
            stat = nf90_inquire_dimension (ncid, idvar, len = jpjdta)

            stat = nf90_inq_dimid (ncid, 'time', idvar)
            if (stat /= nf90_noerr) call netcdf_err(stat)
            stat = nf90_inquire_dimension (ncid, idvar, len = jptdta)

        ! ------------------------------------------------------
        ! Allocate arrays
        ! ------------------------------------------------------
               if (.not. allocated (u)) allocate (u(jpidta,jpjdta,jpkdta,jptdta))
               if (.not. allocated (v)) allocate (v(jpidta,jpjdta,jpkdta,jptdta))
               if (.not. allocated (umodel)) allocate (umodel(jpidta,jpjdta,jpkdta,jptdta))
               if (.not. allocated (vmodel)) allocate (vmodel(jpidta,jpjdta,jpkdta,jptdta))
        !
        if(ll_rotate) then
               if (.not. allocated (lon_in)) allocate (lon_in(jpidta,jpjdta))
               if (.not. allocated (lat_in)) allocate (lat_in(jpidta,jpjdta))
        endif
               if (.not. allocated (tmp)) allocate (tmp(jpidta,jpjdta))
               if (.not. allocated (angle)) allocate (angle(jpidta,jpjdta))

        ! Retrive variables
        ! ------------------------------------------------------
        ! ------------------------------------------------------
        ! Velocity
        ! ------------------------------------------------------
             start(1)=1 
             start(2)=1 
             start(3)=1 
             start(4)=1 
        !
             count(1)=jpidta
             count(2)=jpjdta
             count(3)=jpkdta
             count(4)=jptdta
        !
             stat = nf90_inq_varid (ncid, 'uo', idvar)
             if (stat /= nf90_noerr) call netcdf_err(stat)
             stat = nf90_get_var (ncid,idvar,u(:,:,:,:),start,count)
             if (stat /= nf90_noerr) call netcdf_err(stat)
             stat = nf90_inq_varid (ncid, 'vo', idvar)
             if (stat /= nf90_noerr) call netcdf_err(stat)
             stat = nf90_get_var (ncid,idvar,v(:,:,:,:),start,count)
             if (stat /= nf90_noerr) call netcdf_err(stat)
        ! ------------------------------------------------------
        ! Lat Lon
        ! ------------------------------------------------------
            start2(1)=1
            start2(2)=1
            start2(3)=1
            count2(1)=jpidta
            count2(2)=jpjdta
            count2(3)=jptdta

        if(ll_rotate) then
            stat = nf90_inq_varid (ncid, 'glamu', idvar)
            if (stat /= nf90_noerr) call netcdf_err(stat)
            stat = nf90_get_var (ncid,idvar,lon_in(:,:),start2,count2)
            if (stat /= nf90_noerr) call netcdf_err(stat)

            stat = nf90_inq_varid (ncid, 'gphiu', idvar)
            if (stat /= nf90_noerr) call netcdf_err(stat)
            stat = nf90_get_var (ncid,idvar,lat_in(:,:),start2,count2)
            if (stat /= nf90_noerr) call netcdf_err(stat)
    endif
        ! ------------------------------------------------------
        ! Close file
        ! ------------------------------------------------------
            stat = nf90_close(ncid)
            
            !  from kate for roms calculate the angle between the xi-eta grid and the
            !  lon-lat grid
               !  at rho points. see discusssion
               !  https://www.myroms.org/forum/viewtopic.php?f=14&t=4137


               if( ll_rotate ) then

                do j = 1, jpjdta-1
                  do i = 1, jpidta-1
                    a1 = lat_in(i+1, j) - lat_in(i, j)
                    a2 = lon_in(i+1, j) - lon_in(i, j)
                    if (abs(a2) .gt. 180.) then
                      if (a2 .lt. -180. ) then
                        a2 = a2 + 360.
                      else
                        a2 = a2 - 360.
                      endif
                    endif
                    a2 = a2 * cos(0.5*rad*(lat_in(i, j) + lat_in(i+1, j)))
                    angle(i, j) = atan2(a1, a2)
                  enddo
                enddo

                do j = 1, jpjdta-1
                  do i = 1, jpidta-1
                    a2 = lat_in(i, j) - lat_in(i, j+1)
                    a1 = (lon_in(i, j) - lon_in(i, j+1))
                    if (abs(a1) .gt. 180.) then
                      if (a1 .lt. -180. ) then
                        a1 = a1 + 360.
                      else
                        a1 = a1 - 360.
                      endif
                    endif
                    a1 = a1 * cos(0.5*rad*(lat_in(i, j) + lat_in(i, j+1)))
                    angle(i, j) = 0.5*(angle(i, j) + atan2(a1, -a2))
                  enddo
                enddo
                angle(:,jpjdta)=angle(:,jpjdta-1);
                angle(jpidta,:)=angle(jpidta-1,:);
                !silvia from east north to model components
                do jt = 1,jptdta
                   do jz = 1,jpkdta
                      do jj = 1, jpjdta
                         do ji = 1, jpidta
                            umodel(ji,jj,jz,jt)=u(ji,jj,jz,jt)*cos(angle(ji,jj))+v(ji,jj,jz,jt)*sin(angle(ji,jj))
                            vmodel(ji,jj,jz,jt)=v(ji,jj,jz,jt)*cos(angle(ji,jj))-u(ji,jj,jz,jt)*sin(angle(ji,jj))
                         enddo
                      enddo
                   enddo
               enddo 

               else

                       umodel = u
                       vmodel = v

               endif
        ! ------------------------------------------------------
        ! Depth and geometry BDY file
        ! ------------------------------------------------------
              stat = nf90_open('coord_bdy.nc', NF90_NOWRITE, ncid)
              if (stat /= nf90_noerr) call netcdf_err(stat)
        !
              stat = nf90_inq_dimid (ncid, 'xbU', idvar)
              if (stat /= nf90_noerr) call netcdf_err(stat)
              stat = nf90_inquire_dimension (ncid, idvar, len = jpiout)
        !
        if(ll_rotate) then
              if (.not. allocated (lon_ou)) allocate (lon_ou(jpiout))
              if (.not. allocated (lat_ou)) allocate (lat_ou(jpiout))
      endif
              if (.not. allocated (indi)) allocate (indi(jpiout))
              if (.not. allocated (indj)) allocate (indj(jpiout))

        if(ll_rotate) then
              stat = nf90_inq_varid (ncid, 'lonU', idvar)
              if (stat /= nf90_noerr) call netcdf_err(stat)
              stat = nf90_get_var (ncid,idvar,lon_ou)
              if (stat /= nf90_noerr) call netcdf_err(stat)
        !
              
              stat = nf90_inq_varid (ncid, 'latU', idvar)
              if (stat /= nf90_noerr) call netcdf_err(stat)
              stat = nf90_get_var (ncid,idvar,lat_ou)
              if (stat /= nf90_noerr) call netcdf_err(stat)
      endif

              stat = nf90_inq_varid (ncid, 'nbiu', idvar)
              if (stat /= nf90_noerr) call netcdf_err(stat)
              stat = nf90_get_var (ncid,idvar,indi)
              if (stat /= nf90_noerr) call netcdf_err(stat)
        !
              stat = nf90_inq_varid (ncid, 'nbju', idvar)
              if (stat /= nf90_noerr) call netcdf_err(stat)
              stat = nf90_get_var (ncid,idvar,indj)
              if (stat /= nf90_noerr) call netcdf_err(stat)
              stat = nf90_close(ncid)
              stat = nf90_close(ncid)
        ! ------------------------------------------------------
        ! Allocate output
        ! ------------------------------------------------------
               if (.not. allocated (u_ou)) allocate (u_ou(jpiout,1,jpkdta,jptdta))
        ! ------------------------------------------------------
        ! interpolate with nearest
        ! ------------------------------------------------------
               do jpo=1,jpiout
                   u_ou(jpo,1,:,:)=umodel(indi(jpo),indj(jpo),:,:)
               enddo
        !-----------------------------------------------------------------------
        ! Write netcdf file
        !-----------------------------------------------------------------------

          stat = nf90_create('file_ou.nc', NF90_64BIT_OFFSET, ncid)
          stat = nf90_open  ('file_ou.nc', nf90_write       , ncid)
        !
          stat = nf90_redef(ncid)
        !
          stat = nf90_def_dim(ncid, 'x'           , jpiout, idlon)
          stat = nf90_def_dim(ncid, 'y'           , 1     , idlat)
          stat = nf90_def_dim(ncid, 'deptht'      , jpkdta, iddep)
          stat = nf90_def_dim(ncid, 'time_counter', nf90_unlimited,ideof)
        !
          stat = nf90_def_var ( ncid, 'vozocrtx', nf90_float, (/ idlon, idlat, iddep, ideof/), idvaru)
!
  stat = nf90_enddef(ncid)
!
  stat = nf90_put_var ( ncid, idvaru,u_ou);
  if (stat /= nf90_noerr) call netcdf_err(stat)
!
  stat = nf90_close (ncid)
!

 end program create_bdy_U

!-----------------------------------------------------------------------
     subroutine netcdf_err(errcode)
!-----------------------------------------------------------------------

  use netcdf

  implicit none

  INTEGER, intent(in) :: errcode

  if(errcode /= nf90_noerr) then
     print*,'Netcdf Error: ', trim(nf90_strerror(errcode))
     stop "Stopped"
  endif

end subroutine netcdf_err
