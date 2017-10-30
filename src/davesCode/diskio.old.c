/*  diskio is a set of entry points to do all diskio for large programs
 * where file keeping is a problem.  Diskio also does the actual i/o in an
 * efficient manner (not Fortran!), and also allows the user to position
 * within a file.
 *
 *    The following entry points are in this c program.
 * GETFIL(mode, lun, name, istat)   assigns disk files and unit numbers
 * FREFIL(mode, lun, istat)    frees or releases units
 * PODISC(lun, mode, nwrd)    positions lun to 32 bt word nwrd
 * RDDISC(lun, buffer, nwrds, istat)   reads nwrds 32 bit words from disk unit lun
 * WRDISC(lun, buffer, nwrds)    writes nwrds 32 bit words to disk unit lun
 * PODISCB(lun, mode, nwrd)    positions lun to 8 bt word nwrd
 * RDDISCB(lun, buffer, nwrds, istat)   reads nwrds 8 bit words from disk unit lun
 * WRDISCB(lun, buffer, nwrds)    writes nwrds 8 bit words to disk unit lun
 *
****   NOTE  ****   lun is an index to an array of file descriptors within this
                   subroutine, thus any I/O must be done through this subroutine
                   (since the other I/O doesn't have the file descriptor!)

c  Call GETFIL(MODE, LUN, NAME, ISTAT)
c
c     GETFIL KEEPS TRACK OF, AND OPTIONALLY ASSIGNS, DISK FILE UNIT NUMBERS.
C  THE PURPOSE IS TO ASSIGN UNIT NUMBERS TO SUBROUTINES AS THEY ARE NEEDED,
C  RATHER THAN EACH SUBROUTINE ASSIGNING A PARTICULAR NUMBER FOR A PARTICULAR
C  TASK, AND THUS NO OTHER ROUTINES BEING ABLE TO USE THAT UNIT NUMBER EVEN
C  THOUGH THE ORIGINAL TASK IS DONE.  MOST FORTRANS ALSO HAVE A LIMIT AS TO
C  THE LARGEST UNIT NUMBER ALLOWED, THUS GETFIL OPTIMIZES THE TOTAL NUMBER OF UNIT
C  NUMBERS USED IN A COMPUTER RUN.  FURTHER MOTIVATION FOR USE OF GETFIL IS THAT
C  SYSTEM CONFIGURATIONS ALLOW CERTAIN UNIT NUMBERS TO BE USED FOR SYSTEM
C  SOFTWARE AND THE POOR PROGRAMMER HAS TO KEEP TRACK OF WHAT THE SYSTEM USES
c  (such as stdin=0, stdout=1, errout=2).
C    GETFIL WILL FIND AN UNUSED UNIT NUMBER AND RETURN IT'S NUMBER, AS WELL AS
C  OPTIONALLY ASSIGNING A DISK FILE TO THE UNIT NUMBER.  A UNIT NUMBER CAN
C  BE OPTIONALLY RESERVED BUT NOT ASSIGNED TO A DISK FILE.
C     THE FILE ASSOCIATED WITH THE UNIT LUN WILL HAVE A NAME seis##, WHERE  ##
C  IS LUN.  WHEN REQUESTED, GETFIL CLOSES, DELETES, AND OPENS seis##.
C     FILES seis## MAY BE DELETED AND FILE UNIT NUMBERS RELEASED BY USING
C  SUBROUTINE FREFIL.
C  ARGUMENTS:
C   MODE   - THE TYPE OF DISK ASSIGNMENT TO MAKE. INTEGER*4
c          >0,  LUN is returned by GETFIL.
C          =1,  FINDS A FREE UNIT NUMBER AND RETURNS IT VIA LUN.
C               CREATE A NEW DISK FILE NAMED seis## AND START AT THE BEGINNING.
C          =2,  JUST RETURN A FREE UNIT NUMBER AND RESERVE IT SO THAT NO OTHER
C               CALL CAN USE IT.  DO NOT OPEN ANY FILES FOR IT.
C          =3,  FINDS A FREE UNIT NUMBER AND CREATES THE FILE GIVEN IN NAME TO
C               THE UNIT.  NAME MUST BE GIVEN.
c          =4,  Finds a free unit number and opens the existing file name. NAME
c               must be given.  The file is opened for reading and writing
c               unless permission is denied, in which case the file is opened
c               for reading only.
c          <0,  LUN must be specified by the calling routine.
C          =-1,  RESERVE UNIT NUMBER LUN ( LUN MUST BE SPECIFIED BY THE
C                CALLING ROUTINE) AND  CREATES THE FILE seis## FOR READING AND
c                WRITING.
C          =-2,  RESERVE UNIT NUMBER LUN. DO NOT OPEN ANY FILES.
c          =-3,  creates file name on unit lun. (both specified)
c          =-4,  opens file name on unit lun. (both must be specified)
C   LUN     - THE FILE UNIT NUMBER. INTEGER*4
C             LUN IS SET BY GETFIL WHEN MODE>0.
C             LUN MUST BE SET BY THE CALLING ROUTINE WHEN MODE<0.
C   NAME    - A CHARACTER FILE NAME ASSIGNED BY GETFIL THAT HAS BEEN ASSIGNED
C             ON LUN.  THIS IS RETURNED BY GETFIL.  Name must be at least 6
c             characters long  (character*6).
c   ISTAT   - The return status of the file assignment.

C           =-1, TOO MANY FILES ALREADY EXIST, UNIT NUMBER NOT RESERVED.
C           =-2, LUN IS ALREADY ASSIGNED.

  CALL FREFIL( MODE, LUN, ISTAT )
  Frefil releases and closes (with file marks at the current pointer) the file
associated with lun.  The file must have been assigned via GETFIL.  The file
may be (optionally) deleted (unlinked).

  arguments:
    mode  - The mode of freeing to perform.
          =-2,  Close the file on lun, do no release the unit (file descriptor).
          =-3,  Close and delete the file on lun.
          =1,  Release the unit, do not close or delete the file.
          =2,  Release the unit and close the file (do not delete it).
          =3,  Release the unit, close and delete the file.
          =4,  Release, close and delete all files opened by GETFIL.
    lun   - The logical unit number of the file
    istat - The return status of the file action.
          >=0, No problems.
          =-1, Invalid mode.
          =-2, Invalid lun.
          =-3, lun was not assigned.



  CALL PODISC( LUN, MODE, NWRD )
  PODISC ositions and open the disc file associated with lun.  The positioning
may be to an absolute word address or relative to the current file pointer.
  ARGUMENTS:
    LUN  - The unit number of the file to be positioned.
    MODE - The mode of positioning.
         =1, The file is positioned to the ABSOLUTE word address.
         =2, The file is positioned nwrd RELATIVE to the current file pointer.
    NWRD - The number of 4 byte words to postion to. The number of 32 words.


  CALL RDDISC( LUN, BUFFER, NWRDS, ISTAT )
  RDDISC reads nwrds 32bit words from the disc file associated with the file on
unit lun.  
  ARGUMENTS:
    LUN    - The logical unit number of the file to be read.
    BUFFER - The array to receive the results of the read.  Buffer must be at
             laest nwrds long.
    NWRDS  - TYhe number of words to read into buffer. Each words is 4 bytes.
             Nwrds*4 bytes will be read.
    ISTAT  - The return status of the read.
           >0, ISTAT words were read into buffer (No problems).
           =-1,  An end of file was detected.
           <-1, A problem occurred.


  CALL WRDISC( LUN, BUFFER, NWRDS)
  WRDISC write nwrds from buffer to disc file associated with lun.  If the
device is a tty, then write to it and hope that it is finished by the time
we do another (e.g. if a plot is sent to the C.ITOH printer we shall not
worry about the XONN/XOFF protocal - GETFIL sets TTY devices to raw mode).
  ARGUMENTS:
   LUN    - The logical unit number of the file to write to.
   BUFFER - The array in memory to write to disc.
   NWRDS  - The number of 32 bit words (4 byte words) to write to disc.


*/

