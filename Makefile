# CurveDNS' Makefile template
#
# The @VAR@ tokens will be replaced by configure.curvedns

NACLLIB?=/usr/local/lib
NACLINC?=/usr/local/include
CDNSCFLAGS?=-Wall -fno-strict-aliasing -O3 -I$(NACLINC)

# If you have libev at a non-standard place, specify that here:
#EV=
#EVCFLAGS=-I$(EV)/include
#EVLDFLAGS=-L$(EV)/lib

CC?=gcc
CFLAGS?= -O3 -fomit-frame-pointer -funroll-loops $(CDNSCFLAGS) $(EVCFLAGS)
LDFLAGS?=-L$(NACLLIB) $(EVLDFLAGS)

# do not edit below

EXTRALIB=-lev -lsodium

TARGETS=curvedns-keygen curvedns

.PHONY: targets clean distclean install

targets: $(TARGETS)

clean:
	rm -f *.a *.o $(TARGETS)

distclean: clean
	rm -f Makefile

install:
	@echo Sorry, no automated install. Copy the following binaries to your preferred destination path:
	@echo "  $(TARGETS)"

debug.o: debug.c debug.h
	$(CC) $(CFLAGS) -c debug.c

cache_hashtable.o: cache_hashtable.c cache_hashtable.h debug.o
	$(CC) $(CFLAGS) -c cache_hashtable.c

# ready for possible critbit addition
cache.a: cache_hashtable.o
	$(AR) cr cache.a cache_hashtable.o
	ranlib cache.a

dns.o: dns.c dns.h debug.o event.a
	$(CC) $(CFLAGS) -c dns.c

dnscurve.o: dnscurve.c dnscurve.h debug.o event.a
	$(CC) $(CFLAGS) -c dnscurve.c

curvedns.o: curvedns.c curvedns.h debug.o ip.o misc.o
	$(CC) $(CFLAGS) -c curvedns.c

ip.o: ip.c ip.h debug.o
	$(CC) $(CFLAGS) -c ip.c

event_tcp.o: event_tcp.c event.h debug.o ip.o cache.a
	$(CC) $(CFLAGS) -c event_tcp.c

event_udp.o: event_udp.c event.h debug.o ip.o cache.a
	$(CC) $(CFLAGS) -c event_udp.c

event_main.o: event_main.c event.h debug.o ip.o cache.a
	$(CC) $(CFLAGS) -c event_main.c

event.a: event_main.o event_udp.o event_tcp.o
	$(AR) cr event.a event_main.o event_udp.o event_tcp.o
	ranlib event.a

misc.o: misc.c misc.h ip.o debug.o
	$(CC) $(CFLAGS) -c misc.c

curvedns-keygen.o: curvedns-keygen.c
	$(CC) $(CFLAGS) -c curvedns-keygen.c

# The targets:
curvedns: debug.o ip.o misc.o cache.a event.a dnscurve.o dns.o curvedns.o
	$(CC) $(LDFLAGS) debug.o ip.o misc.o dnscurve.o dns.o cache.a event.a curvedns.o $(EXTRALIB) -o curvedns

curvedns-keygen: curvedns-keygen.o debug.o ip.o misc.o
	$(CC) $(LDFLAGS) curvedns-keygen.o debug.o ip.o misc.o $(EXTRALIB) -o curvedns-keygen
