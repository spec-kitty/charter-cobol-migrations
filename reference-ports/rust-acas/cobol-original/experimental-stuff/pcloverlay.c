/*
 * @(#)pcoverlay.c--Convert a pcl document into an overlay file
 * @(#)STS/KBS 03july2001
 *
 * Inspired by 'ovl' Hewlett Packard PCL Laser Overlay creation utility
 * by Peter Hamilton, http://www.hamil.demon.co.uk/pcl/
 *
 * This is a complete re-write with somewhat more sophiscated escape
 * sequence parsing.  I basicly stole his setup for the overlay macro
 * and his list of sequences to delete from the stream.
 *
 * Peter's original was distributed under the GNU Version 2, June 1991
 * General Public License.  I don't know what that means for my
 * re-write.  I am imposing no restrictions on my version.
 * Kevin Smith, November 2001, kbs@shady.com
 */

#include <stdio.h>
#include <ctype.h>

int	ProcessEscapes(void);
void	PclWrite(char *,int);

int	landscape = -1;		/* 0 = portrait, 1 = landscape */
int	tobytes;		/* total bytes output */
int	tibytes;		/* total bytes input */
char	obuf[4096];		/* output buffer */
char	*op;			/* current pointer in the output */
int	debug;			/* != 0 == debug */

int
main(
    int		ac,
    char	*av[]
)
{
    int		c;
    char	cc;
    int		rawdata;	/* Transparent data size */

    rawdata = 0;		/* Nothing to start with */
    op = obuf;			/* Initialize the output buffer */

    if(ac > 1)
    {
	if(strcmp(av[1],"-d") == 0)
	{
	    debug++;
	}
	else
	{
	    fprintf(stderr,"usage: %s [-d]\n",av[0]);
	    return(1);
	}
    }

    while ((c = getchar()) != EOF)
    {
	tibytes++;
	if ( rawdata > 0 ) {
	    rawdata--;
	}
	else
	{
	    switch(c) {

	     /*
	      * Process escape sequences
	      *
	      * Function returns the number of raw data bytes which
	      * follow the escape sequence and which should be passed
	      * unmodified
	      */
	     case 0x1b:
		rawdata = ProcessEscapes();
		continue;
		break;

	     /*
	      * Ignore form feeds in the overlay
	      */
	     case '\f':
		continue;

	    }
	}
	cc = c;
	PclWrite(&cc,1);
    }

    PclWrite(NULL,-1);

    if(debug) {
	fprintf(stderr,"%d bytes in, %d bytes out\n",tibytes,tobytes);
    }
    return(0);
}

#define	STATE_TYPE1	0	/* first char of sequence */
#define	STATE_TYPE2	1	/* possible second char */
#define	STATE_ARG	2	/* sub-args to sequence */
#define	STATE_NUM1	3	/* start of a number */
#define	STATE_NUM2	4	/* continuation of a number */
#define	STATE_CMD	5	/* command letter */

/*
 * Command terminators
 *
 * An upper case letter, an equal sign, or an `at' sign
 * Also <esc>9 is a special sequence
 */
#define	ISTERM(x)	(isupper(x) || (x)=='=' || (x)=='@' || (x)=='9')

/*
 * Start of a number
 *
 * A digit, +, or -
 */
#define	ISNUM1(x)	(isdigit(x) || (x)=='-' || (x)=='+')

/*
 * Continuation of a number
 *
 * A digit
 */
#define	ISNUM2(x)	(isdigit(x))

/*
 * Delete an escape sequence
 *
 * sp points to the start of arguments after the lead in sequence
 * cp points to the beginning of the current command/argument
 *
 * If we havn't identified any sequences or we have just a short
 * single sequence, just delete the whole thing
 *
 * Otherwise, delete the current command.
 * If there is a previous command, convert it to upper case if we were the
 * last command else leave it alone.
 * If there is no previous command, delete the whole sequence
 */
#define	DELETEARG							\
    *ep = 0; \
    if(cp && sp) {							\
	char	dac;							\
if(debug) {\
fprintf(stderr,"DELETE: ebuf=[%s], sp=[%s], cp=[%s]\n",ebuf,sp,cp); \
} \
	dac = ep[-1];							\
	ep = cp;							\
	if (ep <= sp) {							\
	    if (ISTERM(dac)) {						\
		ep = ebuf;						\
	    }								\
	} else {							\
	    if (isupper(dac) && islower(ep[-1])) {			\
		ep[-1] = toupper(ep[-1]);				\
	    }								\
	}								\
    } else { 								\
	ep = ebuf;							\
    }

