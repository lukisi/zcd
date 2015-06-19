NULL = 
ACLOCAL_AMFLAGS = -I m4
.PHONY: check

lib_LTLIBRARIES = \
	libzcd-tasklet-system.la \
	libzcd.la \
	$(NULL)

noinst_LTLIBRARIES = \
	libmacgetter.la \
	libhelperrpc.la \
	libsamplerpc.la \
	$(NULL)

bin_PROGRAMS = \
	rpcdesign \
	$(NULL)

noinst_PROGRAMS = \
	sample \
	sample_udp \
	$(NULL)

EXTRA_PROGRAMS = \
	tcp_server \
	$(NULL)

libmacgetter_la_SOURCES = \
	mac-getter/hw.c \
	mac-getter/hw.h \
	$(NULL)

libmacgetter_la_CPPFLAGS = \
	$(NULL)

libmacgetter_la_LIBADD = \
	$(NULL)

libzcd_tasklet_system_la_SOURCES = \
	zcd_tasklet.vala \
	$(NULL)

libzcd_tasklet_system_la_VALAFLAGS = \
	-H zcd-tasklet-system.h \
	--library zcd-tasklet-system \
	$(NULL)

libzcd_tasklet_system_la_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(NULL)

libzcd_tasklet_system_la_LIBADD = \
	$(GOBJECT_LIBS) \
	$(NULL)

libzcd_la_SOURCES = \
	zcd.vala \
	zcd-tasklet-system.vapi \
	mac-getter/hw.vapi \
	config.vapi \
	$(NULL)

libzcd_la_VALAFLAGS = \
	-H zcd.h \
	--library zcd \
	--pkg gee-0.8 \
	--pkg gio-2.0 \
	--pkg json-glib-1.0 \
	$(NULL)

libzcd_la_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GIO_CFLAGS) \
	$(JSON_CFLAGS) \
	$(NULL)

libzcd_la_LIBADD = \
	$(GIO_LIBS) \
	$(GEE_LIBS) \
	$(GOBJECT_LIBS) \
	$(JSON_LIBS) \
	$(builddir)/libzcd-tasklet-system.la \
	$(builddir)/libmacgetter.la \
	$(NULL)

tcp_server_SOURCES = \
	check/server.vala \
	$(NULL)

tcp_server_VALAFLAGS = \
	--pkg tasklet \
	--pkg gee-0.8 \
	--pkg gio-2.0 \
	$(NULL)

tcp_server_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GIO_CFLAGS) \
	$(TASKLET_CFLAGS) \
	$(NULL)

tcp_server_LDADD = -lm \
	$(GOBJECT_LIBS) \
	$(GIO_LIBS) \
	$(GEE_LIBS) \
	$(TASKLET_LIBS) \
	$(builddir)/libzcd.la \
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

libhelperrpc_la_SOURCES = \
	common_helpers.vala \
	$(NULL)

libhelperrpc_la_VALAFLAGS = \
	-H helperrpc.h \
	--library helperrpc \
	--pkg gee-0.8 \
	--pkg gio-2.0 \
	--pkg json-glib-1.0 \
	$(NULL)

libhelperrpc_la_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GIO_CFLAGS) \
	$(JSON_CFLAGS) \
	$(NULL)

libhelperrpc_la_LIBADD = \
	$(GOBJECT_LIBS) \
	$(GIO_LIBS) \
	$(GEE_LIBS) \
	$(JSON_LIBS) \
	$(NULL)

libsamplerpc_la_SOURCES = \
	sample_interfaces.vala \
	sample_skeleton.vala \
	sample_stub.vala \
	common_skeleton.vala \
	common_stub.vala \
	helperrpc.vapi \
	zcd-tasklet-system.vapi \
	zcd.vapi \
	$(NULL)

libsamplerpc_la_VALAFLAGS = \
	-H samplerpc.h \
	--library samplerpc \
	--pkg gee-0.8 \
	--pkg gio-2.0 \
	--pkg json-glib-1.0 \
	$(NULL)

libsamplerpc_la_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GIO_CFLAGS) \
	$(JSON_CFLAGS) \
	$(NULL)

