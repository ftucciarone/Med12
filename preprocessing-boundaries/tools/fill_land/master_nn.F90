PROGRAM MASTER

!...........................................................
!
! Preprocessor for global to regional model files
! For use with Initial and boundary condition preparation
!
! Assume source grid is regular and target is not
! Use NN regridding (more robust than 
! any akima or bilin/bicub interpolation)
!
! OpenMP parallelization is supported through key openmp
!
! AS2020
!
!...........................................................

IMPLICIT NONE

INTEGER :: IAUX
CHARACTER :: CAUX
CHARACTER(len=99) :: CNAM
INTEGER :: N3D 

CALL GETARG(1,CNAM)
IF(LEN_TRIM(CNAM).eq.0) THEN
        WRITE(*,*) ' Please specify the namelist'
ENDIF

CALL GETARG(2,CAUX)
N3D = 3
IF(CAUX .EQ. '2') N3D = 2
IF(CAUX .EQ. '4') N3D = 4

IF (N3D.EQ.3) THEN
        WRITE(*,*) '3d interpolation'
        CALL INTNN3
ELSEIF (N3D.EQ.4) THEN
        WRITE(*,*) '3d+time interpolation'
        CALL INTNN4
ELSEIF (N3D.EQ.2) THEN
        WRITE(*,*) '2d interpolation'
        CALL INTNN2
ELSE
        WRITE(*,*) 'Unknown configuration'
        STOP
ENDIF

CONTAINS 

SUBROUTINE INTNN4

#ifdef __OPENMP__
USE OMP_LIB
#endif
USE NCDF

IMPLICIT NONE

INTEGER :: im, jm, km
INTEGER :: io, jo, ko
REAL, DIMENSION(:,:,:), ALLOCATABLE :: mski,msko
REAL, DIMENSION(:,:,:,:), ALLOCATABLE :: fldi,fldo
REAL, DIMENSION(:,:  ), ALLOCATABLE :: lono,lato
REAL, DIMENSION(:    ), ALLOCATABLE :: loni,lati
REAL, DIMENSION(:    ), ALLOCATABLE :: depi,depo
REAL :: zmv

INTEGER :: jk, kk, jk2, jj, ji, ki, kj,nt
REAL    :: ri, rj, rk, p(8)
INTEGER :: ki1,ki2,ki3,ki4,kj1,kj2,kj3,kj4
REAL    :: ri1,ri2,ri3,ri4,rj1,rj2,rj3,rj4,ro
REAL    :: zoff,zscl,rk2
INTEGER :: kf ,kf2 ,kt, kk2, gs, myt, gi, gj,gk
REAL    :: xd, yd, rd, zd
REAL, ALLOCATABLE :: pt(:)
INTEGER, ALLOCATABLE :: gsi(:,:,:)
INTEGER, ALLOCATABLE :: gsj(:,:,:)
INTEGER, ALLOCATABLE :: gsk(:,:,:)
LOGICAL :: lok, lcal

CHARACTER(LEN=300):: cfin,cfmo,cunit,clnm
CHARACTER(LEN=80) :: cvar,cvlom,cvlam,cvmso,cvloo,cvlao,&
        & catt,cvdm,cvdo

INTEGER, PARAMETER :: gs_hs = 200
REAL, PARAMETER :: deg2rad = 0.01745329, rad2deg = 57.29578, Rad = 6371000.

!...........................................................

NAMELIST/config/cfin,cvar,im,jm,km,cvlom,cvlam,&
       & io,jo,ko,cvmso,cvloo,cvlao,nt,&
       & catt,cfmo,cvdm,cvdo,lcal,cunit,clnm

WRITE(*,*) ' Reading namelist'

open(12,FILE=TRIM(cnam),STATUS='OLD')
read(12,config)
close(12)

WRITE(*,*) ' Allocating field'
ALLOCATE(FLDI(im,jm,km,nt))
ALLOCATE(MSKI(im,jm,km))
ALLOCATE(LONI(im))
ALLOCATE(LATI(jm))
ALLOCATE(DEPI(km))

ALLOCATE(FLDO(io,jo,ko,nt))
ALLOCATE(MSKO(io,jo,ko))
ALLOCATE(LONO(io,jo))
ALLOCATE(LATO(io,jo))
ALLOCATE(DEPO(ko))

