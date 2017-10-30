
      program img2xyt
c
c  program to extract a sub array from an integer*2 Mercator grid
c
      common /grid/nlt,nln,dlt,dln,iproj
      common /bounds/rlt0,rltf,rln0,rlnf,rlnm
      common/info/lcrt(2),lin(10),nin,lout(10),nout
      integer*2 iin(10800) 
c
c  open the input file
c
      call inioc(lu1)
c
c  setup the grid parameters for a 2 minute grid
c
      idln=2
      nln=10800
      nlt=6336
      rlt0=-72.006
      rln0=0.
      dln=idln/60.
      dlt=0.
      rland=998.
      rdum=999.
      iproj=2
      write (*,901)
 901  format(' enter bounds for output grid: ',/,
     +         ' south, north, west, east :',$)
 100  read(*,*)slt0,sltf,sln0,slnf
      if(slt0.ge.sltf.or.sln0.ge.slnf) then
        write(*,'(a)')' rlt0 < rltf and rln0 < rlnf '
        go to 100
      endif
c
c  get all of the data or just the hits
c
      ihit=0
      write(*,903)
 903  format(/,' enter (0) for every grid point and',/,
     + ' enter (1) for only measured depths:',$)
      read(*,*)ihit
c
c   compute the starting and ending indices
c
      i180=0
      call mercator(sltf,sln0,i00,j00,1)
      call mercator(slt0,slnf,iff,jff,1)
      if(j00.lt.1) then
        j00=j00+nln
        jff=jff+nln
        i180=1
      endif
      write(*,*)sln0,j00,slnf,jff
c
c  make sure jff is greater than j00
c
      if(jff.lt.j00) jff=jff+nln
c
c  make sure the corners are within the box
c
      if(i00.eq.-1)i00=1
      if(iff.eq.-1)iff=nlt
      if(j00.eq.-1)j00=1
      if(jff.eq.-1)jff=nln
      njout=jff-j00+1
      niout=iff-i00+1
c
c open the output file
c
      call outio(lu2)
c
c jump to the correct row
c
      ntot=0
      call podiscb(lu1,1,2*nln*(i00-1))
      do 200 i=i00,iff
      call rddiscb(lu1,iin,2*nln,istat)
      if(istat.lt.0) then
        write(lcrt(2),'(a)')' Problem reading input file '
        stop
      endif
      if(i.ge.i00.and.i.le.iff) then
      do 150 j=j00,jff
c
c  skip empty cells
c
      jj=1+mod(j-1+nln,nln)
      idat=iin(jj)
      itest=abs(mod(idat,2))
      if(ihit.eq.1.and.itest.eq.0) go to 150
      call mercator(rltt,rlnt,i,jj,-1)
      topo=idat
c
c  write out latitude, longitude and topography (meters)
c
      ntot=ntot+1
      if(i180.eq.1.and.rlnt.gt.180) rlnt=rlnt-360.
      write(lu2,*)rlnt,rltt,topo
  150 continue
      endif
 200  continue
      call closio(-1)
      write(*,902)ntot
 902  format(' # of records for output file ',i8)
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
c remember: 
c a) pixel #1 is at lon=0, 
c b) pixel "#0" doesn't exist; it's really the last pixel, "#nln"
c c) but if pixel #0 did exist, it would be the first negative lon, 
	j=(rln1-rln0)/dln
c	write(*,*)rln0,rln1,j
	if ((rln1-rln0).ge.0) j=j+1
c	write(*,*)j
c
c  check to see if the point lies to the left of the box
c
        if(j.lt.1) then
        	rln1=rln1+360.
        	if(rln1.le.rlnf) go to 20
        endif
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
