AC_INIT([budgie-screenshot-applet],[0.3.9.1],[stfric369@gmail.com],[budgie-screenshot-applet],[https://github.com/cybre/budgie-screenshot-applet])
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([-Wno-portability no-dist-gzip dist-xz foreign subdir-objects])
AC_PROG_CC
AC_PROG_CC_STDC
LT_PREREQ(2.2)
AC_CONFIG_HEADERS([config.h])
AC_PREFIX_DEFAULT(/usr/local)
AM_SILENT_RULES([yes])
LT_INIT([disable-static])
AC_CONFIG_MACRO_DIR([m4])
AM_GNU_GETTEXT([external])

GLIB_GSETTINGS

m4_define([budgie_required_version], [2])

# Note budgie-1.0 depends on peas, gtk, etc. Sorta your package managers
# business to make sure those deps are satisfied.
# Also note this is just for the C and Vala subprojects!
PKG_CHECK_MODULES(BUDGIE_PLUGIN,
        budgie-1.0 >= budgie_required_version
)

PKG_CHECK_MODULES(GNOME,
        gnome-desktop-3.0 >= 3.18.0
)

PKG_CHECK_MODULES(JSON,
        json-glib-1.0 >= 1.0.0
)

PKG_CHECK_MODULES(REST,
        rest-0.7 >= 0.7
)

# Required only for Vala applets.
AM_PROG_VALAC([0.28], [], [AC_MSG_ERROR([valac is required to build Vala applets])])
     
IT_PROG_INTLTOOL([0.50.0])
GETTEXT_PACKAGE=budgie-screenshot-applet
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE",
                   [The prefix for our gettext translation domains.])

AC_CONFIG_FILES([Makefile
                budgie-screenshot-applet/Makefile
                data/Makefile
                po/Makefile.in])

AC_OUTPUT

AM_GLIB_GNU_GETTEXT

AC_MSG_RESULT([
        budgie-screenshot-applet $VERSION
        ========

        prefix:                 ${prefix}
        libdir:                 ${libdir}
        sysconfdir:             ${sysconfdir}
        exec_prefix:            ${exec_prefix}
        bindir:                 ${bindir}
        datarootdir:            ${datarootdir}

        compiler:               ${CC}
        cflags:                 ${CFLAGS}
        ldflags:                ${LDFLAGS}
])
