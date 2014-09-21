using aroop;
using shotodol;
using shotodol.netio;
using shotodol_platform_net;

/**
 * \addtogroup netio
 *  @{
 */
public abstract class shotodol.netio.NetScribe : Replicable {
	public abstract aroop_uword16 getToken(NetStreamAddrPlatformImpl*platAddr);
	public abstract void getAddressAs(aroop_uword16 token, NetStreamAddrPlatformImpl*platAddr);
}

/* @} */
