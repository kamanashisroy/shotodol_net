#ifndef SHOTODOL_PLATFORM_NET_INCLUDE_H
#define SHOTODOL_PLATFORM_NET_INCLUDE_H

#include <sys/socket.h>
#include <netinet/in.h>
#include <poll.h>
#ifdef LINUX_BLUETOOTH
#include <bluetooth/bluetooth.h>
#include <bluetooth/sco.h>
#include <bluetooth/rfcomm.h>
#endif

enum {
	NET_STREAM_FLAG_UDP = 1,
	NET_STREAM_FLAG_TCP = 1<<1,
	NET_STREAM_FLAG_BIND = 1<<2,
	NET_STREAM_FLAG_CONNECT = 1<<3,
#ifdef LINUX_BLUETOOTH
	NET_STREAM_FLAG_RFCOMM = 1<<4,
	NET_STREAM_FLAG_SCO = 1<<5,
#endif
	NET_STREAM_FLAG_LISTEN = 1<<6,
};
struct net_stream {
	SYNC_UWORD16_T token;
	int sock;
	union {
		struct sockaddr_in in;
#ifdef LINUX_BLUETOOTH
		struct sockaddr_sco bt;
		struct sockaddr_rc btrc;
#endif
	} addr;
	SYNC_UWORD8_T flags;
};

enum {
	MAXIMUM_POLL_LIMIT = 64,
};

struct net_stream_poll {
	int fdcount;
	int evtcount;
	int evtindex;
	struct pollfd fd_set[MAXIMUM_POLL_LIMIT];
	struct net_stream*strms[MAXIMUM_POLL_LIMIT];
};

// stream
#define net_stream_empty(x) ({(x)->sock = -1;})
#define net_stream_copy(x,y) ({memcpy((x),(y),sizeof(*x));})
int net_stream_create(struct net_stream*strm, struct aroop_txt*path, SYNC_UWORD8_T flags);
int net_stream_recv(struct net_stream*strm, struct aroop_txt*buf);
int net_stream_send(struct net_stream*strm, struct aroop_txt*buf);
#define net_stream_close(x) ({if((x)->sock > 0){close((x)->sock);}0;})
#define net_stream_accepting(x) ({((x)->flags & NET_STREAM_FLAG_BIND);})
int net_stream_accept_new(struct net_stream*newone, struct net_stream*from);
int net_stream_addr_copy_to_extring(struct net_stream*strm, struct sockaddr*addr, struct aroop_txt*buf);
int net_stream_addr_copy_from_extring(struct net_stream*strm, struct sockaddr*addr, struct aroop_txt*buf);
int net_stream_recvfrom(struct net_stream*strm, struct aroop_txt*buf, struct sockaddr*src);
int net_stream_sendto(struct net_stream*strm, struct aroop_txt*buf, struct sockaddr*dst);
	

// poll
int net_stream_poll_add_stream(struct net_stream_poll*spoll, struct net_stream*strm);
int net_stream_poll_check_for(struct net_stream_poll*spoll, struct net_stream*strm, int writing, int reading);
int net_stream_poll_delete_stream(struct net_stream_poll*spoll, struct net_stream*strm);
int net_stream_poll_check_events(struct net_stream_poll*spoll);
struct net_stream*net_stream_poll_next(struct net_stream_poll*spoll);
#define net_stream_poll_create(x) ({(x)->fdcount = 0;})
#define net_stream_set_token(x,y) ({(x)->token = y;})
#define net_stream_get_token(x) ({(x)->token;})

#define net_stream_sockaddr_calc_hash(x) ({opp_get_hash_bin(x,sizeof(*x));})
#define net_stream_sockaddr_rebuild_from(x,y) ({memcpy((x),(y),sizeof(*x));})
#define net_stream_sockaddr_equals(x,y) ({!memcmp((x),(y),sizeof(*x));})

#endif //SHOTODOL_PLUGIN_INCLUDE_H