WRITE(*,*) ' Reading field'
Call GETVAR(cfin,cvar ,im,jm,km,nt,fldi)
Call GETVAR(cfin,cvlom,im,loni)
where ( loni .gt. 180.) loni=loni-360.
Call GETVAR(cfin,cvlam,jm,lati)
Call GETATT(cfin,cvar,catt,zmv)
Call GETATT(cfin,cvar,'add_offset'  ,zoff)
Call GETATT(cfin,cvar,'scale_factor',zscl)
zoff = 0.
zscl = 1.
Call GETVAR(cfin,cvdm,km,depi)

mski(:,:,:) = 1.
where ( fldi(:,:,:,1) .eq. zmv ) mski = 0.
write(*,*) ' Ocean points in input file :', 100. * sum(mski) / real(im*jm*km)

fldi = fldi*zscl+zoff

WRITE(*,*) ' Reading field'
Call GETVAR(cfmo,cvmso,io,jo,ko,msko)
Call GETVAR(cfmo,cvloo,io,jo,lono)
Call GETVAR(cfmo,cvlao,io,jo,lato)
Call GETVAR(cfmo,cvdo ,ko,depo)

!...........................................................

fldo=0.
kf=0
kf2=0
allocate( pt(gs_hs*gs_hs*16) )
allocate(gsi(io,jo,ko))
allocate(gsj(io,jo,ko))
allocate(gsk(io,jo,ko))

if(lcal) then
   gsi(:,:,:) = 0
   gsj(:,:,:) = 0
   gsk(:,:,:) = 0
else
   write(*,*) 'reading gsarr'
   Call GETVAR('gsari.nc','ii',io,jo,ko,gsi)
   Call GETVAR('gsarj.nc','jj',io,jo,ko,gsj)
   Call GETVAR('gsark.nc','kk',io,jo,ko,gsk)
endif

#ifdef __OPENMP__
!$OMP PARALLEL DEFAULT(SHARED),PRIVATE(jk,kk,rk,jk2,ji,jj,ki,kj,ri,rj,&
!$OMP & p,kf,kf2,pt,ki1,ki2,ki3,ki4,kj1,kj2,kj3,kj4,ri1,ri2,ri3,ri4,rj1,&
!$OMP & rj2,rj3,rj4,kt,ro,kk2,lok,gs,myt,rk2,xd,yd,zd,rd,gi,gj,gk)
myt=omp_get_thread_num()
!$OMP DO SCHEDULE(DYNAMIC,1)
#else
myt=1
#endif
DO jk=1,ko

  IF (ko.eq.1 .or. km.eq.1) THEN
          kk = 1
          rk = 1.
  ELSE
    kk = 0
    rk = 0.
    DO jk2=1,km
        if( depo(jk) .ge. depi(jk2) .and. &
            depo(jk) .lt. depi(jk2+1) ) then
 
            kk = jk2
            rk = 1. - ( abs(depo(jk)-depi(jk2)) / abs( depi(jk2+1)-depi(jk2)) )
 
        endif
    ENDDO
    if(kk.eq.0) then
            if( depo(jk) .ge. depi(km) ) then
                    kk=km
                    rk=1.
            else if ( depo(jk) .lt. depi(1) ) then
                    kk=1
                    rk=1.
            else
                    write(*,*) 'Vertical interp failed',jk
                    call abort()
            endif
    endif
  endif

  write(*,*) myt,':',jk,kk,rk
 
  DO jj=1,jo

      ! if(mod(jj,10).eq.0) write(*,*) myt,':',jk,jj

      DO ji=1,io
      
         IF( msko(ji,jj,jk) .gt. 0.5 ) THEN

                  ki = int( (lono(ji,jj)-loni(1))/abs( loni(2)-loni(1) ) ) + 1
                  kj = int( (lato(ji,jj)-lati(1))/abs( lati(2)-lati(1) ) ) + 1

        if( lcal ) then
                  lok = .false.

                  gsc : DO gs=1,gs_hs

                  kt = 0
                  ro = 1.e+12

                  DO kk2=max(1,kk-(gs-1)),min(km,kk+gs)
                   DO kj2=max(1,kj-(gs-1)),min(jm,kj+gs)
                    DO ki2=max(1,ki-(gs-1)),min(im,ki+gs)

                      IF(mski(ki2,kj2,kk2 ).gt.0.5) then

                       kt = kt+1

                       xd = Rad*deg2rad*(lono(ji,jj)-loni(ki2))*cos(  deg2rad*(lato(ji,jj)+lati(kj2))/2 )
                       yd = Rad*deg2rad*(lato(ji,jj)-lati(kj2))
                       zd = abs( depo(jk)-depi(kk2) )
                       rd = sqrt( xd*xd+yd*yd+zd*zd ) 
                       IF(rd .lt. ro) then
                               ro = rd
                               gi = ki2; gj=kj2 ; gk=kk2
                       endif

                       endif

                    ENDDO
                   ENDDO
                  ENDDO

                  if( kt .gt. 0 ) then
                      fldo(ji,jj,jk,:) = fldi(gi,gj,gk,:)
                      gsi(ji,jj,jk) = gi
                      gsj(ji,jj,jk) = gj
                      gsk(ji,jj,jk) = gk
                      lok = .true.
                      exit gsc
                  endif

                  enddo gsc
                  if(.not.lok) kf=kf+1
          else
                  gi = gsi(ji,jj,jk)
                  gj = gsj(ji,jj,jk)
                  gk = gsk(ji,jj,jk)
                  fldo(ji,jj,jk,:) = fldi(gi,gj,gk,:)
          endif

         ENDIF

      ENDDO

   ENDDO    

