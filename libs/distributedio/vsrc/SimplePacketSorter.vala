using aroop;
using shotodol;
using shotodol.distributedio;

/***
 * \addtogroup distributedio
 * @{
 */
public class shotodol.distributedio.SimplePacketSorter : OutputStream32x {
	protected uint wpos;
	public SimplePacketSorter(uint givenWpos) {
		wpos = givenWpos;
	}

	~SimplePacketSorter() {
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
