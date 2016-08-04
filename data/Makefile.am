appdatadir = $(datadir)/appdata
appdata_DATA = budgie-screenshot-applet.appdata.xml


EXTRA_DIST = \
	plugin.gresource.xml \
	com.github.cybre.screenshot-applet.gschema.xml \
	settings.ui \
	$(appdata_DATA) \
	screen.png \
	window.png \
	selection.png \
	src/screen.svg \
	src/window.svg \
	src/selection.svg

plugin_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/data --generate-dependencies $(top_srcdir)/data/plugin.gresource.xml)

BUILT_SOURCES = \
	plugin-resources.h \
	plugin-resources.c

# resources
plugin-resources.h: $(top_srcdir)/data/plugin.gresource.xml $(plugin_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-header --c-name screenshot_applet $<

plugin-resources.c: $(top_srcdir)/data/plugin.gresource.xml $(plugin_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-source --c-name screenshot_applet $<
	
gsettings_SCHEMAS = \
	com.github.cybre.screenshot-applet.gschema.xml

@GSETTINGS_RULES@
