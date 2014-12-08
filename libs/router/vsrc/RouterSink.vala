using aroop;
using shotodol;
using shotodol.netio;

/***
 * \addtogroup netio
 * @{
 */
public class shotodol.netio.RouterSink : OutputStream {
	int wpos;
	public RouterSink(int givenWpos) {
		wpos = givenWpos;
	}

	~RouterSink() {
	}

	public override int write(extring*buf) throws IOStreamError.OutputStreamError {
		aroop_uword16 x = 0;
		x = buf.char_at(wpos);
		x = x << 8;
		x |= buf.char_at(wpos + 1);
		sink[x%count].write(buf);
		return 0;
	}
}

/** @} */