ENDDO
#ifdef __OPENMP__
!$OMP END DO
!$OMP END PARALLEL
#endif

!...........................................................

WRITE(*,*) ' DONE! Number of failures> ',kf

call WRITE_VARNCDF('output.nc',io,jo,ko,nt,fldo,cvar,trim(cunit),trim(clnm))
if(lcal) then
        call WRITE_VARNCDF('gsari.nc',io,jo,ko,gsi,'ii','','i-point')
        call WRITE_VARNCDF('gsarj.nc',io,jo,ko,gsj,'jj','','j-point')
        call WRITE_VARNCDF('gsark.nc',io,jo,ko,gsk,'kk','','k-point')
endif

END SUBROUTINE INTNN4

SUBROUTINE INTNN3

#ifdef __OPENMP__
USE OMP_LIB
#endif
USE NCDF

IMPLICIT NONE

INTEGER :: im, jm, km
INTEGER :: io, jo, ko
REAL, DIMENSION(:,:,:), ALLOCATABLE :: mski,msko,fldi,fldo
REAL, DIMENSION(:,:  ), ALLOCATABLE :: lono,lato
REAL, DIMENSION(:    ), ALLOCATABLE :: loni,lati
REAL, DIMENSION(:    ), ALLOCATABLE :: depi,depo
REAL :: zmv

INTEGER :: jk, kk, jk2, jj, ji, ki, kj
REAL    :: ri, rj, rk, p(8)
INTEGER :: ki1,ki2,ki3,ki4,kj1,kj2,kj3,kj4
REAL    :: ri1,ri2,ri3,ri4,rj1,rj2,rj3,rj4,ro
REAL    :: zoff,zscl,rk2
INTEGER :: kf ,kf2 ,kt, kk2, gs, myt, gi, gj,gk
REAL    :: xd, yd, rd, zd
REAL, ALLOCATABLE :: pt(:)
INTEGER, ALLOCATABLE :: gsi(:,:,:)
INTEGER, ALLOCATABLE :: gsj(:,:,:)
INTEGER, ALLOCATABLE :: gsk(:,:,:)
LOGICAL :: lok, lcal

CHARACTER(LEN=300):: cfin,cfmo,cunit,clnm
CHARACTER(LEN=80) :: cvar,cvlom,cvlam,cvmso,cvloo,cvlao,&
        & catt,cvdm,cvdo

INTEGER, PARAMETER :: gs_hs = 200
REAL, PARAMETER :: deg2rad = 0.01745329, rad2deg = 57.29578, Rad = 6371000.

!...........................................................

NAMELIST/config/cfin,cvar,im,jm,km,cvlom,cvlam,&
       & io,jo,ko,cvmso,cvloo,cvlao,&
       & catt,cfmo,cvdm,cvdo,lcal,cunit,clnm

WRITE(*,*) ' Reading namelist'

open(12,FILE=TRIM(cnam),STATUS='OLD')
read(12,config)
close(12)

