EXTRA_DIST = \
	screenshot-applet-images.gresource.xml \
	screen.png \
	window.png \
	selection.png \
	src/screen.svg \
	src/window.svg \
	src/selection.svg

screenshot_applet_images = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/data --generate-dependencies $(top_srcdir)/data/screenshot-applet-images.gresource.xml)

BUILT_SOURCES = \
	screenshot-applet-images.h \
	screenshot-applet-images.c


# resources
screenshot-applet-images.h: $(top_srcdir)/data/screenshot-applet-images.gresource.xml $(screenshot_applet_images)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-header --c-name screenshot_applet_images $<

screenshot-applet-images.c: $(top_srcdir)/data/screenshot-applet-images.gresource.xml $(screenshot_applet_images)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-source --c-name screenshot_applet_images $<
