c
      subroutine swap16(buf,n)        
c     f77 swap16 swaps the 2 bytes within each 16 bit word of array buf.
c  this routine is useful for converting dec 16 bit integers to other computer
c  integer formats (or vice versa).
c
c  arguments:
c     buf - the array to be converted.
c     n   - the number of 16 bit words to be converted.   integer*4
c
c  copyright: paul henkart, scripps institution of oceanography, 11 april 1982
c
      character*1 buf(1),a
c
      j=1
      do 200 i=1,n
      a=buf(j)
      buf(j)=buf(j+1)
      buf(j+1)=a
      j=j+2
  200 continue
      return
      end
