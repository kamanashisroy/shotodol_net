using aroop;
using shotodol;
using shotodol.netio;
using shotodol_platform_net;

/**
 * \addtogroup netio
 *  @{
 */
public class shotodol.netio.DefaultNetScribe : shotodol.netio.NetScribe {
	class NetAddr : aroop.Searchable {
		public NetStreamAddrPlatformImpl rawAddr;
		public void build(NetStreamAddrPlatformImpl*addr) {
			rawAddr = NetStreamAddrPlatformImpl.build_from(addr);
			set_hash(calcHash());
		}
		public aroop_hash calcHash() {
			return rawAddr.calcHash();
		}
	}
	SearchableFactory<NetAddr> addrs;
	public DefaultNetScribe() {
		addrs = SearchableFactory<NetAddr>.for_type(16,1/* Start token value from 1. */);
	}

	~DefaultNetScribe() {
	}

	public override aroop_uword16 getToken(NetStreamAddrPlatformImpl*platAddr/*extring*address*/) {
		NetAddr?entry = null;
#if CONNECTION_ORIENTED_DEBUG
		print("Searching address hash %ul\n", platAddr.calcHash());
#endif
		entry = addrs.search(platAddr.calcHash(), (data) => {
			unowned NetAddr naddr = ((NetAddr)data);
			if(platAddr.equals(&naddr.rawAddr)) {
				return 0;
			}
			return -1;
		});
		
		if(entry != null) {
			return entry.get_token();
		}
		entry = addrs.alloc_full();
		entry.build(platAddr);
		entry.pin();
		return entry.get_token();
	}

	public override void getAddressAs(aroop_uword16 token, NetStreamAddrPlatformImpl*platAddr) {
		NetAddr?entry = addrs.get(token);
		if(entry == null)
			return;
#if CONNECTION_ORIENTED_DEBUG
		print("Found\n");
#endif
		platAddr.rebuild_from(&entry.rawAddr);
	}
}

/* @} */
