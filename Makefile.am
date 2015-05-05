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

# TODO make it configurable the flag "-D linux"
libzcd_la_VALAFLAGS = \
	-H zcd.h \
	--library zcd \
	-D linux \
	--pkg tasklet \
	--pkg gee-0.8 \
	--pkg gio-2.0 \
	$(NULL)

libzcd_la_CPPFLAGS = \
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


CLEANFILES = \
	$(srcdir)/zcd.vapi \
	$(srcdir)/zcd.h \
	$(srcdir)/libzcd_la_vala.stamp \
	$(srcdir)/zcd.c \
	$(NULL)

zcd.vapi: libzcd_la_vala.stamp
	$(NULL)

