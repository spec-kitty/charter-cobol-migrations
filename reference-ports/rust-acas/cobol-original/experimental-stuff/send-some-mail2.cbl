       >>source free
*> ************************************************************ <*
*> Author:    Robert Doerfler
*> Date:      2011-12-13
*> Purpose:   sending some mail
*> Tectonics: cobc
*> ************************************************************ <*
 identification division.
 program-id. sendsomemail.

 environment division.
 input-output section.
 data division.
 working-storage section.

 01  Mail-To-Address                     Pic X(64).
 01  Mail-Subject                        Pic X(64).
 01  Mail-Body                           Pic X(256).
 01  Mail-Command                        Pic X(600).
 01  Mail-Return                         Usage Binary-Long.
 01  Mail-Attachment-Filename            Pic X(64).

 procedure division.
 beginning.


 MOVE "vbcoen@gmail.com" TO MAIL-TO-ADDRESS.
 MOVE "COBOL EMAIL TEST" TO MAIL-SUBJECT.
 MOVE "test test test test2 " TO MAIL-BODY.

 MOVE "home/vince/tmp/test.pdf" TO MAIL-ATTACHMENT-FILENAME.

*> echo 'body line ' | mutt -s 'subject line' -a /tmp/test.pdf <*
*>                        -- vbcoen@gmail.com                    <*


 STRING "echo 'test 1 2 3' | " DELIMITED BY SIZE
        "mutt " DELIMITED BY SIZE
        " -s '" DELIMITED BY SIZE
        MAIL-SUBJECT DELIMITED BY SIZE
        "' -a " DELIMITED BY SIZE
        MAIL-ATTACHMENT-FILENAME DELIMITED BY SIZE
        " -- " DELIMITED BY SIZE
        MAIL-TO-ADDRESS DELIMITED BY SIZE

        INTO MAIL-COMMAND.

 DISPLAY MAIL-COMMAND

 CALL "SYSTEM" USING MAIL-COMMAND
               RETURNING MAIL-RETURN.

 goback.
