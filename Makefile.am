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
	test_json_handling \
	$(NULL)

check_PROGRAMS = \
	test_json_handling \
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

test_json_handling_SOURCES = \
	testsuites/test_json_handling/test_json_handling.vala \
	testsuites/test_json_handling/json_handling.vala \
	$(NULL)

test_json_handling_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--pkg glib-2.0 \
	--pkg gee-0.8 \
	--pkg json-glib-1.0 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_json_handling_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSON_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	$(NULL)

test_json_handling_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(JSON_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(PTHTASKLET_LIBS) \
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

