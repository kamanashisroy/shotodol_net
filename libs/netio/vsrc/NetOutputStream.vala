using aroop;
using shotodol;
using shotodol.netio;

/**
 * \addtogroup netio
 *  @{
 */
internal class shotodol.netio.NetOutputStream : OutputStream {
	bool closed;
	Queue<xtring>packets;
	internal shotodol_platform_net.NetStreamPlatformImpl client;
	bool asyncStream;
	//long lastActivityTime;
	public NetOutputStream(bool isAsynchronous = false) {
		packets = Queue<xtring>();
		closed = false;
		client = shotodol_platform_net.NetStreamPlatformImpl();
		asyncStream = isAsynchronous;
		//lastActivityTime = 0;
		// TODO cleanup on last activity time
	}
	~NetOutputStream() {
		client.close();
	}

	public int process() {

		xtring?pkt = packets.dequeue();	
		if(pkt == null)
			return 0;
		return client.write(pkt);
	}


	public override int write(extring*buf) throws IOStreamError.OutputStreamError {
		if(closed)
			return 0;
		if(!asyncStream)
			client.write(buf);
		int len = buf.length();
		xtring pkt = new xtring.copy_on_demand(buf);
		packets.enqueue(pkt);
		process();
		return len;
	}

	public override void close() throws IOStreamError.OutputStreamError {
		if(!closed)
			client.close();
		closed = true;
	}
}


/* @} */
