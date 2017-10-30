      program interp_ship
c
c  interpolates a profile through a global mercator image grid
c
      parameter (nltmx=6336,nlnmx=10800)
      integer*2 idata(nlnmx,nltmx)
      real*4    drec(20)
      integer*2 iin(nlnmx),latfn,lonfn,tfn
      common/info/lcrt(2),lin(10),nin,lout(10),nout
      common/grid/nlat,nlon,rdlt,rdln,iproj
      common/bounds/rlt0,rltf,rln0,rlnf,rlnm
c
c  open the input and output files
c
      write(*,*)' Input File  containing points to be interpolated'
      call inio(lui)
      write(*,*) 
      write(*,*)' Lon field #, Lat field #, Total # fields  (eg  2,3,8)'
      read*,lonfn,latfn,tfn
      write(*,*)
      write(*,*)' enter scale factor (0.1-gravity) (1-topography): '
      read(*,*) scale
      write(*,*)
      write(*,*)' Output File'
      call outio(luo)
      write(*,*)
c
c  setup the grid parameters

      nlon=10800
      nlat=6336
      rlt0=-72.006
      rltf=72.006
      rln0=0.
      rlnf=360.
      rdln=0.033333333
      rdlt=0.
      rland=998.
      rdum=999.
c
c Open & Read the Grid File
c
      write(*,*)' Grid File '
      call inioc(lub)
      write(*,*)
      write(*,*)'   Reading the grid...'
      write(*,*)
      iproj=2
      if(nlat.gt.nltmx.or.nlon.gt.nlnmx) then
        write(*,901)
 901    format('***** increase nltmx or nlnmx')
        stop
      endif
      do 101 i=1,nlat
      call rddiscb(lub,iin,2*nlon,istat)
      if(istat.lt.0) then
        write(lcrt(2),'(a)')' Problem reading input file '
        stop
      endif
      do 99 j=1,nlon
      idata(j,i)=iin(j)
  99  continue
 101  continue
      icall=1
 100  read(lin(1),*,end=999)(drec(ii),ii=1,tfn)
      rln = drec(lonfn)
      if(rln.lt.0.) rln=rln+360.
      rlt = drec(latfn)

c
c  get the indices of the closest mercator point
c
      call mercator(rlt,rln,im,jm,1)
      if(im.eq.-1.or.jm.eq.-1) go to 100
c
c determine the lat and lon of the closest mercator point
c
      call mercator(rltm,rlnm,im,jm,-1)
c
c find the 4 mercator points bounding the output point.
c
      iclosest=0
      if(rlt.lt.rltm) then
        im1=im
        rlt1=rltm
        im2=im+1
        call mercator(rlt2,rdum,im2,jm,-1)
        if(rlt2.eq.-999.) iclosest=1
      else
        im1=im-1
        call mercator(rlt1,rdum,im1,jm,-1)
        if(rlt1.eq.-999.) iclosest=1
        im2=im
        rlt2=rltm
      endif
      if(rln.gt.rlnm) then
        jm1=jm
        rln1=rlnm
        jm2=jm+1
        call mercator(rdum,rln2,im,jm2,-1)
        if(rln2.eq.-999.) iclosest=1
      else
        jm1=jm-1
        call mercator(rdum,rln1,im,jm1,-1)
        if(rln1.eq.-999.) iclosest=1
        jm2=jm
        rln2=rlnm
      endif
c
c  if one point is outside of grid do a closest point
c  interpolation
c
      if(iclosest.eq.1) then
        grav=idata(jm,im)/10.
        write(lcrt(2),'(a)')' **closest point interpolation** '
      else
c
c  read 4 points and convert to float mgal
c 
        idat=idata(jm1,im1)
        itest=iabs(mod(idat,2))
        dat11=(idat-itest)*scale
        idat=idata(jm1,im2)
        itest=iabs(mod(idat,2))
        dat21=(idat-itest)*scale
        idat=idata(jm2,im1)
        itest=iabs(mod(idat,2))
        dat12=(idat-itest)*scale
        idat=idata(jm2,im2)
        itest=iabs(mod(idat,2))
        dat22=(idat-itest)*scale
