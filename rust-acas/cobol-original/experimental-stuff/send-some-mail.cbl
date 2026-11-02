       >>source free
identification division.
 program-id. sendsomemail.

 environment division.
 input-output section.
 data division.
 working-storage section.

 01  mail-to-address                     pic x(64).
 01  mail-subject                        pic x(64).
 01  mail-from-address                   pic x(64).
 01  mail-body                           pic x(256).
 01  mail-command                        pic x(512).
 01  mail-return                         usage binary-long.
 01  Mail-Attachment-Filename            Pic X(64).

 procedure division.
 beginning.


     move "vbcoen@gmail.com"         to mail-to-address.
     move "'Your current Statement from Applewood Computers'"           to mail-subject.
     move "vbcoen@btconnect.com"     to mail-from-address.
     move "Your current statement from Applewood Computer is attached.Should you have any problems with this please email admin at: vbcoen@gmail.com. We thank you for your prompt attention."
                                     to mail-body.

*>     move "Your invoice from Applewood Computer is attached.Should you have any problems with this please email admin at: vbcoen@gmail.com. We thank you for your business and we hope to see you again soon."
*>                                     to mail-body.

     move "/home/vince/tmp/test.pdf" to mail-attachment-filename.

     string "echo '"          delimited by size
            mail-body         delimited by size
            "' | mailx -r "    delimited by size
            mail-from-address delimited by size
            "-s "             delimited by size
            mail-subject      delimited by size
        " -a "           delimited by size
        mail-attachment-filename delimited by size
         " "      delimited by size
            mail-to-address   delimited by size
            into mail-command.

     call "system" using mail-command
                   returning mail-return.
     goback.