WRITE(*,*) ' Allocating field'
ALLOCATE(FLDI(im,jm,km))
ALLOCATE(MSKI(im,jm,km))
ALLOCATE(LONI(im))
ALLOCATE(LATI(jm))
ALLOCATE(DEPI(km))

ALLOCATE(FLDO(io,jo,ko))
ALLOCATE(MSKO(io,jo,ko))
ALLOCATE(LONO(io,jo))
ALLOCATE(LATO(io,jo))
ALLOCATE(DEPO(ko))

WRITE(*,*) ' Reading field'
Call GETVAR(cfin,cvar ,im,jm,km,fldi)
Call GETVAR(cfin,cvlom,im,loni)
where ( loni .gt. 180.) loni=loni-360.
Call GETVAR(cfin,cvlam,jm,lati)
Call GETATT(cfin,cvar,catt,zmv)
Call GETATT(cfin,cvar,'add_offset'  ,zoff)
Call GETATT(cfin,cvar,'scale_factor',zscl)
zoff = 0.
zscl = 1.
Call GETVAR(cfin,cvdm,km,depi)

mski(:,:,:) = 1.
where ( fldi .eq. zmv ) mski = 0.
write(*,*) ' Ocean points in input file :', 100. * sum(mski) / real(im*jm*km)

fldi = fldi*zscl+zoff

WRITE(*,*) ' Reading field'
Call GETVAR(cfmo,cvmso,io,jo,ko,msko)
Call GETVAR(cfmo,cvloo,io,jo,lono)
Call GETVAR(cfmo,cvlao,io,jo,lato)
Call GETVAR(cfmo,cvdo ,ko,depo)

!...........................................................

fldo=0.
kf=0
kf2=0
allocate( pt(gs_hs*gs_hs*16) )
allocate(gsi(io,jo,ko))
allocate(gsj(io,jo,ko))
allocate(gsk(io,jo,ko))

if(lcal) then
   gsi(:,:,:) = 0
   gsj(:,:,:) = 0
   gsk(:,:,:) = 0
else
        write(*,*) 'reading gsarr'
   Call GETVAR('gsari.nc','ii',io,jo,ko,gsi)
   Call GETVAR('gsarj.nc','jj',io,jo,ko,gsj)
   Call GETVAR('gsark.nc','kk',io,jo,ko,gsk)
endif

#ifdef __OPENMP__
!$OMP PARALLEL DEFAULT(SHARED),PRIVATE(jk,kk,rk,jk2,ji,jj,ki,kj,ri,rj,&
!$OMP & p,kf,kf2,pt,ki1,ki2,ki3,ki4,kj1,kj2,kj3,kj4,ri1,ri2,ri3,ri4,rj1,&
!$OMP & rj2,rj3,rj4,kt,ro,kk2,lok,gs,myt,rk2,xd,yd,zd,rd,gi,gj,gk)
myt=omp_get_thread_num()
!$OMP DO SCHEDULE(DYNAMIC,1)
#else
myt=1
#endif
DO jk=1,ko

  IF (ko.eq.1 .or. km.eq.1) THEN
          kk = 1
          rk = 1.
  ELSE
    kk = 0
    rk = 0.
    DO jk2=1,km
        if( depo(jk) .ge. depi(jk2) .and. &
            depo(jk) .lt. depi(jk2+1) ) then
 
            kk = jk2
            rk = 1. - ( abs(depo(jk)-depi(jk2)) / abs( depi(jk2+1)-depi(jk2)) )
 
        endif
    ENDDO
    if(kk.eq.0) then
            if( depo(jk) .ge. depi(km) ) then
                    kk=km
                    rk=1.
            else if ( depo(jk) .lt. depi(1) ) then
                    kk=1
                    rk=1.
            else
                    write(*,*) 'Vertical interp failed',jk
                    call abort()
            endif
    endif
  endif

  write(*,*) myt,':',jk,kk,rk
 
  DO jj=1,jo

      ! if(mod(jj,10).eq.0) write(*,*) myt,':',jk,jj

      DO ji=1,io
      
         IF( msko(ji,jj,jk) .gt. 0.5 ) THEN

                  ki = int( (lono(ji,jj)-loni(1))/abs( loni(2)-loni(1) ) ) + 1
                  kj = int( (lato(ji,jj)-lati(1))/abs( lati(2)-lati(1) ) ) + 1

        if( lcal ) then
                  lok = .false.

                  gsc : DO gs=1,gs_hs

                  kt = 0
                  ro = 1.e+12

                  DO kk2=max(1,kk-(gs-1)),min(km,kk+gs)
                   DO kj2=max(1,kj-(gs-1)),min(jm,kj+gs)
                    DO ki2=max(1,ki-(gs-1)),min(im,ki+gs)

                      IF(mski(ki2,kj2,kk2 ).gt.0.5) then

                       kt = kt+1

                       xd = Rad*deg2rad*(lono(ji,jj)-loni(ki2))*cos(  deg2rad*(lato(ji,jj)+lati(kj2))/2 )
                       yd = Rad*deg2rad*(lato(ji,jj)-lati(kj2))
                       zd = abs( depo(jk)-depi(kk2) )
                       rd = sqrt( xd*xd+yd*yd+zd*zd ) 
                       IF(rd .lt. ro) then
                               ro = rd
                               gi = ki2; gj=kj2 ; gk=kk2
                       endif

                       endif

                    ENDDO
                   ENDDO
                  ENDDO

                  if( kt .gt. 0 ) then
                      fldo(ji,jj,jk) = fldi(gi,gj,gk)
                      gsi(ji,jj,jk) = gi
                      gsj(ji,jj,jk) = gj
                      gsk(ji,jj,jk) = gk
                      lok = .true.
                      exit gsc
                  endif

                  enddo gsc
                  if(.not.lok) kf=kf+1
          else
                  gi = gsi(ji,jj,jk)
                  gj = gsj(ji,jj,jk)
                  gk = gsk(ji,jj,jk)
                  fldo(ji,jj,jk) = fldi(gi,gj,gk)
          endif

         ENDIF

      ENDDO

   ENDDO    