c
c  do the interpolation
c
        t=(rln-rln1)/(rln2-rln1)
        if(t.lt.0.or.t.gt.1.) then
          write(lcrt(2),'(a)')' **** error t out of range '
          stop
        endif
        u=(rlt-rlt2)/(rlt1-rlt2)
        if(u.lt.0.or.u.gt.1.) then
          write(lcrt(2),'(a)')' **** error u out of range '
          stop
        endif
        do 150 k=2,5
        grav=(1.-t)*(1.-u)*dat21 + t*(1.-u)*dat22 +
     1        t*u*dat12 + (1.-t)*u*dat11
  150   continue
      endif

      drec(tfn+1)=grav
      write(lout(1),*)(drec(ii),ii=1,tfn+1)
  902 format(20g14.7)
      go to 100
c
c  exit the program
c
 999  call closio(-1)
      stop
      end
c
      subroutine mercator(rlt,rln,i,j,icall)
c
c  routine to compute the indices i,j associated with the
c  mercator projection of rlt,rln.
c
c  input
c   rlt   -   latitude (deg)
c   rln   -   longitude (deg)
c   icall -   0-set up grid parameters
c             1-calculate index i, j from rlt, rln
c            -1-calculate rlt, rln from index i, j
c
c output
c   i     -   row of matrix for rlt
c   j     -   column of matrix for rln 
c
      common /grid/nlt,nln,dlt,dln,iproj
      common /bounds/rlt0,rltf,rln0,rlnf,rlnm
      common /info/lcrt(2),lin(10),nin,lout(10),nout
      data rad /.0174533/
      save arg,rad
c
c  if icall equals 0 then get location parameters
c
      if(icall.eq.0) then
      write(lcrt(2),900)
  900 format(' # of lat, # of lon (both even): ',$)
      read(lcrt(1),*)nlt,nln
      write(lcrt(2),901)
  901 format(' minimum latitude: ',$)
      read(lcrt(1),*)rlt0
      write(lcrt(2),902)
  902 format(' minimum longitude, long. spacing (deg): ',$)
      read(lcrt(1),*)rln0,dln
      rlnf=rln0+dln*nln
c
c  check to see if the left side of the box is negative
c  and add 360. if it's true.
c
      if(rln0.lt.0.) then
      rln0=rln0+360.
      rlnf=rlnf+360.
      endif
c
c  compute the maximum latitude
c
      arg=alog(tan(rad*(45.+rlt0/2.)))
      arg2=rad*dln*nlt+arg
      term=exp(arg2)
      rltf=2.*atan(term)/rad-90.
c
c  print corners of area
c
      write(lcrt(2),903)
 903  format('  corners of area  ')
      write(lcrt(2),904)rltf,rln0,rltf,rlnf
      write(lcrt(2),904)rlt0,rln0,rlt0,rlnf
  904 format(2f9.4,6x,2f9.4)
      write(lcrt(2),905)
  905 format(' continue?  1-yes  0-no: ',$)
      read(lcrt(1),*)iyes
      if(iyes.eq.0)stop
      return
      endif
c
c compute the indices of the point
c
      if(icall.eq.1) then
        rln1=rln
        arg1=alog(tan(rad*(45.+rlt0/2.)))
        arg2=alog(tan(rad*(45.+rlt/2.)))
        i=nlt+1-(arg2-arg1)/(dln*rad)
        if(i.lt.1.or.i.gt.nlt) i=-1
  20    continue
        j=(rln1-rln0)/dln+1
        j2=j
c
c  check to see if the point lies to the left of the box
c
        if(j2.lt.1) then
        rln1=rln1+360.
        if(rln1.le.rlnf)go to 20
        endif
        if(j.lt.1.or.j.gt.nln) j=-1
      else
c
c  compute latitude and longitude
c
        if(i.lt.1.or.i.gt.nlt) then
        rlt=-999.
        return
        endif
        if(j.lt.1.or.j.gt.nln) then
        rln=-999.
        return
        endif
        arg1=rad*dln*(nlt-i+.5)
        arg2=alog(tan(rad*(45.+rlt0/2.)))
        term=exp(arg1+arg2)
        rlt=2.*atan(term)/rad-90.
        rln=rln0+dln*(j-.5)
      endif
      return
      end
c
c          Copyright 1988
c          David T. Sandwell
c
c***********************************************************************
      subroutine inio(lu)
c***********************************************************************
c
c   routine to open a read-only sequential file and
c   assign a logical unit #, lu. the file must already
c   exist.
c
c***** calls no other routines
c
      character*80 name
      common/info/lcrt(2),lin(10),nin,lout(10),nout
      data lu0,lus,luf/9,10,20/
      save lu0,lus,luf
