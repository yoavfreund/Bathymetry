#include <stdlib.h>
#include <string.h>

#define osx	1  /* Mac OSX   */
#define linux   0  /* Linux needs to set to 1 */
#define	hp	0  /* must be set 1 on HP computers	*/
#define sgi     0  /* must be set 1 on SGI - SGI doesn't have creat64 */
#define sun	0  /* 1 if SunOS	*/
#define debug   0 /* set to 1 to get debug print statements */

/* set tabstop=6  */
/*  diskio is a set of entry points to do all diskio for large programs
 * where file keeping is a problem.  Diskio also does the actual i/o in an
 * efficient manner (not Fortran!), and also allows the user to position
 * within a file.
 *
 *    The following entry points are in this c program.
 * GETFIL(mode, lun, name, istat)   assigns disk files and unit numbers
 * GETFIL64(mode, lun, name, istat) needed in some machines for files > 2GB
 * FREFIL(mode, lun, istat)    frees or releases units
 * PODISC(lun, mode, nwrd)    positions lun to 32 bit word nwrd
 * PODISC64(lun, mode, nwrd) positions lun to 32 bit word nwrd, nwrd is 64bits
 * RDDISC(lun, buffer, nwrds, istat)   reads nwrds 32 bit words from disk unit lun
 * WRDISC(lun, buffer, nwrds)    writes nwrds 32 bit words to disk unit lun
 * PODISCB64(lun, mode, nbyte) positions lun to byte nbyte, nbyte is 64 bits
 * RDDISCB(lun, buffer, nbytes, istat)   reads nbytes bytes from disk unit lun
 * WRDISCB(lun, buffer, nbytes)    writes nbytes bytes to disk unit lun
 * FILSIZ( name, isize )  return the size of the file name
 * GETDIR( name, istat )  return the current path
 * GODIR( name, istat ) Change directories (cd) to name
 * ADRDISC( lun, address ) Return the current disk address.
 * ADRDISC64( lun, address ) Return the current disk address (2 32bit words).
 * FDSYNC( lun ) - Calls fsync (synchronize a file's in-memory state )
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
C     THE FILE ASSOCIATED WITH THE UNIT LUN WILL HAVE A NAME sioseis_tmp##, WHERE  ##
C  IS LUN.  WHEN REQUESTED, GETFIL CLOSES, DELETES, AND OPENS sioseis_tmp##.
C     FILES sioseis_tmp## MAY BE DELETED AND FILE UNIT NUMBERS RELEASED BY USING
C  SUBROUTINE FREFIL.
C  GETFIL ARGUMENTS:
C   MODE   - THE TYPE OF DISK ASSIGNMENT TO MAKE. INTEGER*4
c          >0,  LUN is returned by GETFIL.
C          =1,  FINDS A FREE UNIT NUMBER AND RETURNS IT VIA LUN.
C               CREATE A NEW DISK FILE NAMED sioseis_tmp## AND START AT THE BEGINNING.
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
C                CALLING ROUTINE) AND  CREATES THE FILE sioseis_tmp## FOR READING AND
c                WRITING.
C          =-2,  RESERVE UNIT NUMBER LUN. DO NOT OPEN ANY FILES.
c          =-3,  creates file name on unit lun. (both specified)
c          =-4,  opens file name on unit lun. (both must be specified)
C   LUN     - THE FILE UNIT NUMBER. INTEGER*4
C             LUN IS SET BY GETFIL WHEN MODE>0.
C             LUN MUST BE SET BY THE CALLING ROUTINE WHEN MODE<0.
C   NAME    - A CHARACTER FILE NAME ASSIGNED BY GETFIL THAT HAS BEEN ASSIGNED
C             ON LUN.  THIS IS RETURNED BY GETFIL.  DISKIO will generate
c             a 6 character name for mode 1.  DISKIO forces the string by
c             to terminate will a NULL, as is required in C, by putting
c             a NULL in the first blank in the string.
  ****   FORTRAN users must terminate the name with a blank   ******
c   ISTAT   - The return status of the file assignment.
            =0, File opened properly.

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
          =4,  Release, close and delete all SCRATCH files opened by
               GETFIL mode 1.
    lun   - The logical unit number of the file
    istat - The return status of the file action.
          >=0, No problems.
          =-1, Invalid mode.
          =-2, Invalid lun.
          =-3, lun was not assigned.



  CALL PODISC( LUN, MODE, NWRD )
  CALL PODISCB( LUN, MODE, NBYTE )
  PODISC positions and open the disc file associated with lun.  The positioning
may be to an absolute address or relative to the current file pointer.
The first address is 0, the second adress is 1, etc.
  ARGUMENTS:
    LUN  - The unit number of the file to be positioned.
    MODE - The mode of positioning.
         =1, The file is positioned to the ABSOLUTE word address.
         =2, The file is positioned nwrd RELATIVE to the current file pointer.
    NWRD - The number of 4 byte words to postion to. The number of 32 words.
    NBYTE - The byte number to postion to. 


  CALL RDDISC( LUN, BUFFER, NWRDS, ISTAT )
  CALL RDDISCB( LUN, BUFFER, NBYTES, ISTAT )
  RDDISC reads nwrds 32bit words from the disc file associated with the file on
unit lun.  
  RDDISCB reads nbytes from the disc file associated with the file on
unit lun.  
  ARGUMENTS:
    LUN    - The logical unit number of the file to be read.
    BUFFER - The array to receive the results of the read.  Buffer must be at
             laest nwrds long.
    NWRDS  - The number of words to read into buffer. Each words is 4 bytes.
    NBYTES - The number of bytes to read into buffer.
    ISTAT  - The return status of the read.
           >0, ISTAT words/bytes were read into buffer (No problems).
           =-1,  An end of file was detected.
           <-1, A problem occurred.


  CALL WRDISC( LUN, BUFFER, NWRDS)
  CALL WRDISCB( LUN, BUFFER, NBYTES)
  WRDISC writes nwrds from buffer to disc file associated with lun.
  WRDISCB writes nbytes bytes from buffer to disc file associated with lun.
If the device is a tty, then write to it and hope that it is finished by the time
we do another (e.g. if a plot is sent to the C.ITOH printer we shall not
worry about the XONN/XOFF protocal - GETFIL sets TTY devices to raw mode).
  ARGUMENTS:
   LUN    - The logical unit number of the file to write to.
   BUFFER - The array in memory to write to disc.
   NWRDS  - The number of 32 bit words (4 byte words) to write to disc.
   NBYTES  - The number of bytes to write to disc.

Where has the copyright gone?
Where has the mod history gone?

Copyright (C) by The Regents of The University of California, 1980
Written by Paul Henkart, Scripps Institution of Oceanography, La Jolla, Ca.
All Rights Reserved.

mod 29 June 1995 - block unit 7 because of HPUX Fortran.
mod 3 Aug 98 - When file can't be opened in getfil, set fd[*lun]
    to the unit number and set *lun to 0
mod Mar 99 - Keep track of the file names in char array fname so that
     unlink works!
mod May 99 - Add new entries filsiz, getdir, godir - Rudolf Widmer-Schnidrig
mod May 99 - Try to open as a large file (>2GB) if open fails.
           - Add getfil64 to open or create as a largefile.
           - Add adrdisc
mod Sep 99 - mkname barfed on inserting \0 when the file name was a constant
mod Dec 99 - Bah Humbug.  Change frefil unlink to rm sioseis_tmp%d
mod Oct 00 - DLz, added subroutines podisc64, podiscb64 to use 64-bit 
             addresses to position the disk
mod Apr 02 - Add #include <unistd.h> and SEEK_CUR, SEEK_SET
mod Jul 02 - Add define osx and define debug
mod Jul 02 - Add PMODE_ALL so tmp files can be deleted by everybody
mod 23 Oct 02 - Add fsync to "sync" or force write the buffer.
mod 19 May 03 - getfil64 mode 3 needs close after creat so it can be
                read as well as written.
*/

