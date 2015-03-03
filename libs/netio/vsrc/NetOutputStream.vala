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
	bool connectionless;
	NetScribe?scribe;
	//long lastActivityTime;
	public NetOutputStream(bool isAsynchronous = false, bool isConnectionless = false, NetScribe?gscribe = null) {
		packets = Queue<xtring>();
		closed = false;
		client = shotodol_platform_net.NetStreamPlatformImpl();
			
		asyncStream = isAsynchronous;
		connectionless = isConnectionless;
		scribe=gscribe;
		//lastActivityTime = 0;
		// TODO cleanup on last activity time
	}
	~NetOutputStream() {
		client.close();
	}

	public void updateNetStream(shotodol_platform_net.NetStreamPlatformImpl*given) {
		client.copy_deep(given);
	}

	public int process() {

		xtring?pkt = packets.dequeue();	
		if(pkt == null)
			return 0;
		if(connectionless) {
			shotodol_platform_net.NetStreamAddrPlatformImpl rawAddr;
			aroop_uword16 token = pkt.fly().char_at(0);
			token = token << 8;
			token |= pkt.fly().char_at(1);
			if(scribe == null) return 0;
			scribe.getAddressAs(token, &rawAddr);
			pkt.fly().shift(2); // skip the token
			return client.writeTo(pkt, &rawAddr);
		} else {
			return client.write(pkt);
		}
	}


	public override int write(extring*buf) throws IOStreamError.OutputStreamError {
		if(closed)
			return 0;
		if(!asyncStream)
			if(connectionless) {
				shotodol_platform_net.NetStreamAddrPlatformImpl rawAddr;
				aroop_uword16 token = buf.char_at(0);
				token = token << 8;
				token |= buf.char_at(1);
				if(scribe == null) return 0;
				scribe.getAddressAs(token, &rawAddr);
#if CONNECTIONLESS_DEBUG
				extring addr = extring.stack(32);
				client.copyToEXtring(&rawAddr, &addr);
				extring dlg = extring.stack(128);
				dlg.printf("Writing %d bytes to %s, token %u\n", buf.length(), addr.to_string(), token);
				Watchdog.watchit(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 100, &dlg);
#endif
				buf.shift(2); // skip the token
				return client.writeTo(buf, &rawAddr);
			} else {
				return client.write(buf);
			}
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
