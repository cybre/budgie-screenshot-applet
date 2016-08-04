plugindir = $(libdir)/budgie-desktop/plugins

screenshotappletdir = $(plugindir)/screenshot-applet

screenshotapplet_DATA = \
	ScreenshotApplet.plugin

screenshotapplet_LTLIBRARIES = \
	libscreenshotapplet.la

libscreenshotapplet_la_SOURCES = \
	ScreenshotApplet.vala \
	NewScreenshotView.vala \
	CountdownView.vala \
	UploadingView.vala \
	UploadDoneView.vala \
	ErrorView.vala \
	AutomaticScrollBox.vala \
	HistoryView.vala \
	HistoryViewItem.vala \
	SettingsView.vala \
	../data/plugin-resources.h \
	../data/plugin-resources.c

libscreenshotapplet_la_CFLAGS = \
	$(BUDGIE_PLUGIN_CFLAGS) \
	$(GNOME_CFLAGS) \
	$(JSON_CFLAGS) \
	$(REST_CFLAGS) \
	$(GEE_CFLAGS) \
	-DGNOME_DESKTOP_USE_UNSTABLE_API

libscreenshotapplet_la_LIBADD = \
	$(BUDGIE_PLUGIN_LIBS) \
	$(GNOME_LIBS) \
	$(JSON_LIBS) \
	$(REST_LIBS) \
	$(GEE_LIBS)

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
	--pkg gee-1.0 \
	--pkg gnome-desktop-3.0 \
	--vapidir ${top_srcdir}/vapi \
	--gresources=${top_srcdir}/data/plugin.gresource.xml \
	--target-glib=2.38