ENDDO
#ifdef __OPENMP__
!$OMP END DO
!$OMP END PARALLEL
#endif

!...........................................................

WRITE(*,*) ' DONE! Number of failures> ',kf

call WRITE_VARNCDF('output.nc',io,jo,ko,fldo,cvar,trim(cunit),trim(clnm))
if(lcal) then
        call WRITE_VARNCDF('gsari.nc',io,jo,ko,gsi,'ii','','i-point')
        call WRITE_VARNCDF('gsarj.nc',io,jo,ko,gsj,'jj','','j-point')
        call WRITE_VARNCDF('gsark.nc',io,jo,ko,gsk,'kk','','k-point')
endif

END SUBROUTINE INTNN3
!...........................................................

SUBROUTINE INTNN2

USE NCDF

IMPLICIT NONE

INTEGER :: im, jm, km
INTEGER :: io, jo, ko
REAL, DIMENSION(:,:,:), ALLOCATABLE :: mski,msko
REAL, DIMENSION(:,:  ), ALLOCATABLE :: fldi,fldo
REAL, DIMENSION(:,:  ), ALLOCATABLE :: lono,lato
REAL, DIMENSION(:    ), ALLOCATABLE :: loni,lati
REAL, DIMENSION(:    ), ALLOCATABLE :: depi,depo
REAL :: zmv

INTEGER :: jk, kk, jk2, jj, ji, ki, kj
REAL    :: ri, rj, rk, p(8)
INTEGER :: ki1,ki2,ki3,ki4,kj1,kj2,kj3,kj4
REAL    :: ri1,ri2,ri3,ri4,rj1,rj2,rj3,rj4,ro
REAL    :: zoff,zscl,rk2
INTEGER :: kf ,kf2 ,kt, kk2, gs, myt, gi, gj,gk
REAL    :: xd, yd, rd, zd
REAL, ALLOCATABLE :: pt(:)
INTEGER, ALLOCATABLE :: gsi(:,:,:)
INTEGER, ALLOCATABLE :: gsj(:,:,:)
INTEGER, ALLOCATABLE :: gsk(:,:,:)
LOGICAL :: lok, lcal

CHARACTER(LEN=300):: cfin,cfmo,cunit,clnm
CHARACTER(LEN=80) :: cvar,cvlom,cvlam,cvmso,cvloo,cvlao,&
        & catt,cvdm,cvdo

INTEGER, PARAMETER :: gs_hs = 200
REAL, PARAMETER :: deg2rad = 0.01745329, rad2deg = 57.29578, Rad = 6371000.

!...........................................................