libsamplerpc_la_LIBADD = \
	$(GOBJECT_LIBS) \
	$(GIO_LIBS) \
	$(GEE_LIBS) \
	$(JSON_LIBS) \
	$(builddir)/libhelperrpc.la \
	$(builddir)/libzcd-tasklet-system.la \
	$(builddir)/libzcd.la \
	$(NULL)

sample_SOURCES = \
	sample_main.vala \
	sample_tasklet.vala \
	zcd-tasklet-system.vapi \
	samplerpc.vapi \
	$(NULL)

sample_VALAFLAGS = \
	--pkg tasklet \
	--pkg gee-0.8 \
	--pkg gio-2.0 \
	--pkg json-glib-1.0 \
	$(NULL)

sample_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GIO_CFLAGS) \
	$(TASKLET_CFLAGS) \
	$(JSON_CFLAGS) \
	$(NULL)

sample_LDADD = -lm \
	$(GOBJECT_LIBS) \
	$(GIO_LIBS) \
	$(GEE_LIBS) \
	$(TASKLET_LIBS) \
	$(JSON_LIBS) \
	$(builddir)/libzcd-tasklet-system.la \
	$(builddir)/libsamplerpc.la \
	$(NULL)

sample_udp_SOURCES = \
	sample_udp_main.vala \
	sample_udp_tasklet.vala \
	zcd-tasklet-system.vapi \
	samplerpc.vapi \
	$(NULL)

sample_udp_VALAFLAGS = \
	--pkg tasklet \
	--pkg gee-0.8 \
	--pkg gio-2.0 \
	--pkg json-glib-1.0 \
	$(NULL)

sample_udp_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GIO_CFLAGS) \
	$(TASKLET_CFLAGS) \
	$(JSON_CFLAGS) \
	$(NULL)

sample_udp_LDADD = -lm \
	$(GOBJECT_LIBS) \
	$(GIO_LIBS) \
	$(GEE_LIBS) \
	$(TASKLET_LIBS) \
	$(JSON_LIBS) \
	$(builddir)/libzcd-tasklet-system.la \
	$(builddir)/libsamplerpc.la \
	$(NULL)


TESTS = \
	test_libs \
	$(NULL)

check_PROGRAMS = \
	test_libs \
	$(NULL)

test_libs_SOURCES = \
	testsuites/test_libs/test_libs.vala \
	zcd.vapi \
	zcd-tasklet-system.vapi \
	$(NULL)

test_libs_VALAFLAGS = \
	--pkg gio-2.0 \
	--pkg gee-0.8 \
	--pkg tasklet \
	$(NULL)

test_libs_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GIO_CFLAGS) \
	$(GEE_CFLAGS) \
	$(TASKLET_CFLAGS) \
	$(NULL)

test_libs_LDADD = -lm \
	$(GOBJECT_LIBS) \
	$(GIO_LIBS) \
	$(GEE_LIBS) \
	$(TASKLET_LIBS) \
	$(builddir)/libzcd-tasklet-system.la \
	$(builddir)/libzcd.la \
	$(NULL)


vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	zcd.vapi \
	zcd.deps \
	zcd-tasklet-system.vapi \
	$(NULL)

include_HEADERS = \
	zcd.h \
	zcd-tasklet-system.h \
	$(NULL)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = \
	zcd.pc \
	zcd-tasklet-system.pc \
	$(NULL)

EXTRA_DIST = \
	zcd.pc.in \
	zcd-tasklet-system.pc.in \
	$(NULL)

CLEANFILES = \
	$(builddir)/tcp_server \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(srcdir)/helperrpc.vapi \
	$(srcdir)/samplerpc.vapi \
	$(srcdir)/zcd-tasklet-system.vapi \
	$(srcdir)/zcd.vapi \
	$(NULL)

helperrpc.vapi: libhelperrpc_la_vala.stamp

samplerpc.vapi: libsamplerpc_la_vala.stamp

zcd.vapi: libzcd_la_vala.stamp

zcd-tasklet-system.vapi: libzcd_tasklet_system_la_vala.stamp

