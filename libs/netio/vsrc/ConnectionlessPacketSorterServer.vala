using aroop;
using shotodol;
using shotodol.netio;

/***
 * \addtogroup netio
 * @{
 */
public class shotodol.netio.ConnectionlessPacketSorterServer : PacketSorterSpindle {
	OutputStream?sink;
	shotodol_platform_net.NetStreamPlatformImpl server = shotodol_platform_net.NetStreamPlatformImpl();
	NetOutputStream responder;
	extring laddr;
	extring pstack;
	/**
	 * \brief This is vanilla connectionless server (UDP, for example).
	 *
	 * The server listens for data and put that data into protocol/input/sink. The sink(like gstreamer sink) should be registered as plugin. For example, to listen to udp data you need to write an extension at 'udp/input/sink'. @see rehashHook()
	 * @param addr Server address, for example, UDP://127.0.0.1:5060
	 * @param stack Protocol stack, for example, sip,rtp etc .
	 * 
	 */
	public ConnectionlessPacketSorterServer(extring*stack, extring*addr) {
		base();
		laddr = extring.copy_on_demand(addr);
		pstack = extring.copy_on_demand(stack);
		server = shotodol_platform_net.NetStreamPlatformImpl();
		sink = null;
		responder = new NetOutputStream();
	}

	~ConnectionlessPacketSorterServer() {
		server.close();
	}

	public void close() {
		cancel();
		pl.remove(&server);
		server.close();
	}

	public override int start(Spindle?plr) {
		extring rpt = extring.stack(128);
		rpt.printf("Shotodol connection less server listening spindle starts at %s", laddr.to_string());
		Watchdog.watchit(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, &rpt);
		setup(&laddr);
		return 0;
	}

	int setup(extring*addr) {
		// TODO in place of shotodol_platform_net use abstraction to decouple from the implementation platform
		extring wvar = extring.set_static_string("Connectionless Server");
		Watchdog.watchvar(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, &wvar, addr);
		extring sockaddr = extring.stack(128);
		sockaddr.concat(addr);
		//sockaddr.trim_to_length(23);
		sockaddr.zero_terminate();
		int ret = server.connect(&sockaddr, shotodol_platform_net.ConnectFlags.BIND);
		sockaddr.destroy();
		if(ret == 0) {
			Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, "Listening");
			pl.add(&server);
			poll = true;
		}
		return ret;
	}

	internal override int onEvent(shotodol_platform_net.NetStreamPlatformImpl*x) {
#if CONNECTIONLESS_DEBUG
		print("[ + ] Incoming data\n");
#endif
		xtring pkt = new xtring.alloc(1024/*, TODO set factory */);
		uint dataPosition = 0;
		int len = x.readFrom(pkt, &dataPosition);
		if(len == 0) {
			//close(); // XXX should we exit here ?
			return 0;
		}
		pkt.fly().setLength(len);
#if CONNECTIONLESS_DEBUG
		print("trimmed packet to %d data\n", pkt.fly().length());
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, "Reading ..");
#endif
		// IMPORTANT trim the pkt here.
		pkt.shrink(len);
#if CONNECTIONLESS_DEBUG
		extring addr = extring.stack(32);
		shotodol_platform_net.NetStreamAddrPlatformImpl*platAddr = pkt.fly().to_string();
		server.copyToEXtring(platAddr, &addr);
		//shotodol_platform_net.NetStreamPlatformImpl.copyAddrAs(server, pkt, &addr);
		print("Read %d bytes(from %u bytes) from %s\n", len, dataPosition, addr.to_string());
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, "Read bytes ..");
#endif
		pkt.fly().shift((int)dataPosition-2); // 2 byte is used for TCP too. So they both have the same header length
		if(sink == null) {
			return 0;
		}
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, "Writing to sink");
		sink.write(pkt);
		return 0;
	}

	public void registerOutputSink(Module mod) {
		extring entry = extring.stack(128);
		entry.concat(&pstack);
		entry.concat_string("/connectionless/output/sink");
		Plugin.register(&entry, new AnyInterfaceExtension(responder, mod));
	}
	public void registerRehashHook(Module mod) {
		extring entry = extring.set_static_string("rehash");
		Plugin.register(&entry, new HookExtension(rehashHook, mod));
	}
	public void registerAllHooks(Module mod) {
		registerOutputSink(mod);
		registerRehashHook(mod);
		extring entry = extring.set_static_string("MainSpindle");
		Plugin.register(&entry, new AnyInterfaceExtension(this, mod));
	}
	public int rehashHook(extring*inmsg, extring*outmsg) {
		sink = null;
		extring entry = extring.stack(128);
		entry.concat(&pstack);
		entry.concat_string("/connectionless/input/sink");
		Plugin.acceptVisitor(&entry, (x) => {
			sink = (OutputStream)x.getInterface(null);
		});
		return 0;
	}
}

/** @} */
