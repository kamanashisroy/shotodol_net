using aroop;
using shotodol;
using shotodol.router;

/***
 * \addtogroup router
 * @{
 */
public class shotodol.router.SimplePacketSorter : OutputStream {
	protected uint wpos;
	protected aroop_uword16 count;
	protected OutputStream sink[64];
	public SimplePacketSorter(uint givenWpos) {
		wpos = givenWpos;
		count = 0;
	}

	~SimplePacketSorter() {
	}

	public int addSink(OutputStream givenSink) {
		if(count >= 64)
			return -1;
		sink[count++] = givenSink;
		return (int)count-1;
	}

	public virtual aroop_uword16 resolveZero(extring*buf) {
		return 0;
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
			x = resolveZero(buf);
		} else {
			x = x%count;
		}
		return sink[x].write(buf);
	}
}

/** @} */
