NULL = 
ACLOCAL_AMFLAGS = -I m4
.PHONY: check

lib_LTLIBRARIES = \
	libzcd.la \
	$(NULL)

noinst_LTLIBRARIES = \
	libmacgetter.la \
	$(NULL)

bin_PROGRAMS = \
	rpcdesign \
	$(NULL)

TESTS = \
	test_tcpclient_1 \
	test_tcpclient_2 \
	test_tcpclient_3 \
	test_tcpserver_1 \
	test_tcpserver_2 \
	test_tcpserver_3 \
	test_udpclient_1 \
	test_udpclient_2 \
	test_udpserver_1 \
	test_udpserver_2 \
	$(NULL)

XFAIL_TESTS = \
	test_tcpclient_2 \
	test_tcpserver_2 \
	$(NULL)

check_PROGRAMS = \
	test_tcpclient_1 \
	test_tcpclient_2 \
	test_tcpclient_3 \
	test_tcpserver_1 \
	test_tcpserver_2 \
	test_tcpserver_3 \
	test_udpclient_1 \
	test_udpclient_2 \
	test_udpserver_1 \
	test_udpserver_2 \
	$(NULL)

libmacgetter_la_SOURCES = \
	mac-getter/hw.c \
	mac-getter/hw.h \
	$(NULL)

libmacgetter_la_CPPFLAGS = \
	$(NULL)

libmacgetter_la_LIBADD = \
	$(NULL)

libzcd_la_SOURCES = \
	zcd.vala \
	api.vala \
	tasklet_system.vala \
	listeners.vala \
	senders.vala \
	caller_info.vala \
	connection_protocol.vala \
	json_handling.vala \
	mac-getter/hw.vapi \
	config.vapi \
	$(NULL)

libzcd_la_VALAFLAGS = \
	-H zcd.h \
	--library zcd \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--pkg gee-0.8 \
	--pkg json-glib-1.0 \
	--pkg tasklet-system \
	$(NULL)

libzcd_la_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSON_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(NULL)