/* #include <sgtty.h>
	struct    sgttyb    term; */ /*  if the device is a tty then it's not disk!  */
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>


#define   MAXFDS    40  /* the most files allowed in UNIX */
#define   PMODE     0755 /* read, write, execute for owner, read and exec for group */
#define	PMODE_ALL	0777 /* read, write, execute for everybody  */
void mknamec( nam )
	char 	*nam;
{
	while( *nam != ' ' && *nam != '\0' ) *nam++;  /* find a blank or the end */
        *nam = '\0';
}

/* 0 is stdin
   1 is stdout
   2 is stderr
   5 is fortran reader
   6 is fortran printer
   7 HPUX fortran has problems with opening unit 7 'UNFORMATTED'
*/
static    int       fd[MAXFDS] = {0, 1, 2, -1, -1, 5, 6, 7, -1, -1,
                               -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                               -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                               -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
static	int	nbits[MAXFDS] = { 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 
						32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 
						32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 
						32, 32, 32, 32, 32, 32, 32, 32, 32, 32 };
static	int	reserved[MAXFDS] = {0, 1, 2, -1, -1, 5, 6, 7, -1, -1,
                               -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                               -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                               -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
static	long      offset;  /* the number of bytes to move relative to the origin */
#if !osx && !linux
	off64_t   offset64;
#else
	off_t	offset64;
#endif
static	int	nbit=32;
static	int       origin;
static	char      fname[80][MAXFDS];
static	char      tname[80];
static	int       nbytes;
static	long       status;
static	int       i;
static	struct    stat	stbuf;

#if hp
     void getfil64(mode, lun, name, istat)
#else
     void getfil64_(mode, lun, name, istat)
#endif
          int       *mode;
          int       *lun;
          char      *name;
          int       *istat;
{
#if debug
	printf("getfil64, mode= %d, lun= %d\n",*mode,*lun);
#endif
	nbit = 64;
	*istat = 0;
	*lun = -1;
	for (i = MAXFDS-1; fd[i] == -1 && i > 0; i--)  *lun = i;
	if ( *lun == -1 ){
	if( fd[3] == -1 ) *lun = 3;
	else if( fd[4] == -1 ) *lun = 4 ;
	if(  *lun == -1) {
		printf(" ***  ERROR  ***  Too many units for getfil64 (%d max).%d\n",MAXFDS,*mode);
		*istat = -1;
		exit(0) ; }
	}
	nbits[*lun] = 64;
	if(*mode == 1 ) {
		sprintf(name, "sioseis_tmp%d\0", *lun);
#if sgi || osx
		status = creat( name, PMODE_ALL );
#else
		status = creat64( name, PMODE_ALL );
#endif
		close(status);
		strcpy(fname[*lun],name);
#if !osx
		status = open64(name,2);
#else
		status = open(name,2);
#endif
	}
	if( *mode == 3 ) {
		strcpy(tname,name);
		mknamec( tname );
#if sgi || osx
		status = creat( tname, PMODE );
#else
		status = creat64( tname, PMODE );
#endif
		close(status);
#if !osx
		open64(tname,2);
#else
		open(tname,2);
#endif
		fd[*lun] = status;
		strcpy(fname[*lun],tname);
	}
	if( *mode == 4 ) {
		strcpy(tname,name);
		mknamec( tname );
#if !osx
		status = open64( tname, 2);
		if( status == -1 ) status = open64( tname, 0);
		if( status == -1 ) status = open64( tname, 1);
#else
		status = open( tname, 2);
		if( status == -1 ) status = open( tname, 0);
		if( status == -1 ) status = open( tname, 1);
#endif
	}
#if debug
	printf("getfil64 status= %d, lun= %d\n",status,*lun);
#endif
	if( status != -1 ) {
		fd[*lun] = status;
		strcpy(fname[*lun],tname);
		*istat = 0;
		return;
	}else{
		perror(name);
		*lun = -1;
		*istat = status;
		return;
	}
}




#if hp
	void getfil(mode, lun, name, istat)
#else
	void getfil_(mode, lun, name, istat)
#endif
          int       *mode;
          int       *lun;
          char      *name;
          int       *istat;

{
      *istat = 0;
#if debug
	printf("getfil, nbit= %d, mode= %d, lun= %d\n",nbit,*mode,*lun);
#endif
      if(*mode < 0 ) {   /* negative mode means the caller specifies the lun */
		if( *lun < 0 || *lun > MAXFDS ){   /* is it a legal lun? */
			printf("Bad disk unit number of %d\n",*lun);
			exit(0) ; }
		if( nbit == 64 ) nbits[*lun] = 64;
		if(*mode == -1 ) {
			sprintf(name, "sioseis_tmp%d", *lun);
			status = creat( name, PMODE_ALL ); /* read and write */
			close(status);
			status = open(name,2); }
		if(*mode == -2) {
			fd[*lun] = *lun;
			return ; } /* just reserve the unit number */
		if( *mode == -3 ) {  /* creat the file on the specified unit */
			strcpy(tname,name);
			mknamec( tname ); /* make sure the name terminates with a NULL */
			fd[*lun] = creat ( tname, PMODE );
			status = close(fd[*lun]);
			status = open(tname,2);} /* might be a different fd! */
		if( *mode == -4 )  {
			strcpy(tname,name);
			mknamec( tname ); /* make sure the name terminates with a NULL */
			status = open ( tname, 2);
			if( status == -1 ) status = open( tname, 0); 
			if( status == -1 ) status = open( tname, 1);
			if( status == -1 ) {
/*		printf("wouldn't open as a small file, trying as a big file.\n");*/
#if !osx
				status = open64( tname, 2);
				if( status == -1 ) status = open64( tname, 0);
				if( status == -1 ) status = open64( tname, 1);
#else
				status = open( tname, 2);
				if( status == -1 ) status = open( tname, 0);
				if( status == -1 ) status = open( tname, 1);
#endif
				if( status >0 ) nbits[*lun] = 64;
			}
			if( status != -1 ) stat( tname, &stbuf );  /* get the status and file size */
#if debug
			printf("lun= %d, status=%d, nbits[*lun]= %d, tbuf.st_size = %x\n",
			*lun,status,nbits[*lun],stbuf.st_size); 
#endif
			if( status != -1 && nbits[*lun] == 32 && (stbuf.st_size > 2147483647 || stbuf.st_size < 0 )) {
/*		printf("it was opened, but it's a big file!\n");*/
				status = close( fd[*lun] );
#if !osx
				status = open64( name, 2);
				if( status == -1 ) status = open64( name, 0);
				if( status == -1 ) status = open64( name, 1);
#else
				status = open( name, 2);
				if( status == -1 ) status = open( name, 0);
				if( status == -1 ) status = open( name, 1);
#endif
				if( status >0 ) nbits[*lun] = 64;
			}
		}
		fd[*lun] = status;
		strcpy(fname[*lun],name);
		if( fd[*lun] == -1 ) status = -1 ;
		if( status > 0 ) {
			*istat = 0;
           /*      if( strcmp("/dev/tty", name) == 0 ) { 
                      printf(" modifying tty!!!");
                      ioctl( fd[*lun], TIOCGETP, &term);
                      term.sg_flags = EVENP | ODDP | RAW | XTABS;
                      ioctl( fd[*lun], TIOCSETN, &term); }
           */
			return;}
		*istat = -3 ;
		perror(name);
		return; }
       else {      /* find a free unit by searching fd for a -1 */
           *lun = -1;
           for (i = MAXFDS-1; fd[i] == -1 && i > 0; i--)  *lun = i;
           if ( *lun == -1 ){
               if( fd[3] == -1 ) *lun = 3;
                   else if( fd[4] == -1 ) *lun = 4 ;
               if(  *lun == -1) {
                   printf(" ***  ERROR  ***  Too many units for getfil (%d max).%d\n",MAXFDS,*mode);
                   *istat = -1;
                   exit(0) ; }
           }
           if ( *mode == 2) {  /* =2 means just reserve the unit - don't open */
               fd[*lun] = 99 ;  /* set it to  something , but not -1 */
               return ; }
           if(*mode == 1 ) {
               sprintf(name, "sioseis_tmp%d", *lun) ;   /* create the name sioseis_tmp##  */
			status = creat( name, PMODE_ALL );
               close(status);
               strcpy(fname[*lun],name);
			fd[*lun] = status;
			status = open(name,2); }
           if( *mode == 3 ) {
			strcpy(tname,name);
                mknamec( tname );   /* make sure the name terminates with a NULL */
                status = creat( tname, PMODE );   /* open with read and write privileges */
                close(status);
                status = open(tname,2);
                fd[*lun] = status;
                strcpy(fname[*lun],tname);}
           if( *mode == 4 ) { 
			strcpy(tname,name);
    			mknamec( tname );
			status = open( tname, 2);
			if( status == -1 )  status = open( tname, 0);  /* open it for read only if read and write fails */
			if( status == -1 ) status = open( tname, 1);  /* open for write only if read only failed */
			if( status == -1 ) {
/*		printf("wouldn't open as a small file, trying as a big file.\n");*/
#if !osx
				status = open64( tname, 2);
				if( status == -1 ) status = open64( tname, 0);
				if( status == -1 ) status = open64( tname, 1);
#else
				status = open( tname, 2);
				if( status == -1 ) status = open( tname, 0);
				if( status == -1 ) status = open( tname, 1);
#endif
				if( status >0 ) nbits[*lun] = 64;
			}
			if( status != -1 ) stat( tname, &stbuf );  /* get the status and file size */
#if debug
			printf("lun= %d, status=%d, nbits[*lun]= %d, tbuf.st_size = %x\n",
			*lun,status,nbits[*lun],stbuf.st_size);
#endif
			if( status != -1 && nbits[*lun] == 32 && (stbuf.st_size > 2147483647 || stbuf.st_size < 0 )) {
/*		printf("it was opened, but it's a big file!\n");*/
				strcpy(tname,name);
				status = close( fd[*lun] );
#if !osx
				status = open64( tname, 2);
				if( status == -1 ) status = open64( tname, 0);
				if( status == -1 ) status = open64( tname, 1);
#else
				status = open( tname, 2);
				if( status == -1 ) status = open( tname, 0);
				if( status == -1 ) status = open( tname, 1);
#endif
				if( status >0 ) nbits[*lun] = 64;
			}
			if( status != -1 ) {
				fd[*lun] = status; /* return the file desriptor  */
/*				if( nbits[*lun] == 64 ) printf("opened with open64\n"); */
				strcpy(fname[*lun],tname);
				*istat = 0;  /* everything is ok */
       /*          if( strncmp("/dev/tty", name, 8 ) == 0 ) {
                      printf(" unit=%d",fd[*lun]);
                      printf(" modifying tty!!!");
                      ioctl( fd[*lun], TIOCGETP, &term);
                      term.sg_flags = EVENP | ODDP | RAW | XTABS;
                      ioctl( fd[*lun], TIOCSETN, &term);  }
        */
				return ;
			}
          }
#if debug
	printf("lun= %d, status= %d, fd[*lun]= %d\n",*lun,status, fd[*lun]);
#endif
		if( status <= 0 ) {
/*			fd[*lun] = -1;  changed Mar 12, 99  pch  */
			*lun = -1;
/*			perror(name);   removed 1 Oct 99, pch  */
			*istat = status ;
			return;
		}
	}
}


#if hp
	void frefil( mode, lun, istat)
#else
	void frefil_( mode, lun, istat)
#endif
        int    *mode;
        int    *lun;
        int    *istat;

{
        char    cmd[80];

#if debug
      printf("frefil, mode= %d, lun= %d\n",*mode,*lun);
#endif
      if( *mode == -2) {   /* -2 means just close sioseis_tmp## - do not release the unit */
            status = close( fd[*lun] );
            return; }
      if( *mode == -3) {  /* -1 means close and delete sioseis_tmp## - don't release the unit number */
            status = close( fd[*lun] );
            sprintf(cmd, "rm ");
            strcat(cmd,fname[*lun]);
            system(cmd);
            fd[*lun] = -1 ;
            return; }
      if( *mode == 1) {   /* =1 means just to release the unit - don't close! */
            fd[*lun] = -1 ;
            return; }
      if( *mode == 2 )  {   /* =2 means release the unit number and close sioseis_tmp## */
            status = close( fd[*lun] );
            fd[*lun] = -1;
            return; }
      if( *mode == 3 ) {  /* =3 means release, close and delete */
            status = close( fd[*lun] );
            sprintf(cmd, "rm ");
            strcat(cmd,fname[*lun]);
            system(cmd);
            fd[*lun] = -1 ;
            return; }
      if( *mode == 4 )  { /*  =4 means release, close, delete all scratch (sioseis_tmp) files */
            for ( i = 3; i < MAXFDS ; i++ ) {
                  if( reserved[i] == -1 &&  fd[i] > 0 && fd[i] != 99 ) {
                      status = close( fd[i] );
                      sprintf(cmd, "sioseis_tmp%d", i);
                      if( strcmp(cmd,fname[i]) == 0 ) {
                          sprintf(cmd, "rm sioseis_tmp%d\n", i);
                          system(cmd);
                      }
                      fd[i] = -1; }
            }
            return;
      }
}

#if hp
	void filsiz(name, bsize)
#else
	void filsiz_(name, bsize)
#endif
	char      *name;
	int       *bsize;

{
	strcpy(tname,name);
	mknamec( tname );   /* make sure the name terminates with a NULL */
      stat(tname, &stbuf);
      *bsize = stbuf.st_size;
      return;
}

/* GETCWD
     Note: getdir has one argument more than the call to this
                   function in FORTRAN!
    (FORTRAN (at least on SUNs) expects to be passed the length of
    all character variables in a way that remains hidden to the
    FORTRAN user. This is done by passing additional arguments,
    one integer for each character variable!
    here cwd_len contains the length of the character variable cwd
    exactly as declared in the FORTRAN main program! )

    If this code is portable I eat a broom!     -ruedi
    Works on Sun and HP.  bombs on SGI.  - paul
*/

#if hp
	void getdir(cwd, istat, cwd_len)
#else
	void getdir_(cwd, istat, cwd_len)
#endif
	char      *cwd;
	int       *istat;
	int       cwd_len;
{
	*istat = -1 ;
/*	printf("GETDIR: cwd_len = %d\n", cwd_len); */
	getcwd(cwd, cwd_len);
	*istat = 0 ;
/*	printf("GETDIR: cwd = %s\n", cwd); */
	return;
}

#if hp
	void godir(dir, istat)
#else
	void godir_(dir, istat)
#endif
	char        *dir;
	int         *istat;
{
	*istat = -1 ;
/*	printf("GODIR: dir = %s\n", dir); */
	if (( *istat = chdir( dir ) ) == NULL) return;
	perror("godir");
	return;
}



#if hp
	void podisc( lun, mode, addres)
#else
	void podisc_( lun, mode, addres)
#endif
      int     *lun;
      int     *mode;
      int     *addres;

{
#if debug
      printf(" podisc, lun=%d, mode=%d, addr=%d\n",*lun,*mode,*addres);
#endif
      offset = *addres * 4 ;  /* the address was given in units of 4 bytes */
      origin = SEEK_SET;  /* preset to origin of the beginning of the file */
      if( *mode == 2 ) origin = SEEK_CUR;   /* mode = 2 means relative to the current position */
      status = lseek( fd[*lun], offset, origin) ;
      if( status < 0 ) {
	fprintf( stderr, "Warning: disk address, %d, less than 0, setting to 0\n",status);
	lseek( fd[*lun], (off_t)0, SEEK_SET );
      }
      return;
}

#if hp
	void podisc64( lun, mode, addres64)
#else
	void podisc64_( lun, mode, addres64)
#endif
      int	*lun;
      int	*mode;
#if !osx && !linux
      off64_t	*addres64;  /* 64 bit address of 32 bit words  */
#else
      off_t	*addres64;  /* 64 bit address of 32 bit words  */
#endif

{
#if debug 
	printf(" podisc64, lun=%d, mode=%d, addr=%d\n",*lun,*mode,*addres64);
#endif
      offset64 = *addres64 * 4 ;  /* the address was given in units of 4 bytes */
      origin = SEEK_SET;  /* preset to origin of the beginning of the file */
      if( *mode == 2 ) origin = SEEK_CUR;   /* mode = 2 means relative to the current position */
#if !osx
      status = lseek64( fd[*lun], offset64, origin) ;
#else
      status = lseek( fd[*lun], offset64, origin) ;
#endif
      if( status < 0 ) {
	fprintf( stderr, "Warning: disk address, %d, less than 0, setting to 0\n",status);
#if !osx
	lseek64( fd[*lun], 0L, SEEK_SET );
#else
	lseek( fd[*lun], (off_t)0, SEEK_SET );
#endif
      }
      return;
}

#if hp
	void podiscb( lun, mode, addres)
#else
	void podiscb_( lun, mode, addres)
#endif
      int     *lun;
      int     *mode;
      int     *addres;

{
#if debug
      printf(" podiscb, lun=%d, mode=%d, addr=%d\n",*lun,*mode,*addres);
#endif
      offset = *addres ;  /* the address was given in units of bytes */
      origin = SEEK_SET;  /* preset to origin of the beginning of the file */
      if( *mode == 2 ) origin = SEEK_CUR;   /* mode = 2 means relative to the current position */
      status = lseek( fd[*lun], offset, origin) ;
      if( status < 0 ) {
	fprintf( stderr, "Warning: disk address, %d, less than 0, setting to 0\n",status);
	lseek( fd[*lun], 0L, SEEK_SET );
      }
      return;
}

#if hp
	void podiscb64( lun, mode, addres64)
#else
	void podiscb64_( lun, mode, addres64)
#endif
      int     *lun;
      int     *mode;
#if !osx && !linux
      off64_t	*addres64;
#else
      off_t	*addres64;
#endif

{
#if debug
	printf(" podiscb64, lun=%d, mode=%d, addr=%d\n",*lun,*mode,*addres64);
#endif
      offset64 = *addres64 ;  /* the address was given in units of bytes */
      origin = SEEK_SET;  /* preset to origin of the beginning of the file */
      if( *mode == 2 ) origin = SEEK_CUR;   /* mode = 2 means relative to the current position */
      if( status < 0 ) {
	fprintf( stderr, "Warning: disk address, %d, less than 0, setting to 0\n",status);
#if !osx && !linux
	lseek64( fd[*lun], (off64_t)0, SEEK_SET );
#else
	lseek( fd[*lun], (off_t)0, SEEK_SET );
#endif
      }
      return;
}

#if hp
	void adrdisc( lun, addres )
#else
	void adrdisc_( lun, addres )
#endif
	int	*lun;
	int	*addres;

{
	*addres = lseek( fd[*lun], (off_t)0, SEEK_CUR );
#if debug
	printf("addr= %d nbits= %d\n",*addres,nbits[*lun]);
#endif
	if( nbits[*lun] != 32 ) {
		printf("adrdisc: Address may be wrong because it's a large file (>2GB)\n");
	}
	return;
}

#if hp
	void adrdisc64( lun, addres64 )
#else
	void adrdisc64_( lun, addres64 )
#endif
	int	*lun;
#if !osx && !linux
	off64_t	*addres64;
#else
	off_t	*addres64;
#endif

{
#if !osx && !linux
	*addres64 = lseek64( fd[*lun], (off64_t)0, SEEK_CUR );
#else
	*addres64 = lseek( fd[*lun], (off_t)0, SEEK_CUR );
#endif
/*	printf("addr64= %d\n",*addres64);  what's the format for longlong?  */
	return;
}

#if hp
	void rddisc(lun, buffer, nwrds, istat)
#else
	void rddisc_(lun, buffer, nwrds, istat)
#endif
       int     *lun;
       int     *buffer;
       int     *nwrds;
       int     *istat;

{
       nbytes = *nwrds * 4 ;  /* nwrds is the number of 4 byte words to read */
#if debug
	offset = lseek( fd[*lun], (off_t)0, SEEK_CUR );
#endif
       status = read( fd[*lun], buffer, nbytes);
#if debug
	printf(" rddisc, lun=%d, from byte %d nwrds=%d, status=%d\n",*lun,offset,*nwrds,status);
#endif
       if( status < 0 ) {
              printf(" ***  ERROR  ***  disc file read error on unit %d, status = %d\n",*lun,status);
              perror("rddisc");
              *istat = status ; }
       else *istat = status / 4 ;  /* convert the number of bytes read to words */
       *istat = status / 4;
       if ( *istat == 0 ) *istat = -1 ;  /* istat=-1 means end of file  */
       return;
}


#if hp
	void rddiscb(lun, buffer, n, istat)
#else
	void rddiscb_(lun, buffer, n, istat)
#endif
       int     *lun;
       int     *buffer;
       int     *n;
       int     *istat;

{
	nbytes = *n ; 
#if debug
	offset = lseek( fd[*lun], (off_t)0, SEEK_CUR );
#endif
       status = read( fd[*lun], buffer, nbytes);
#if debug
	printf(" rddiscb, lun=%d, n=%d, status=%d from %d\n",*lun,*n,status,offset);
#endif
       if( status < 0 ) {
              printf(" ***  ERROR  ***  disc file read error on unit %d, status = %d\n",*lun,status);
              perror("rddisc");
              *istat = status ; }
       else *istat = status ;
       *istat = status;
       if ( *istat == 0 ) *istat = -1 ;  /* istat=-1 means end of file  */
       return;
}

#if hp
	void wrdisc(lun, buffer, nwrds)
#else
	void wrdisc_(lun, buffer, nwrds)
#endif
       int     *lun;
       int     *buffer;
       int     *nwrds;

{
#if debug
/*       watch out if it's a 64 bit file  */
	offset = lseek( fd[*lun], (off_t)0, SEEK_CUR );
	printf(" wrdisc, lun=%d, to byte %d, nwrds=%d\n",*lun,offset,*nwrds);
#endif
       nbytes = *nwrds * 4 ;  /* nwrds is the number of 4 byte words to write */
       status = write( fd[*lun], buffer, nbytes);
       if( status != nbytes ) {
             printf(" ***  ERROR  ***  ^GDisc file write error on unit %d, status = %d\n",*lun,status);
             perror("wrdisc"); }
       return;
}

#if hp
	void wrdiscb(lun, buffer, n)
#else
	void wrdiscb_(lun, buffer, n)
#endif
       int     *lun;
       int     *buffer;
       int     *n;

{
#if debug
	offset = lseek( fd[*lun], (off_t)0, SEEK_CUR );
	printf(" wrdiscb, lun=%d, to byte %d, nwrds=%d\n",*lun,offset,*n); 
#endif
	nbytes = *n ;
	status = write( fd[*lun], buffer, nbytes);
if( status != nbytes ) {
		printf(" ***  ERROR  ***  ^GDisc file write error on unit %d, status = %d\n",*lun,status);
		perror("wrdisc"); }
	return;
}

#if hp
	void fdsync( lun )
#else
	void fdsync_( lun )
#endif
	int     *lun; 
 
{
	status = fsync( fd[*lun] );
	status = fflush( stdin );
#if debug
	printf("fd= %d, lun= %d, status= %d\n",fd[*lun],*lun,status);
#endif
	return;    
}



/* end */