/*
 * Compute the numeric value of the current argument
 */
#define	NUMVAL(x)							\
    {									\
	char	numbuf[10];						\
	if (ep - cp > 0 && ep - cp < sizeof(numbuf)-1)			\
	{								\
	    strncpy(numbuf,cp,ep - cp);					\
	    numbuf[ep - cp] = '\0';					\
	    x = atoi(numbuf);						\
	}								\
    }

int
ProcessEscapes(void)
{
    char	ebuf[1024];
    char	*ep;			/* current offset in buffer */
    char	*ee;			/* end of ebuf */
    char	*sp;			/* start of sequence (after types) */
    char	*cp;			/* start of current command */
    int		c;			/* current character */
    int		state;			/* current parsing state */
    int		rawdata;		/* raw data bytes */
    int		terminate;		/* termination flag */
    int		pels;			/* landscape flag */

    char	dbuf[1024];
    char	*dp = dbuf;

    state = STATE_TYPE1;
    ep = ebuf;
    sp = NULL;
    cp = NULL;
    ee = ebuf + sizeof(ebuf);
    rawdata = 0;
    terminate = 0;
    pels = -1;			/* -1=unknown, 0=portrait, 1=landscape */

    /*
     * Loop getting chars till we hit a sequence terminator
     * or run out of room in the buffer or hit the end of file.
     *
     * We should only run out of room or hit EOF if we have
     * a corrupt input.
     */
    while( terminate == 0 && ep < ee && (c = getchar()) != EOF )
    {
	tibytes++;
	*dp++ = c;		/* Save originals for debugging */

	/*
	 * Handle the beginning state for all escape sequences
	 *
	 * Check for single character escapes (first char is a terminator)
	 * else go on to longer sequences
	 *
	 */
	if (state == STATE_TYPE1)
	{
	    if (ISTERM(c))
	    {
		state = STATE_CMD;
	    }
	    else
	    {
		*ep++ = c;
		state = STATE_TYPE2;
		continue;
	    }
	}

	/*
	 * Handle the second character of an escape sequence
	 *
	 * If numeric, we are starting the arguments to the sequence
	 * otherwise save the sequence char and then look for args
	 */
	if (state == STATE_TYPE2)
	{
	    if(ISNUM1(c))
	    {
		state = STATE_ARG;
	    }
	    else
	    {
		*ep++ = c;
		state = STATE_ARG;
		continue;
	    }
	}

	/*
	 * Starting a new argument
	 *
	 * If current char is numeric start numeric processing
	 * else we have a command letter
	 */
	if (state == STATE_ARG)
	{
	    cp = ep;			/* remember where we started */
	    if (!sp)
	    {
		sp = ep;
	    }
	    if (ISNUM1(c)) {
		state = STATE_NUM1;
	    }
	    else
	    {
		state = STATE_CMD;
	    }
	}

	/*
	 * Process numeric qualifiers
	 *
	 * State one is the beginning of a number which
	 * must be a digit, a '+', or a '-'.
	 *
	 * A digit rolls us over into continued number processing
	 * otherwise save the sign and switch to continued numbers.
	 *
	 * If non-numeric then switch to command state
	 */
	if (state == STATE_NUM1)
	{
	    if (ISNUM2(c)) {
		/*
		 * Change to continued number processing
		 * and drop into code
		 */
		state = STATE_NUM2;
	    }
	    else
	    {
		if (ISNUM1(c))
		{
		    /*
		     * Only one char allowed in num state 1
		     */
		    *ep++ = c;
		    state = STATE_NUM2;
		    continue;
		}
		else
		{
		    state = STATE_CMD;
		}
	    }
	}

	/*
	 * Continued number processing
	 *
	 * Keep saving the number as long as we are seeing digits else
	 * switch to command state
	 */
	if (state == STATE_NUM2)
	{
	    if (ISNUM2(c))
	    {
		*ep++ = c;
		continue;
	    }
	    else
	    {
		state = STATE_CMD;
	    }
	}

	/*
	 * Process an escape command
	 */
	if (state == STATE_CMD)
	{
	    *ep++ = c;

	    /*
	     * Flag whether this was a terminating character
	     */
	    terminate = ISTERM(c);

	    /*
	     * Ignore resets
	     */
	    if (!sp && c == 'E')
	    {
		DELETEARG;
	    }

	    /*
	     * Ignore raster "rotate image" command
	     * *r<n>F
	     */
	    else if (
		strncmp(ebuf,"*r",2) == 0 &&
		toupper(c) == 'F'
	    ) {
		DELETEARG;
	    }

	    /*
	     * Ignore certain page and control commands
	     */
	    else if (strncmp(ebuf,"&l",2) == 0) {
		switch (toupper(c)) {
		 case 'O':	/* set page orientation */
		    NUMVAL(pels);
		 case 'A':	/* set page size */
		 case 'H':	/* set paper source */
		 case 'G':	/* ??? */
		 case 'P':	/* set page length */
		 case 'S':	/* simplex/duplex printing */
		 case 'X':	/* number of copies */
		    DELETEARG;
		}
	    }

	    /*
	     * Get the data length 
	     * *r<n>F
	     */
	    else if (
		( strncmp(ebuf,"&p",2) == 0 && toupper(c) == 'X' ) ||
		( strncmp(ebuf,")s",2) == 0 && toupper(c) == 'W' ) ||
		( strncmp(ebuf,"(s",2) == 0 && toupper(c) == 'W' ) ||
		( strncmp(ebuf,"*b",2) == 0 && toupper(c) == 'W' )
	    ) {
		NUMVAL(rawdata);
	    }

	    cp = NULL;
	    state = STATE_ARG;

	}

    }

    *ep = '\0';
    *dp = '\0';
    if(debug) {
	fprintf(stderr,"[%s] -> [%s] (%d)\n",dbuf,ebuf,rawdata);
    }

    /*
     * Transmit whatever is left of the sequence
     */
    if (ep > ebuf)
    {
	PclWrite("\033",1);
	PclWrite(ebuf,ep-ebuf);
    }

    /*
     * Record the landscape mode
     * If there are multiple modes, we remember the last one in the
     * first escape sequence containing modes.
     *
     * This is a hack for wordperfect which seems to start every file
     * with <esc>&l1o0o...  Maybe switching back and forth will cause
     * a reset to default user values for margins etc (changing to an
     * current mode is ignored, hence the switch
     */
    if(landscape == -1 && pels != -1)
    {
	landscape = pels;
    }

    return(rawdata);
}

