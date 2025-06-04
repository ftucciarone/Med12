! ----------------------------------------------------------------------
! Code to create BDY data 
! P.Oddo CMRE (2018)
! SF modified to deal with other variables and take directly the points on the
! boundary
! ----------------------------------------------------------------------

       program create_bdy_T

       use netcdf

       IMPLICIT NONE

       include 'netcdf.inc' 

       integer  stat,ncid,idvar,jpkdta,jpidta, jpjdta, jptdta, jpiout
       integer :: start(4), count(4), start2(3), count2(3), star(2), coun(2)
       integer :: kk,index(2)
       integer :: jpi,jpj,jpk,jpt,jpo
       integer :: iddep,idlat,ideof,idlon,idvardep,idvareta,idvarlat,idvarlon
       integer :: idvarsal,idvartem,idvarfice,idvarhice,idvarhsnow

! ----------------------------------------------------------------------
! define input
! ----------------------------------------------------------------------
       real(8),allocatable, dimension (:,:,:,:)  ::  tem,sal         !|
       real(8),allocatable, dimension (:,:,:)    ::  ssh,hsnow,hice,fice             !|
! ----------------------------------------------------------------------
! Gemoetry input output
! ----------------------------------------------------------------------
       integer,allocatable, dimension (:)        ::  indi,indj        !|
! ----------------------------------------------------------------------
! Output variables
! ----------------------------------------------------------------------
       real(8),allocatable, dimension (:,:,:,:)   ::  tem_ou,sal_ou    !|
       real(8),allocatable, dimension (:,:,:)     ::  ssh_ou           !|
       real(8),allocatable, dimension (:,:,:)     ::  hsnow_ou,fice_ou,hice_ou !|
! ----------------------------------------------------------------------
! working arrays
! ----------------------------------------------------------------------
       real(8),allocatable, dimension (:,:)      ::  tmp              !|

!                          START
! ------------------------------------------------------
! Reading input file
! ------------------------------------------------------
    stat = nf90_open('file_in.nc', NF90_NOWRITE, ncid)
    if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
! ------------------------------------------------------
! Get dimensions
! ------------------------------------------------------
    stat = nf90_inq_dimid (ncid, 'z', idvar)
    if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
    stat = nf90_inquire_dimension (ncid, idvar, len = jpkdta)

    stat = nf90_inq_dimid (ncid, 'x', idvar)
    if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
    stat = nf90_inquire_dimension (ncid, idvar, len = jpidta)

    stat = nf90_inq_dimid (ncid, 'y', idvar)
    if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
    stat = nf90_inquire_dimension (ncid, idvar, len = jpjdta)

    stat = nf90_inq_dimid (ncid, 'time', idvar)
    if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
    stat = nf90_inquire_dimension (ncid, idvar, len = jptdta)

  write(*,*)'jpkdta=',jpkdta,'jpidta=',jpidta,'jpjdta=',jpjdta,'jptdta=',jptdta
! ------------------------------------------------------
! Allocate arrays
! ------------------------------------------------------
       if (.not. allocated (tem)) allocate (tem(jpidta,jpjdta,jpkdta,jptdta))
       if (.not. allocated (sal)) allocate (sal(jpidta,jpjdta,jpkdta,jptdta))
       if (.not. allocated (ssh)) allocate (ssh(jpidta,jpjdta,       jptdta))
       if (.not. allocated (fice)) allocate (fice(jpidta,jpjdta,       jptdta))
       if (.not. allocated (hice)) allocate (hice(jpidta,jpjdta,       jptdta))
!
!
       if (.not. allocated (tmp)) allocate (tmp(jpidta,jpjdta))
!
! ------------------------------------------------------
! Retrive variables
! ------------------------------------------------------
! ------------------------------------------------------
! Salinity
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
     stat = nf90_inq_varid (ncid, 'so', idvar)
     if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
     stat = nf90_get_var (ncid,idvar,sal(:,:,:,:),start,count)
     if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
