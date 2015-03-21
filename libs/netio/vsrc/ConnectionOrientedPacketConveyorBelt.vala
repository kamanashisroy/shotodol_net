using aroop;
using shotodol;
using shotodol.netio;

/***
 * \addtogroup netio
 * @{
 */
public class shotodol.netio.ConnectionOrientedPacketConveyorBelt : PacketConveyorBeltFiber {
	OutputStream?sink;
	shotodol_platform_net.NetStreamPlatformImpl server = shotodol_platform_net.NetStreamPlatformImpl();
	CompositeOutputStream responders;
	extring laddr;
	extring pstack;
	enum serverInfo {
		TOKEN = 1024,
	}
	/**
	 * \brief This is vanilla tcp server.
	 *
	 * The server listens for data and put that data into 'protocol/incoming/sink'. The sink(like gstreamer sink) should be registered as plugin. For example, to listen to http data you need to write an extension at 'http/incoming/sink'. @see rehashHook()
	 * @param addr Server address, for example, TCP://127.0.0.1:80
	 * @param stack Protocol stack, for example, http,xmpp etc .
	 * see http server implementation for example.
	 * 
	 */
	public ConnectionOrientedPacketConveyorBelt(extring*stack, extring*addr) {
		base();
		laddr = extring.copy_on_demand(addr);
		pstack = extring.copy_on_demand(stack);
		server = shotodol_platform_net.NetStreamPlatformImpl();
		server.setToken(serverInfo.TOKEN);
		sink = null;
		responders = new CompositeOutputStream();
	}

	~ConnectionOrientedPacketConveyorBelt() {
		server.close();
	}

	public void close() {
		cancel();
		pl.remove(&server);
		server.close();
	}

	public override int start(Fiber?plr) {
		extring rpt = extring.stack(128);
		rpt.printf("Shotodol connection oriented server listening spindle starts at %s", laddr.to_string());
		Watchdog.watchit(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.Severity.LOG, 0, 0, &rpt);
		setup(&laddr);
		return 0;
	}

	int setup(extring*addr) {
		extring wvar = extring.set_static_string("Connection Oriented server");
		Watchdog.watchvar(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.Severity.LOG, 0, 0, &wvar, addr);
		extring sockaddr = extring.stack(128);
		sockaddr.concat(addr);
		//sockaddr.trim_to_length(23);
		sockaddr.zero_terminate();
		int ret = server.connect(&sockaddr, shotodol_platform_net.ConnectFlags.BIND);
		sockaddr.destroy();
		if(ret == 0) {
			Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.Severity.LOG, 0, 0, "Listening");
			pl.add(&server);
			poll = true;
		}
		return ret;
	}

	internal override int onEvent(shotodol_platform_net.NetStreamPlatformImpl*x) {
		aroop_uword16 token = x.getToken();
		if(token == serverInfo.TOKEN) {
#if CONNECTION_ORIENTED_DEBUG
			print("[ ~ ] New client\n");
#endif
			acceptClient();
			return -1;
		}
#if CONNECTION_ORIENTED_DEBUG
		print("[ + ] Incoming data\n");
#endif
		xtring pkt = new xtring.alloc(1024/*, TODO set factory */);
		extring softpkt = extring.copy_on_demand(pkt);
		softpkt.set_length(2);
		softpkt.shift(2); // keep space for 2 bytes of token header
		int len = x.read(&softpkt);
		if(len == 0) {
			return closeClient(token);
		}
		len+=2;
		pkt.fly().set_length(len);
#if CONNECTION_ORIENTED_DEBUG
		print("trimmed packet to %d data\n", pkt.fly().length());
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.Severity.LOG, 0, 0, "Reading ..");
#endif
		// IMPORTANT trim the pkt here.
		pkt.shrink(len);
#if CONNECTION_ORIENTED_DEBUG
		print("Read %d bytes from %d connection\n", len-2, token);
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.Severity.LOG, 0, 0, "Read bytes ..");
#endif
		if(sink == null) {
			return 0;
		}
		uchar ch = (uchar)((token >> 8) & 0xFF);
		pkt.fly().set_char_at(0, ch);
		ch = (uchar)(token & 0xFF);
		pkt.fly().set_char_at(1, ch);
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.Severity.LOG, 0, 0, "Writing to sink");
		sink.write(pkt);
		return 0;
	}
       int closeClient(aroop_uword16 token) {
#if CONNECTION_ORIENTED_DEBUG
	       print("Closing client \n");
#endif
	       if(sink == null)
		       return -1;
	       NetOutputStream client = (NetOutputStream)responders.getOutputStream(token);
	       pl.remove(&client.client);
	       return 0;
       }

       int acceptClient() {
	       // accept client
#if CONNECTION_ORIENTED_DEBUG
	       print("Accepting new client \n");
#endif
	       NetOutputStream wsink = new NetOutputStream();
	       wsink.client.accept(&server);
	       pl.add(&wsink.client);
	       aroop_uword16 token = responders.addOutputStream(wsink);
#if CONNECTION_ORIENTED_DEBUG
	       print("New conenction token :%d\n", token);
#endif
	       wsink.client.setToken(token);
	       
	       return 0;
       }


	public void registerOutputSink(Module mod) {
		extring entry = extring.stack(128);
		entry.concat(&pstack);
		entry.concat_string("/connectionoriented/outgoing/sink");
		PluginManager.register(&entry, new AnyInterfaceExtension(responders, mod));
		responders.setName(&entry);
	}
	public void registerRehashHook(Module mod) {
		extring entry = extring.set_static_string("rehash");
		PluginManager.register(&entry, new HookExtension(rehashHook, mod));
		entry.rebuild_and_set_static_string("rehashAlter");
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
		entry.concat_string("/connectionoriented/incoming/sink");
		PluginManager.acceptVisitor(&entry, (x) => {
			sink = (OutputStream)x.getInterface(null);
		});
		return 0;
	}
}

/** @} */
