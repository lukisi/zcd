AC_PREREQ([2.68])
AC_INIT([zcd],[2.0])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([subdir-objects] [1.11])
AM_SILENT_RULES([yes])

dnl This avoids dumb '-g -O2' autoconf's default, but won't 
dnl prevent user from setting a specific value for CFLAGS
: ${CFLAGS=""}

LT_INIT
AM_PROG_CC_C_O

dnl Check for vala
AM_PROG_VALAC([0.24.0])

AM_MAINTAINER_MODE([enable])

PKG_CHECK_MODULES([GOBJECT], [gobject-2.0 glib-2.0])
PKG_CHECK_MODULES([GIO], [gio-2.0 gio-unix-2.0])
PKG_CHECK_MODULES([GEE], [gee-0.8])
PKG_CHECK_VAR([GEE_PREFIX], [gee-0.8], [prefix])
PKG_CHECK_MODULES([JSON], [json-glib-1.0])
PKG_CHECK_VAR([JSON_PREFIX], [json-glib-1.0], [prefix])
PKG_CHECK_MODULES([TASKLETSYSTEM], [tasklet-system])
PKG_CHECK_VAR([TASKLETSYSTEM_VAPIDIR], [tasklet-system], [vapidir])
PKG_CHECK_MODULES([PTHTASKLET], [pth-tasklet])
PKG_CHECK_VAR([PTHTASKLET_VAPIDIR], [pth-tasklet], [vapidir])

AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([Makefile zcd.pc])
AC_CONFIG_LINKS([test_datagrams:testsuites/test_datagrams/test_datagrams])
AC_CONFIG_LINKS([test_rpcdesign_1:testsuites/test_rpcdesign_1/test_rpcdesign_1])
AC_OUTPUT