#include <sgtty.h>
struct    sgttyb    term;  /*  if the device is a tty then it's not disk!  */


#define   MAXFDS    30  /* the most files allowed in UNIX */
#define   PMODE     0755 /* read, write, execute for owner, read and exec for group */

/* 0 is stdin
   1 is stdout
   2 is stderr
   5 is fortran reader
   6 is fortran printer
*/
static    int       fd[MAXFDS] = {0, 1, 2, -1, -1, 5, 6, -1, -1, -1, 
                                  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
                                  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
          long      offset;  /* the number of bytes to move relative to the origin */
          int       origin;
          char      fname[80];
          int       nread;
          int       nwrite;
          int       nbytes;
          int       status;
          int       i;

getfil_(mode, lun, name, istat)
          int       *mode;
          int       *lun;
          char      *name;
          int       *istat;

{
      if(*mode < 0 ) {   /* negative mode means the caller specifies the lun */
           if( *lun < 0 || *lun > MAXFDS ){   /* is it a legal lun? */
                 *istat = -1;
                 return; }
           if(*mode == -1 ) {
                 sprintf(name, "seis%d", *lun);
                 status = creat( name, PMODE );  /*  create for reading and writing */
                 close(status);
                 fd[*lun] = open(name,2);
                 status = 0;
                 if( fd[*lun] == -1 ) status = -1 ; }
           if(*mode == -2) {
                 fd[*lun] = *lun;
                 return ; } /* just reserve the unit number */
           if( *mode == -3 ) {  /* creat the file on the specified unit */
                 fd[*lun] = creat ( name, PMODE );  /* the fd may not be the same as lun! */
                 status = close(fd[*lun]);
                 status = 0;
                 fd[*lun] = open(name,2);   /* we could get a different fd! */
                 if( fd[*lun] == -1 ) status = -1 ;}
            if( *mode == -4 )  {
                 fd[*lun] = open ( name, 2);
                 if( fd[*lun] == -1 ) fd[*lun] = open( name, 0); 
                 if( fd[*lun] == -1 ) fd[*lun] = open( name, 1);
                 status = 0;
                 if( fd[*lun] == -1) status = -1 ; }
            if( status == 0 ) {
                 *istat = 0;
           /*      if( strcmp("/dev/tty", name) == 0 ) { 
                      printf(" modifying tty!!!");
                      ioctl( fd[*lun], TIOCGETP, &term);
                      term.sg_flags = EVENP | ODDP | RAW | XTABS;
                      ioctl( fd[*lun], TIOCSETN, &term); }
           */
                  return;}
            *istat = -3 ;
            perror("getfil");
            perror(name);
            return;
            }
       else {      /* find a free unit by searching fd for a -1 */
           *lun = -1;
           for (i = MAXFDS-1; fd[i] == -1 && i > 0; i--)  *lun = i;
           if ( *lun == -1 ){
               if( fd[3] == -1 ) *lun = 3;
                   else if( fd[4] == -1 ) *lun = 4 ;
               if(  *lun == -1) {
                   printf(" ***  ERROR  ***  Too many units for UNIX (30 max).\n");
                   *istat = -1;
                   return; }
                }
           if ( *mode == 2) {  /* =2 means just reserve the unit - don't open */
               fd[*lun] = *lun ;  /* set it to  something , but not -1 */
               return ; }
           if(*mode == 1 ) {
               sprintf(name, "seis%d", *lun) ;   /* create the name seis##  */
               status = creat( name, PMODE );
               close(status);
               status = open(name,2); }
           if( *mode == 3 ) {
                status = creat( name, PMODE );   /* open with read and write privileges */
                close(status);
                status = open(name,2);  }
           if( *mode == 4 ) { status = open( name, 2);
                if( status == -1 )  status = open( name, 0);  /* open it for read only if read and write fails */
                if( status == -1 ) status = open( name, 1); }  /* open for write only if read only failed */
           if( status != -1 ) {  /* if it created successfully, then carry on */
                fd[*lun] = status ;  /* create returns the file desriptor  */
                *istat = 0;  /* tell the caller that everything is ok */
       /*          if( strncmp("/dev/tty", name, 8 ) == 0 ) {
                      printf(" unit=%d",fd[*lun]);
                      printf(" modifying tty!!!");
                      ioctl( fd[*lun], TIOCGETP, &term);
                      term.sg_flags = EVENP | ODDP | RAW | XTABS;
                      ioctl( fd[*lun], TIOCSETN, &term);  }
        */
                return ;  }
           else  {   /* create didn't create! */
                    perror("getfil");
                    perror(name);
                    *istat = status ;
                    return ;  }
           }
}


frefil_( mode, lun, istat)
        int    *mode;
        int    *lun;
        int    *istat;

{
      if( *mode == -2) {   /* -2 means just close seis## - do not release the unit */
            status = close( fd[*lun] );
            return; }
      if( *mode == -3) {  /* -1 means close and delete seis## - don't release the unit number */
            status = close( fd[*lun] );
            sprintf( fname, "seis%d", *lun);
            unlink( fname );
            return; }
      if( *mode == 1) {   /* =1 means just to release the unit - don't close! */
            fd[*lun] = -1 ;
            return; }

      if( *mode == 2 )  {   /* =2 means release the unit number and close seis## */
            status = close( fd[*lun] );
            fd[*lun] = -1;
            return; }
      if( *mode == 3 ) {  /* =3 means relese, close and delete */
            status = close( fd[*lun] );
            fd[*lun] = -1 ;
            sprintf( fname, "seis%d", *lun);
            unlink( fname );
            return; }
      if( *mode == 4 )  { /*  =4 means release, close, delete all files */
            for ( i = 1; i < MAXFDS ; i++ ) {
                 status = close( fd[i] );
                 fd[i] = -1;
                 sprintf( fname, "seis%d", i );
                 unlink( fname ); }
            system("rm fort.*");
            return; }
}

podisc_( lun, mode, addres)
      int     *lun;
      int     *mode;
      int     *addres;

{
/*      printf(" podisc, lun=%d, mode=%d, addr=%d\n",*lun,*mode,*addres);  */
      offset = *addres * 4 ;  /* the addres was given in units of 4 bytes */
      origin = 0;  /* preset to origin of the beginning of the file */
      if( *mode == 2 ) origin = 1;   /* mode = 2 means relative to the current position */
      lseek( fd[*lun], offset, origin) ;
      return;
}


rddisc_(lun, buffer, nwrds, istat)
       int     *lun;
       int     *buffer;
       int     *nwrds;
       int     *istat;

{
       nbytes = *nwrds * 4 ;  /* nwrds is the number of 4 byte words to read */
       status = read( fd[*lun], buffer, nbytes);
/*       printf(" rddisc, lun=%d, nwrds=%d, status=%d\n",*lun,*nwrds,status); */
       if( status < 0 ) {
              printf(" ***  ERROR  ***  disc file read error on unit %d, status = %d\n",*lun,status);
              perror("rddisc");
              *istat = status ; }
       else *istat = status / 4 ;  /* convert the number of bytes read to words */
       *istat = status / 4;
       if ( *istat == 0 ) *istat = -1 ;  /* istat=-1 means end of file  */
       return;
}

wrdisc_(lun, buffer, nwrds)
       int     *lun;
       int     *buffer;
       int     *nwrds;

{
/*       printf(" wrdisc, lun=%d, nwrds=%d\n",*lun,*nwrds);  */
       nbytes = *nwrds * 4 ;  /* nwrds is the number of 4 byte words to write */
       status = write( fd[*lun], buffer, nbytes);
       if( status != nbytes ) {
             printf(" ***  ERROR  ***  disc file write error on unit %d, status = %d\n",*lun,status);
             perror("wrdisc"); }
       return;
}

podiscb_( lun, mode, addres)
      int     *lun;
      int     *mode;
      int     *addres;

{
/*      printf(" podisc, lun=%d, mode=%d, addr=%d\n",*lun,*mode,*addres);  */
      offset = *addres  ;  /* the addres was given in units of bytes */
      origin = 0;  /* preset to origin of the beginning of the file */
      if( *mode == 2 ) origin = 1;   /* mode = 2 means relative to the current position */
      lseek( fd[*lun], offset, origin) ;
      return;
}


rddiscb_(lun, buffer, nbytes, istat)
       int     *lun;
       int     *buffer;
       int     *nbytes;
       int     *istat;

{
       nread = *nbytes ;  /* nread is the number of bytes to read */
       status = read( fd[*lun], buffer, nread);
/*       printf(" rddisc, lun=%d, nbytes=%d, status=%d\n",*lun,*nbytes,status); */
       if( status < 0 ) {
              printf(" ***  ERROR  ***  disc file read error on unit %d, status = %d\n",*lun,status);
              perror("rddisc");
              *istat = status ; }
       else *istat = status  ;  /* convert the number of bytes read to words */
       *istat = status ;
       if ( *istat == 0 ) *istat = -1 ;  /* istat=-1 means end of file  */
       return;
}

wrdiscb_(lun, buffer, nbytes)
       int     *lun;
       int     *buffer;
       int     *nbytes;

{
/*       printf(" wrdisc, lun=%d, nbytes=%d\n",*lun,*nbytes);  */
       nwrite = *nbytes ;  /* nwrite is the number of bytes to write */
       status = write( fd[*lun], buffer, nwrite);
       if( status != nwrite ) {
             printf(" ***  ERROR  ***  disc file write error on unit %d, status = %d\n",*lun,status);
             perror("wrdisc"); }
       return;
}

/* end */
