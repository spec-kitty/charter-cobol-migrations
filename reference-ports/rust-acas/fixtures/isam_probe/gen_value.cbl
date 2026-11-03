identification division.
program-id. gen_value.
environment division.
configuration section.
input-output section.
file-control.
copy "selval.cob".
data division.
file section.
copy "fdval.cob".
working-storage section.
77 i pic 9.
77 fs-reply pic 99.
procedure division.
    open output value-file.
    perform varying i from 1 by 1 until i > 2
        move "Sv" to va-system va-first
        move i to va-second
        move "000123" to va-gl
        move "probe value" to va-desc
        write value-record
    end-perform.
    close value-file.
    stop run.