/*
 * Write output codes
 *
 * Output is buffered to the size of obuf then flushed.
 * This gives us a delay to discover the landscape/portrait mode,
 * or whatever else, so we can construct our leadin sequence
 *
 * Custom leadin codes are prepended on the first flush.
 * Custom closeout codes are appended at the final flush.
 *
 * A length of -1 indicates the final flush
 */
void
PclWrite(
    char	*buf,
    int		size
)
{
    int		wsize;

    static	int	first = 1;

    while(size != 0)
    {
	if(op-obuf == sizeof(obuf) || size < 0)
	{
	    if(first)
	    {
		first = 0;
		if(landscape == -1)
		{
		    landscape = 0;
		}
		if(debug) {
		    fprintf(
			stderr,
			"%s orientation\n",
			landscape == 0 ? "Portrait" :
			    landscape == 1 ? "Landscape" :
			    landscape == 2 ? "Reverse Portrait" :
			    landscape == 3 ? "Reverse Landscape" : "Unknown"
		    );
		};
		/*
		 * This is our first flush so preface it with our stuff
		 *
		 * <esc>E		Printer reset
		 * <esc>&lnnnO		Orientation (nnn = 0-3)
		 * <esc>&f
		 *	1y		Macro ID 1
		 *      0x		Start macro def.
		 *      0S		Push the current position.
		 * <esc>*r0F		Raster orientation matches document
		 */
		tobytes +=
		    printf(
			"\033E\033&l%dO\033&f1y0x0S\033*r0F",landscape
		    );
	    }

	    if (op > obuf)
	    {
		tobytes += op-obuf;
		fwrite(obuf,sizeof(char),op-obuf,stdout);
		op = obuf;
	    }

	    /*
	     * If final flush, ouput the closing string
	     */
	    if(size < 0)
	    {
		/*
		 * Termination sequence
		 *
		 * <esc>&f...
		 *      1s		Pop the current position
		 *      1x		Stop macro def
		 *      10x		Make permanant
		 *      4X		Enable overlay
		 */
		tobytes +=
		    printf(
			"\033&f1s1x10x4X"
		    );
		return;
	    }
	}

	/*
	 * Figure out how much room is left in the output buffer
	 * and copy up to that amount
	 */
	wsize = sizeof(obuf) - (op - obuf);
	if(wsize > size) wsize = size;
	memcpy(op,buf,wsize);
	op   += wsize;
	buf  += wsize;
	size -= wsize;
    }
}
