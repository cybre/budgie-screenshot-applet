plugindir = $(libdir)/budgie-desktop/plugins

screenshotappletdir = $(plugindir)/screenshot-applet

plugin_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/screenshot-applet --generate-dependencies $(top_srcdir)/screenshot-applet/plugin.gresource.xml)

# resources
plugin-resources.h: $(top_srcdir)/screenshot-applet/plugin.gresource.xml $(plugin_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/screenshot-applet --generate-header --c-name screenshot_applet $<

plugin-resources.c: $(top_srcdir)/screenshot-applet/plugin.gresource.xml $(plugin_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/screenshot-applet --generate-source --c-name screenshot_applet $<

BUILT_SOURCES = \
	plugin-resources.h \
	plugin-resources.c

CLEANFILES = \
	$(BUILT_SOURCES)

EXTRA_DIST = \
	com.github.cybre.screenshot-applet.gschema.xml \
	plugin.gresource.xml \
	settings.ui

screenshotapplet_DATA = \
	ScreenshotApplet.plugin

screenshotapplet_LTLIBRARIES = \
	libscreenshotapplet.la

libscreenshotapplet_la_SOURCES = \
	ScreenshotApplet.vala \
	plugin-resources.h \
	plugin-resources.c

libscreenshotapplet_la_CFLAGS = \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(JSON_CFLAGS) \
	$(REST_CFLAGS) \
	$(LIBNOTIFY_CFLAGS)

libscreenshotapplet_la_LIBADD = \
	$(BUDGIE_PLUGIN_LIBS) \
	$(JSON_LIBS) \
	$(REST_LIBS) \
	$(LIBNOTIFY_LIBS)

libscreenshotapplet_la_LDFLAGS = \
	-module \
	-avoid-version \
	-shared \
	$(AM_LDFLAGS)

libscreenshotapplet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libpeas-1.0 \
	--pkg PeasGtk-1.0 \
	--pkg budgie-1.0 \
	--pkg json-glib-1.0 \
	--pkg rest-0.7 \
	--pkg libnotify \
	--vapidir ../vapi \
	--gresources=${srcdir}/plugin.gresource.xml \
	--target-glib=2.38

gsettings_SCHEMAS = \
	com.github.cybre.screenshot-applet.gschema.xml
	
@GSETTINGS_RULES@