NAMELIST/config/cfin,cvar,im,jm,km,cvlom,cvlam,&
       & io,jo,ko,cvmso,cvloo,cvlao,&
       & catt,cfmo,cvdm,cvdo,lcal,cunit,clnm

WRITE(*,*) ' Reading namelist'

open(12,FILE=TRIM(cnam),STATUS='OLD')
read(12,config)
close(12)

WRITE(*,*) ' Allocating field'
ALLOCATE(FLDI(im,jm))
ALLOCATE(MSKI(im,jm,km))
ALLOCATE(LONI(im))
ALLOCATE(LATI(jm))
ALLOCATE(DEPI(km))

ALLOCATE(FLDO(io,jo))
ALLOCATE(MSKO(io,jo,ko))
ALLOCATE(LONO(io,jo))
ALLOCATE(LATO(io,jo))
ALLOCATE(DEPO(ko))

WRITE(*,*) ' Reading field'
Call GETVAR(cfin,cvar ,im,jm,fldi)
Call GETVAR(cfin,cvlom,im,loni)
Call GETVAR(cfin,cvlam,jm,lati)
Call GETATT(cfin,cvar,catt,zmv)
Call GETATT(cfin,cvar,'add_offset'  ,zoff)
Call GETATT(cfin,cvar,'scale_factor',zscl)
Call GETVAR(cfin,cvdm,km,depi)

mski(:,:,:) = 1.
where ( fldi .eq. zmv ) mski(:,:,1) = 0.
write(*,*) ' Ocean points in input file :', 100. * sum(mski(:,:,1)) / real(im*jm)

fldi = fldi*zscl+zoff

WRITE(*,*) ' Reading field'
Call GETVAR(cfmo,cvmso,io,jo,ko,msko)
Call GETVAR(cfmo,cvloo,io,jo,lono)
Call GETVAR(cfmo,cvlao,io,jo,lato)
Call GETVAR(cfmo,cvdo ,ko,depo)

!...........................................................

fldo=0.
kf=0
kf2=0
allocate( pt(gs_hs*gs_hs*16) )
allocate(gsi(io,jo,ko))
allocate(gsj(io,jo,ko))
allocate(gsk(io,jo,ko))

! force it to true for 2d case
lcal = .true.

if(lcal) then
   gsi(:,:,:) = 0
   gsj(:,:,:) = 0
   gsk(:,:,:) = 0
endif

  kk = 1
  rk = 1.
 
  DO jj=1,jo

      ! if(mod(jj,10).eq.0) write(*,*) myt,':',jk,jj

      DO ji=1,io
      
         IF( msko(ji,jj,1) .gt. 0.5 ) THEN

                  ki = int( (lono(ji,jj)-loni(1))/abs( loni(2)-loni(1) ) ) + 1
                  kj = int( (lato(ji,jj)-lati(1))/abs( lati(2)-lati(1) ) ) + 1

                  lok = .false.
                  kk2 = 1

                  gsc : DO gs=1,gs_hs

                  kt = 0
                  ro = 1.e+12

                   DO kj2=max(1,kj-(gs-1)),min(jm,kj+gs)
                    DO ki2=max(1,ki-(gs-1)),min(im,ki+gs)

                      IF(mski(ki2,kj2,kk2 ).gt.0.5) then

                       kt = kt+1

                       xd = Rad*deg2rad*(lono(ji,jj)-loni(ki2))*cos(  deg2rad*(lato(ji,jj)+lati(kj2))/2 )
                       yd = Rad*deg2rad*(lato(ji,jj)-lati(kj2))
                       rd = sqrt( xd*xd+yd*yd ) 
                       IF(rd .lt. ro) then
                               ro = rd
                               gi = ki2; gj=kj2 
                       endif

                       endif

                    ENDDO
                   ENDDO

                  if( kt .gt. 0 ) then
                      fldo(ji,jj) = fldi(gi,gj)
                      lok = .true.
                      exit gsc
                  endif

                  enddo gsc
                  if(.not.lok) kf=kf+1

         ENDIF

      ENDDO

   ENDDO    

!...........................................................

WRITE(*,*) ' DONE! Number of failures> ',kf

call WRITE_VARNCDF('output.nc',io,jo,fldo,cvar,trim(cunit),trim(clnm))

END SUBROUTINE INTNN2

END PROGRAM MASTER
