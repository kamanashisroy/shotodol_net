using aroop;
using shotodol;
using shotodol.netio;

/***
 * \addtogroup netio
 * @{
 */
public abstract class shotodol.netio.TCPPacketSorterSpindle : Spindle {
	protected bool poll;
	//protected int interval;
	protected shotodol_platform_net.NetStreamPollPlatformImpl pl;
	public TCPPacketSorterSpindle() {
		base();
		//interval = 10;
		pl = shotodol_platform_net.NetStreamPollPlatformImpl();
	}

	~TCPPacketSorterSpindle() {
	}
	public override int step() {
		if(!poll) {
			return 0;
		}
		//shotodol_platform.ProcessControl.millisleep(interval);
		pl.check_events();
		do {
			shotodol_platform_net.NetStreamPlatformImpl*x = pl.next();
			if(x == null) {
				break;
			}
			if(onEvent(x)!=0) {
				break;
			}
		} while(true);
		return 0;
	}
	public override int cancel() {
		return 0;
	}
	internal abstract int onEvent(shotodol_platform_net.NetStreamPlatformImpl*x);
}

/** @} */
