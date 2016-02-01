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
	test_zcd_tcp \
	$(NULL)

check_PROGRAMS = \
	test_zcd_tcp \
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
	mac-getter/hw.vapi \
	config.vapi \
	$(NULL)

libzcd_la_VALAFLAGS = \
	-H zcd.h \
	--library zcd \
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

test_zcd_tcp_SOURCES = \
	testsuites/test_zcd_tcp/test_zcd_tcp.vala \
	testsuites/test_zcd_tcp/fake.vala \
	zcd.vapi \
	$(NULL)

test_zcd_tcp_VALAFLAGS = \
	--pkg glib-2.0 \
	--pkg gee-0.8 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_zcd_tcp_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	-I$(srcdir) \
	$(NULL)

test_zcd_tcp_LDADD = \
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

