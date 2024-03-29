*FREE
       // *****************************************************************
       // This program converts all the work queries in a specified       *
       // library into SQL files, saving them in a specified location.    *
       //                                                                 *
       // Written by Justin Becker 03/18/2024                             *
       // *****************************************************************

       //*********** CONTROL OPTIONS ***********//

       Ctl-opt Option(*srcStmt: *nodebugio);

       //*********** PROTOTYPES ***********//

       Dcl-PR ExecuteCommand ExtPgm('QCMDEXC') ;
         Command char(128) const;
         Length packed(15 : 5) const;
       End-PR;

       //*********** STANDALONE VARIABLES ***********//

       Dcl-S Command char(128) inz; // The command string that's passed to QCMDEXC
       Dcl-S Length packed(15 : 5) inz; // The length of the string that's passed to QCMDEXC

       //*********** DECLARE DATA STRUCTURES ***********//

       // Host structure for sql results
       // OBJTEXT is pulled so descriptions can be implemented into
       // the new SQL queries as comments once they're eventually exported
       // for use in Run SQL Scripts' example library
       dcl-ds sqlResults;
         OBJNAME Char(10) inz;
         OBJTEXT Varchar(255) inz;
       END-DS;

       //*********** MAIN ***********//

       EXEC SQL DECLARE C1 CURSOR FOR
         SELECT
           TRIM(OBJNAME) AS OBJNAME,
           IFNULL(OBJTEXT, '') AS OBJTEXT
         FROM TABLE(qsys2.object_statistics('{library}', 'ALL'))
         WHERE OBJTYPE = '*QRYDFN'
         FOR READ ONLY;

       EXEC SQL OPEN C1;

       EXEC SQL FETCH NEXT FROM C1 INTO :sqlResults; // Grab the first result before entering loop

       DOW SQLState < '02000'; // Continue until there are no more results

         // Build the CL by concatenating OBJNAME into the command
         Command = 'RTVQMQRY QMQRY({library}/' +
           %TRIM(OBJNAME) +
           ') SRCFILE({library}/QQMQRYSRC) ' +
           'ALWQRYDFN(*YES)';

         ExecuteCommand( %TRIM(Command) : %len(%trim(Command)) ); // Export the query as an SQL file

         EXEC SQL FETCH NEXT FROM C1 INTO :sqlResults; // Grab next result

       ENDDO;

       EXEC SQL CLOSE C1;

       *InLr = *On;
 