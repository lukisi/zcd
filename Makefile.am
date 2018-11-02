NULL = 
ACLOCAL_AMFLAGS = -I m4
.PHONY: check

lib_LTLIBRARIES = \
	libzcd.la \
	$(NULL)

bin_PROGRAMS = \
	rpcdesign \
	$(NULL)

TESTS = \
	test_json_handling \
	test_streams \
	test_datagrams \
	$(NULL)

check_PROGRAMS = \
	test_json_handling \
	test_streams \
	test_datagrams_alpha \
	test_datagrams_beta \
	test_datagrams_gamma \
	radio_domain \
	$(NULL)

libzcd_la_SOURCES = \
	api.vala \
	tasklet_system.vala \
	listeners.vala \
	senders.vala \
	caller_info.vala \
	connection_protocol.vala \
	json_handling.vala \
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
	--pkg gee-0.8 \
	--pkg json-glib-1.0 \
	$(NULL)

test_json_handling_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSON_CFLAGS) \
	$(NULL)

test_json_handling_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(JSON_LIBS) \
	$(NULL)

test_streams_SOURCES = \
	testsuites/test_streams/test_streams.vala \
	testsuites/test_streams/party_a.vala \
	testsuites/test_streams/party_b.vala \
	testsuites/test_streams/tasklet_system.vala \
	testsuites/test_streams/api.vala \
	testsuites/test_streams/caller_info.vala \
	testsuites/test_streams/json_handling.vala \
	testsuites/test_streams/connection_protocol.vala \
	testsuites/test_streams/listeners.vala \
	testsuites/test_streams/senders.vala \
	$(NULL)

test_streams_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--pkg gee-0.8 \
	--pkg json-glib-1.0 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_streams_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSON_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	$(NULL)

test_streams_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(JSON_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(NULL)

radio_domain_SOURCES = \
	testsuites/radio_domain/radio_domain.vala \
	$(NULL)

radio_domain_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--pkg gio-2.0 \
	--pkg gio-unix-2.0 \
	--pkg gee-0.8 \
	--pkg posix \
	$(NULL)

radio_domain_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GIO_CFLAGS) \
	$(GEE_CFLAGS) \
	$(NULL)

radio_domain_LDADD = \
	$(GOBJECT_LIBS) \
	$(GIO_LIBS) \
	$(GEE_LIBS) \
	$(NULL)

test_datagrams_alpha_SOURCES = \
	testsuites/test_datagrams/alpha_peculiar.vala \
	testsuites/test_datagrams/alpha_common.vala \
	testsuites/test_datagrams/alpha_tasklet_system.vala \
	testsuites/test_datagrams/alpha_api.vala \
	testsuites/test_datagrams/alpha_caller_info.vala \
	testsuites/test_datagrams/alpha_json_handling.vala \
	testsuites/test_datagrams/alpha_connection_protocol.vala \
	testsuites/test_datagrams/alpha_listeners.vala \
	testsuites/test_datagrams/alpha_senders.vala \
	$(NULL)

test_datagrams_alpha_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--pkg gee-0.8 \
	--pkg json-glib-1.0 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_datagrams_alpha_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSON_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	$(NULL)

test_datagrams_alpha_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(JSON_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(NULL)

test_datagrams_beta_SOURCES = \
	testsuites/test_datagrams/beta_peculiar.vala \
	testsuites/test_datagrams/beta_common.vala \
	testsuites/test_datagrams/beta_tasklet_system.vala \
	testsuites/test_datagrams/beta_api.vala \
	testsuites/test_datagrams/beta_caller_info.vala \
	testsuites/test_datagrams/beta_json_handling.vala \
	testsuites/test_datagrams/beta_connection_protocol.vala \
	testsuites/test_datagrams/beta_listeners.vala \
	testsuites/test_datagrams/beta_senders.vala \
	$(NULL)

test_datagrams_beta_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--pkg gee-0.8 \
	--pkg json-glib-1.0 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_datagrams_beta_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSON_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	$(NULL)

test_datagrams_beta_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(JSON_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(NULL)

test_datagrams_gamma_SOURCES = \
	testsuites/test_datagrams/gamma_peculiar.vala \
	testsuites/test_datagrams/gamma_common.vala \
	testsuites/test_datagrams/gamma_tasklet_system.vala \
	testsuites/test_datagrams/gamma_api.vala \
	testsuites/test_datagrams/gamma_caller_info.vala \
	testsuites/test_datagrams/gamma_json_handling.vala \
	testsuites/test_datagrams/gamma_connection_protocol.vala \
	testsuites/test_datagrams/gamma_listeners.vala \
	testsuites/test_datagrams/gamma_senders.vala \
	$(NULL)

test_datagrams_gamma_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--pkg gee-0.8 \
	--pkg json-glib-1.0 \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	$(NULL)

test_datagrams_gamma_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSON_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	$(NULL)

test_datagrams_gamma_LDADD = \
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

