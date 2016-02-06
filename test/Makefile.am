NULL = 
ACLOCAL_AMFLAGS = -I m4
.PHONY: check

bin_PROGRAMS = \
	test_listen \
	test_scrivi \
	test_salutami \
	test_salutami2 \
	$(NULL)

noinst_LTLIBRARIES = \
	libhelperrpc.la \
	libtestrpc.la \
	$(NULL)

libhelperrpc_la_SOURCES = \
	common_helpers.vala \
	$(NULL)

libhelperrpc_la_VALAFLAGS = \
	-H helperrpc.h \
	--library helperrpc \
	--pkg gee-0.8 \
	--pkg json-glib-1.0 \
	$(NULL)

libhelperrpc_la_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSON_CFLAGS) \
	$(NULL)

libhelperrpc_la_LIBADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(JSON_LIBS) \
	$(NULL)

libtestrpc_la_SOURCES = \
	common_skeleton.vala \
	common_stub.vala \
	sample_interfaces.vala \
	sample_skeleton.vala \
	sample_stub.vala \
	helperrpc.vapi \
	$(NULL)

libtestrpc_la_VALAFLAGS = \
	-H testrpc.h \
	--library testrpc \
	--pkg gee-0.8 \
	--pkg json-glib-1.0 \
	--pkg tasklet-system \
	--pkg zcd \
	$(NULL)

libtestrpc_la_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSON_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(ZCD_CFLAGS) \
	$(NULL)

libtestrpc_la_LIBADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(JSON_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(ZCD_LIBS) \
	$(builddir)/libhelperrpc.la \
	$(NULL)

test_listen_SOURCES = \
	test_listen.vala \
	test_serializables.vala \
	testrpc.vapi \
	$(NULL)

test_listen_VALAFLAGS = \
	--pkg gee-0.8 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_listen_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(NULL)

test_listen_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(builddir)/libtestrpc.la \
	$(NULL)

test_scrivi_SOURCES = \
	test_scrivi.vala \
	test_scrivi_serializables.vala \
	testrpc.vapi \
	$(NULL)

test_scrivi_VALAFLAGS = \
	--pkg gee-0.8 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_scrivi_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(NULL)

test_scrivi_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(builddir)/libtestrpc.la \
	$(NULL)

test_salutami_SOURCES = \
	test_salutami.vala \
	test_salutami_serializables.vala \
	testrpc.vapi \
	$(NULL)

test_salutami_VALAFLAGS = \
	--pkg gee-0.8 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_salutami_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(NULL)

test_salutami_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(builddir)/libtestrpc.la \
	$(NULL)

test_salutami2_SOURCES = \
	test_salutami2.vala \
	test_salutami2_serializables.vala \
	testrpc.vapi \
	$(NULL)

test_salutami2_VALAFLAGS = \
	--pkg gee-0.8 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_salutami2_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(NULL)

test_salutami2_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(builddir)/libtestrpc.la \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(srcdir)/helperrpc.vapi \
	$(srcdir)/testrpc.vapi \
	$(NULL)

helperrpc.vapi: libhelperrpc_la_vala.stamp

testrpc.vapi: libtestrpc_la_vala.stamp