c
c  get the file name
c
      write(lcrt(2),901)
  901 format(' enter input filename: ',$)
      read(lcrt(1),903) name
  903 format(a80)
c
c  increment lus and open a file
c
      if(nin.gt.0) lus=lin(nin)+1
      if(lus.gt.lu0.or.lus.lt.luf) then
      open(unit=lus,file=name,err=9000,status='old')
      lu=lus
      nin=nin+1
      lin(nin)=lu
      else
      write(lcrt(2),902)lus
 902  format(' lu is out of range ',i10)
      endif
      return
c
c  could not open file
c
 9000 continue
      write(lcrt(2),*)' could not open ',name
      lu=-lus
      return
      end
c
c          Copyright 1988
c	   David T. Sandwell
c
c***********************************************************************
      subroutine inioc(lu)
c***********************************************************************
c
c   routine to open a read-only direct-access binary file 
c   using the diskio routine.  The routine assigns a
c   free logical unit number
c
c***** calls no other routines
c
      character*80 name
      common/info/lcrt(2),lin(10),nin,lout(10),nout
c
c  get the file name
c
      write(lcrt(2),901)
  901 format(' enter direct-access input filename: ',$)
      read(lcrt(1),903) name
  903 format(a)
c
c  open the file
c
      nc=index(name,' ')
      name(nc:nc)='\0'
      call getfil(4,lu,name,istat)
      if(istat.lt.0) go to 9000
      nin=nin+1
      lin(nin)=lu
      return
c
c  could not open file
c
 9000 continue
      write(lcrt(2),*)' could not open ',name
      return
      end
c
c          Copyright 1988
c	   David T. Sandwell
c
c***********************************************************************
      subroutine outio(lu)
c***********************************************************************
c
c   routine to open a read-write sequential file and
c   assign a logical unit #, lu.
c
c***** calls no other routines
c
      character*80 name
      common/info/lcrt(2),lin(10),nin,lout(10),nout
      data lu0,lus,luf/19,20,30/
      save lu0,lus,luf
c
c  get the file name
c
      write(lcrt(2),901)
  901 format(' enter output filename: ',$)
      read(lcrt(1),903) name
  903 format(a80)
c
c  increment lus and open a file
c
      if(nout.gt.0)lus=lout(nout)+1
      if(lus.gt.lu0.or.lus.lt.luf) then
      open(unit=lus,file=name,err=9000)
      lu=lus
      nout=nout+1
      lout(nout)=lu
      else
      write(lcrt(2),902)lus
 902  format(' lu is out of range ',i10)
      endif
      return
c
c  could not open file
c
 9000 continue
      write(lcrt(2),*)' could not open ',name
      lu=-lus
      return
      end
c
c          Copyright 1988
c	   David T. Sandwell
c
c***********************************************************************
      subroutine closio(lu)
c***********************************************************************
c
c  closes logical unit # lu if lu>0
c  closes all open lu's if lu<0.
c 
c***** calls no frefil
c
      common/info/lcrt(2),lin(10),nin,lout(10),nout      
      if(lu.gt.0) then
      call frefil(2,lu,istat)
      if(istat.lt.0) close(unit=lu)
      else
      imax=max(nin,nout)
      do 10 i=1,imax
      if(lin(i).ne.5) then
c
c  try to close a c file first
c
      call frefil(2,lin(i),istat)
      if(istat.lt.0) close(unit=lin(i))
      endif
      if(lout(i).ne.6) then
      call frefil(2,lout(i),istat)
      if(istat.lt.0) close(unit=lout(i))
      endif
  10  continue
      nin=0
      nout=0
      endif
      return
      end
c
      block data luio
c
c  common blocks for logical unit # transfers.
c
      common/info/lcrt(2),lin(10),nin,lout(10),nout
c
c   lcrt(1)  -  lu for terminal read.
c   lcrt(2)  -  lu for terminal write.
c   lin(i)   -  i'th input file lu (10-19 only).
c   nin      -  # of input files opened.
c   lout(i)  -  i'th output file lu (20-29 only).
c   nout     -  # of output files opened.
c
c***** calls no other routines
c
      data lcrt/5,6/
      data lin,nin/10*5,0/
      data lout,nout/10*6,0/
      end
