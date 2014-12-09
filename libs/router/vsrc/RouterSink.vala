using aroop;
using shotodol;
using shotodol.router;

/***
 * \addtogroup netio
 * @{
 */
public class shotodol.router.RouterSink : OutputStream {
	uint wpos;
	aroop_uword16 count;
	OutputStream sink[64];
	bool zeroToRoundRobin;
	aroop_uword16 roundIndex;
	public RouterSink(uint givenWpos, bool isZeroToRoundRobin = false) {
		wpos = givenWpos;
		count = 0;
		zeroToRoundRobin = isZeroToRoundRobin;
		roundIndex = 0;
	}

	~RouterSink() {
	}

	public int addSink(OutputStream givenSink) {
		if(count >= 64)
			return -1;
		sink[count++] = givenSink;
		return (int)count-1;
	}

	public override int write(extring*buf) throws IOStreamError.OutputStreamError {
		/** sanity check */
		if(count == 0 || buf.length() <= wpos+2)
			return buf.length(); // This data is lost and we do not know the way to route them.
		aroop_uword16 x = 0;
		x = buf.char_at(wpos);
		x = x << 8;
		x |= buf.char_at(wpos + 1);
		if(x == 0) {
			if(zeroToRoundRobin) {
				x = roundIndex + 1;
				x = x%count;
				roundIndex = x;
			}
		} else {
			x = x%count;
		}
		return sink[x].write(buf);
	}
}

/** @} */