! ------------------------------------------------------
! Temperature
! ------------------------------------------------------
     stat = nf90_inq_varid (ncid, 'thetao', idvar)
     if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
     stat = nf90_get_var (ncid,idvar,tem(:,:,:,:),start,count)
     if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
! ------------------------------------------------------
! SSH
! ------------------------------------------------------
    start2(1)=1
    start2(2)=1
    start2(3)=1
    count2(1)=jpidta
    count2(2)=jpjdta
    count2(3)=jptdta
!
    stat = nf90_inq_varid (ncid, 'zos', idvar)
    if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
    stat = nf90_get_var (ncid,idvar,ssh(:,:,:),start2,count2)
    if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
    
#ifdef seaice
    stat = nf90_inq_varid (ncid, 'siconc', idvar)
    if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
    stat = nf90_get_var (ncid,idvar,fice(:,:,:),start2,count2)
    if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
    
    stat = nf90_inq_varid (ncid, 'sithick', idvar)
    if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
    stat = nf90_get_var (ncid,idvar,hice(:,:,:),start2,count2)
    if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
#endif
! ------------------------------------------------------
! Lat Lon
! ------------------------------------------------------
! SKIPPED
! ------------------------------------------------------
! Close file
! ------------------------------------------------------
    stat = nf90_close(ncid)
! ------------------------------------------------------
! Depth and geometry BDY file
! ------------------------------------------------------
      stat = nf90_open('coord_bdy.nc', NF90_NOWRITE, ncid)
      if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
!
      stat = nf90_inq_dimid (ncid, 'xbT', idvar)
      if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
      stat = nf90_inquire_dimension (ncid, idvar, len = jpiout)
!
      if (.not. allocated (indi)) allocate (indi(jpiout))
      if (.not. allocated (indj)) allocate (indj(jpiout))

      stat = nf90_inq_varid (ncid, 'nbit', idvar)
      if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
      stat = nf90_get_var (ncid,idvar,indi)
      if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
!
      stat = nf90_inq_varid (ncid, 'nbjt', idvar)
      if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
      stat = nf90_get_var (ncid,idvar,indj)
      if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
      stat = nf90_close(ncid)
! ------------------------------------------------------
! Allocate output
! ------------------------------------------------------
       if (.not. allocated (tem_ou)) allocate (tem_ou(jpiout,1,jpkdta,jptdta))
       if (.not. allocated (sal_ou)) allocate (sal_ou(jpiout,1,jpkdta,jptdta))
       if (.not. allocated (ssh_ou)) allocate (ssh_ou(jpiout,1,jptdta))
       if (.not. allocated (fice_ou)) allocate (fice_ou(jpiout,1,jptdta))
       if (.not. allocated (hice_ou)) allocate (hice_ou(jpiout,1,jptdta))
! ------------------------------------------------------
! take points on the boundary
! ------------------------------------------------------
       do jpo=1,jpiout
           tem_ou(jpo,1,:,:)=tem(indi(jpo),indj(jpo),:,:)
           sal_ou(jpo,1,:,:)=sal(indi(jpo),indj(jpo),:,:)
           ssh_ou(jpo,1,:)  =ssh(indi(jpo),indj(jpo),:)
           fice_ou(jpo,1,:)  =fice(indi(jpo),indj(jpo),:)
           hice_ou(jpo,1,:)  =hice(indi(jpo),indj(jpo),:)
       enddo

! ------------------------------------------------------
! Replace missing values
! ------------------------------------------------------
       do jpo=1,jpiout
         do jpk=2,jpkdta
           do jpt=1,jptdta
             if (sal_ou(jpo,1,jpk,jpt)<-1000.0) then
               sal_ou(jpo,1,jpk,jpt)=sal_ou(jpo,1,jpk-1,jpt)
             endif
           enddo
         enddo
       enddo


