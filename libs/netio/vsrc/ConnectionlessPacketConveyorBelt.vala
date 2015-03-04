using aroop;
using shotodol;
using shotodol.netio;

/***
 * \addtogroup netio
 * @{
 */
public class shotodol.netio.ConnectionlessPacketConveyorBelt : PacketConveyorBeltFiber {
	OutputStream?sink;
	shotodol_platform_net.NetStreamPlatformImpl server = shotodol_platform_net.NetStreamPlatformImpl();
	NetOutputStream responder;
	extring laddr;
	extring pstack;
	NetScribe?scribe;
	/**
	 * \brief This is vanilla connectionless server (UDP, for example).
	 *
	 * The server listens for data and put that data into protocol/incoming/sink. The sink(like gstreamer sink) should be registered as plugin. For example, to listen to udp data you need to write an extension at 'udp/incoming/sink'. @see rehashHook()
	 * @param addr Server address, for example, UDP://127.0.0.1:5060
	 * @param stack Protocol stack, for example, sip,rtp etc .
	 * 
	 */
	public ConnectionlessPacketConveyorBelt(extring*stack, extring*addr, NetScribe?givenScribe = null) {
		base();
		laddr = extring.copy_on_demand(addr);
		pstack = extring.copy_on_demand(stack);
		server = shotodol_platform_net.NetStreamPlatformImpl();
		sink = null;
		if(givenScribe != null) {
			scribe = givenScribe;
		} else {
			scribe = new DefaultNetScribe();
		}
		responder = new NetOutputStream(false, true, scribe);
	}

	~ConnectionlessPacketConveyorBelt() {
		server.close();
	}

	public void close() {
		cancel();
		pl.remove(&server);
		server.close();
	}

	public override int start(Fiber?plr) {
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
		responder.updateNetStream(&server);
		if(ret == 0) {
			Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, "Listening");
			pl.add(&server);
			poll = true;
		}
		return ret;
	}

	internal override int onEvent(shotodol_platform_net.NetStreamPlatformImpl*x) {
#if CONNECTIONLESS_DEBUG
		extring dlg = extring.stack(512);
		dlg.printf("Incoming data\n");
		Watchdog.watchit(core.sourceFileName(), core.sourceLineNo(), 10, Watchdog.WatchdogSeverity.LOG, 0, 100, &dlg);
#endif
		xtring pkt = new xtring.alloc(1024/*, TODO set factory */);
		extring softpkt = extring.copy_shallow(pkt);
		softpkt.set_length(2);
		softpkt.shift(2); // keep space for 2 bytes of token header
		shotodol_platform_net.NetStreamAddrPlatformImpl platAddr = shotodol_platform_net.NetStreamAddrPlatformImpl();
		int len = x.readFrom(&softpkt, &platAddr);
		if(len <= 0) {
			//close(); // XXX should we exit here ?
			return 0;
		}
		len += 2;
		pkt.fly().set_length(len);
#if CONNECTIONLESS_DEBUG
		dlg.printf("trimmed packet to %d data\n", pkt.fly().length());
		Watchdog.watchit(core.sourceFileName(), core.sourceLineNo(), 10, Watchdog.WatchdogSeverity.LOG, 0, 100, &dlg);
#endif
		// IMPORTANT trim the pkt here.
		pkt.shrink(len);
		aroop_uword16 token = scribe.getToken(&platAddr);
#if CONNECTIONLESS_DEBUG
		shotodol_platform_net.NetStreamAddrPlatformImpl dupPlatAddr = shotodol_platform_net.NetStreamAddrPlatformImpl();
		scribe.getAddressAs(token, &dupPlatAddr);
		extring addr = extring.stack(32);
		server.copyToEXtring(&dupPlatAddr, &addr);
		//shotodol_platform_net.NetStreamPlatformImpl.copyAddrAs(server, pkt, &addr);
		dlg.printf("Read %d bytes from %s, token %u\n", len, addr.to_string(), token);
		Watchdog.watchit(core.sourceFileName(), core.sourceLineNo(), 10, Watchdog.WatchdogSeverity.LOG, 0, 100, &dlg);
#endif
		if(sink == null) {
			return 0;
		}
		uchar ch = (uchar)((token >> 8) & 0xFF);
		pkt.fly().set_char_at(0, ch);
		ch = (uchar)(token & 0xFF);
		pkt.fly().set_char_at(1, ch);
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, "Writing to sink");
		sink.write(pkt);
		return 0;
	}

	public void registerOutputSink(Module mod) {
		extring entry = extring.stack(128);
		entry.concat(&pstack);
		entry.concat_string("/connectionless/outgoing/sink");
		PluginManager.register(&entry, new AnyInterfaceExtension(responder, mod));
	}
	public void registerRehashHook(Module mod) {
		extring entry = extring.set_static_string("rehash");
		PluginManager.register(&entry, new HookExtension(rehashHook, mod));
	}
	public void registerAllHooks(Module mod) {
		registerOutputSink(mod);
		registerRehashHook(mod);
		extring entry = extring.set_static_string("MainFiber");
		PluginManager.register(&entry, new AnyInterfaceExtension(this, mod));
	}
	public int rehashHook(extring*inmsg, extring*outmsg) {
		sink = null;
		extring entry = extring.stack(128);
		entry.concat(&pstack);
		entry.concat_string("/connectionless/incoming/sink");
		PluginManager.acceptVisitor(&entry, (x) => {
			sink = (OutputStream)x.getInterface(null);
		});
		return 0;
	}
}

/** @} */