libzcd_la_LIBADD = \
	$(GEE_LIBS) \
	$(GOBJECT_LIBS) \
	$(JSON_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(builddir)/libmacgetter.la \
	$(NULL)

rpcdesign_SOURCES =  \
	rpcdesign.vala \
	rpcdesign_common_helpers.vala \
	rpcdesign_common_skeleton.vala \
	rpcdesign_common_stub.vala \
	rpcdesign_sample_interfaces.vala \
	rpcdesign_sample_skeleton.vala \
	rpcdesign_sample_stub.vala \
	$(NULL)

rpcdesign_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--pkg gee-0.8 \
	$(NULL)

rpcdesign_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(NULL)

rpcdesign_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(NULL)

test_tcpclient_1_SOURCES = \
	testsuites/test_tcpclient_1/test_tcpclient_1.vala \
	testsuites/test_tcpclient_1/fake.vala \
	zcd.vapi \
	$(NULL)

test_tcpclient_1_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--pkg glib-2.0 \
	--pkg gee-0.8 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_tcpclient_1_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	-I$(srcdir) \
	$(NULL)

test_tcpclient_1_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(builddir)/libzcd.la \
	$(NULL)

test_tcpclient_2_SOURCES = \
	testsuites/test_tcpclient_2/test_tcpclient_2.vala \
	testsuites/test_tcpclient_2/fake.vala \
	zcd.vapi \
	$(NULL)

test_tcpclient_2_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--pkg glib-2.0 \
	--pkg gee-0.8 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_tcpclient_2_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	-I$(srcdir) \
	$(NULL)

test_tcpclient_2_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(builddir)/libzcd.la \
	$(NULL)

test_tcpclient_3_SOURCES = \
	testsuites/test_tcpclient_3/test_tcpclient_3.vala \
	testsuites/test_tcpclient_3/fake.vala \
	zcd.vapi \
	$(NULL)

test_tcpclient_3_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--pkg glib-2.0 \
	--pkg gee-0.8 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_tcpclient_3_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	-I$(srcdir) \
	$(NULL)

test_tcpclient_3_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(builddir)/libzcd.la \
	$(NULL)

test_tcpserver_1_SOURCES = \
	testsuites/test_tcpserver_1/test_tcpserver_1.vala \
	testsuites/test_tcpserver_1/fake.vala \
	zcd.vapi \
	$(NULL)

test_tcpserver_1_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--pkg glib-2.0 \
	--pkg gee-0.8 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_tcpserver_1_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	-I$(srcdir) \
	$(NULL)

test_tcpserver_1_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(builddir)/libzcd.la \
	$(NULL)

test_tcpserver_2_SOURCES = \
	testsuites/test_tcpserver_2/test_tcpserver_2.vala \
	testsuites/test_tcpserver_2/fake.vala \
	zcd.vapi \
	$(NULL)

test_tcpserver_2_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--pkg glib-2.0 \
	--pkg gee-0.8 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_tcpserver_2_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	-I$(srcdir) \
	$(NULL)

test_tcpserver_2_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(builddir)/libzcd.la \
	$(NULL)

test_tcpserver_3_SOURCES = \
	testsuites/test_tcpserver_3/test_tcpserver_3.vala \
	testsuites/test_tcpserver_3/fake.vala \
	zcd.vapi \
	$(NULL)

test_tcpserver_3_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--pkg glib-2.0 \
	--pkg gee-0.8 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_tcpserver_3_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	-I$(srcdir) \
	$(NULL)

test_tcpserver_3_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(builddir)/libzcd.la \
	$(NULL)

test_udpclient_1_SOURCES = \
	testsuites/test_udpclient_1/test_udpclient_1.vala \
	testsuites/test_udpclient_1/fake.vala \
	zcd.vapi \
	$(NULL)

test_udpclient_1_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--pkg glib-2.0 \
	--pkg gee-0.8 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_udpclient_1_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	-I$(srcdir) \
	$(NULL)

test_udpclient_1_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(builddir)/libzcd.la \
	$(NULL)

test_udpclient_2_SOURCES = \
	testsuites/test_udpclient_2/test_udpclient_2.vala \
	testsuites/test_udpclient_2/fake.vala \
	zcd.vapi \
	$(NULL)

test_udpclient_2_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--pkg glib-2.0 \
	--pkg gee-0.8 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_udpclient_2_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	-I$(srcdir) \
	$(NULL)

test_udpclient_2_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(builddir)/libzcd.la \
	$(NULL)

test_udpserver_1_SOURCES = \
	testsuites/test_udpserver_1/test_udpserver_1.vala \
	testsuites/test_udpserver_1/fake.vala \
	zcd.vapi \
	$(NULL)

test_udpserver_1_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--pkg glib-2.0 \
	--pkg gee-0.8 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_udpserver_1_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	-I$(srcdir) \
	$(NULL)

test_udpserver_1_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(builddir)/libzcd.la \
	$(NULL)

test_udpserver_2_SOURCES = \
	testsuites/test_udpserver_2/test_udpserver_2.vala \
	testsuites/test_udpserver_2/fake.vala \
	zcd.vapi \
	$(NULL)

test_udpserver_2_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--pkg glib-2.0 \
	--pkg gee-0.8 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_udpserver_2_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	-I$(srcdir) \
	$(NULL)

test_udpserver_2_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(builddir)/libzcd.la \
	$(NULL)

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	zcd.vapi \
	zcd.deps \
	$(NULL)

include_HEADERS = \
	zcd.h \
	$(NULL)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = \
	zcd.pc \
	$(NULL)

EXTRA_DIST = \
	zcd.pc.in \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(srcdir)/zcd.vapi \
	$(NULL)

zcd.vapi: libzcd_la_vala.stamp