!-----------------------------------------------------------------------
! Write netcdf file
!-----------------------------------------------------------------------

  stat = nf90_create('file_ou.nc', NF90_64BIT_OFFSET, ncid)
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
  !stat = nf90_open  ('file_ou.nc', nf90_write       , ncid)
  !if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
!
  !stat = nf90_redef(ncid)
  !if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
!
  stat = nf90_def_dim(ncid, 'x'           , jpiout, idlon)
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
  stat = nf90_def_dim(ncid, 'y'           , 1     , idlat)
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
  stat = nf90_def_dim(ncid, 'deptht'      , jpkdta, iddep)
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
  stat = nf90_def_dim(ncid, 'time_counter', nf90_unlimited,ideof)
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
!
  stat = nf90_def_var ( ncid, 'votemper', nf90_float, (/ idlon, idlat, iddep, ideof/), idvartem)
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
  stat = nf90_def_var ( ncid, 'vosaline', nf90_float, (/ idlon, idlat, iddep, ideof/), idvarsal)
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
  stat = nf90_def_var ( ncid, 'sossheig', nf90_float, (/ idlon, idlat, ideof/), idvareta)
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
#ifdef seaice
  stat = nf90_def_var ( ncid, 'ileadfra', nf90_float, (/ idlon, idlat, ideof/),idvarfice)
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
  stat = nf90_def_var ( ncid, 'iicethic', nf90_float, (/ idlon, idlat,ideof/),idvarhice)
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
#endif
!
  stat = nf90_enddef(ncid)
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
!
  stat = nf90_put_var ( ncid, idvartem,tem_ou);
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
!
  stat = nf90_put_var ( ncid, idvarsal,sal_ou);
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
!
  stat = nf90_put_var ( ncid, idvareta,ssh_ou);
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)

#ifdef seaice
  stat = nf90_put_var ( ncid, idvarfice,fice_ou);
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)

  stat = nf90_put_var ( ncid, idvarhice,hice_ou);
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
#endif

!
  stat = nf90_close (ncid)
  if (stat /= nf90_noerr) call netcdf_err(stat,__LINE__)
!
  
 end program create_bdy_T

!-----------------------------------------------------------------------
     subroutine netcdf_err(errcode,kline)
!-----------------------------------------------------------------------

  use netcdf

  implicit none

  INTEGER, intent(in) :: errcode, kline

  if(errcode /= nf90_noerr) then
     print*,'Netcdf Error: ', trim(nf90_strerror(errcode)), ' at line ',kline
     stop "Stopped"
  endif

end subroutine netcdf_err



subroutine lintrp (n,x,y,ni,xi,yi)
!
!=======================================================================
!  Copyright (c) 2000 Rutgers University.                              !
!================================================== Hernan G. Arango ===
!                                                                      !
!  Given arrays X and Y of length N, which tabulate a function,        !
!  Y = F(X),  with the Xs  in ascending order, and given array         !
!  XI of lenght NI, this routine returns a linear interpolated         !
!  array YI.                                                           !
!                                                                      !
!=======================================================================
!
      implicit none
      integer i, ii, j, n, ni
      real d1, d2
      real x(n), y(n), xi(ni), yi(ni)
!
!-----------------------------------------------------------------------
!  Linear interpolate fro look-table.
!-----------------------------------------------------------------------
!
      do j=1,ni
        if (xi(j).le.x(1)) then
          ii=1
          yi(j)=y(1)
        elseif (xi(j).ge.x(n))then
          yi(j)=y(n)
        else
          do i=1,n-1
            if ((x(i).lt.xi(j)).and.(xi(j).le.x(i+1))) then
              ii=i
              goto 10
            endif
          enddo
  10      d1=xi(j)-x(ii)
          d2=x(ii+1)-xi(j)
          yi(j)=(d1*y(ii+1)+d2*y(ii))/(d1+d2)
        endif
      enddo

end subroutine lintrp
