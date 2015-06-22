NULL = 
ACLOCAL_AMFLAGS = -I m4
.PHONY: check

lib_LTLIBRARIES = \
	libzcd-tasklet-system.la \
	libzcd.la \
	$(NULL)

noinst_LTLIBRARIES = \
	libmacgetter.la \
	$(NULL)

bin_PROGRAMS = \
	rpcdesign \
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
	--pkg json-glib-1.0 \
	$(NULL)

libzcd_la_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSON_CFLAGS) \
	$(NULL)

libzcd_la_LIBADD = \
	$(GEE_LIBS) \
	$(GOBJECT_LIBS) \
	$(JSON_LIBS) \
	$(builddir)/libzcd-tasklet-system.la \
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

MAINTAINERCLEANFILES = \
	$(srcdir)/zcd-tasklet-system.vapi \
	$(srcdir)/zcd.vapi \
	$(NULL)

zcd.vapi: libzcd_la_vala.stamp

zcd-tasklet-system.vapi: libzcd_tasklet_system_la_vala.stamp

