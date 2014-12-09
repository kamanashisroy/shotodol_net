using aroop;
using shotodol;
using shotodol.router;

/***
 * \addtogroup router
 * @{
 */
public class shotodol.router.RoundRobinPacketSorter : SimplePacketSorter {
	aroop_uword16 roundIndex;
	public RoundRobinPacketSorter(uint givenWpos) {
		roundIndex = 0;
		base(givenWpos);
	}
	public override aroop_uword16 resolveZero(extring*buf) {
		roundIndex = (roundIndex+1)%count;
		return roundIndex;
	}
}

/** @} */
