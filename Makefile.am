NULL = 
ACLOCAL_AMFLAGS = -I m4

lib_LTLIBRARIES = \
	libzcd.la \
	$(NULL)

EXTRA_LTLIBRARIES = \
	libmacgetter.la \
	$(NULL)

libmacgetter_la_SOURCES = \
	mac-getter/hw.c \
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
	--pkg tasklet \
	--pkg gee-0.8 \
	--pkg gio-2.0 \
	$(NULL)

libzcd_la_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GIO_CFLAGS) \
	$(TASKLET_CFLAGS) \
	$(NULL)

libzcd_la_LIBADD = \
	$(GIO_LIBS) \
	$(GEE_LIBS) \
	$(GOBJECT_LIBS) \
	$(TASKLET_LIBS) \
	$(builddir)/libmacgetter.la \
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
	mac-getter/hw.h \
	$(NULL)

CLEANFILES = \
	$(srcdir)/zcd.vapi \
	$(srcdir)/zcd.h \
	$(srcdir)/libzcd_la_vala.stamp \
	$(srcdir)/zcd.c \
	$(srcdir)/testsuites/test_libs/test_libs.c \
	$(builddir)/libmacgetter.la \
	$(NULL)

DISTCLEANFILES = \
	zcd.pc \
	$(NULL)

BUILT_SOURCES = \
	libzcd_la_vala.stamp \
	$(NULL)

