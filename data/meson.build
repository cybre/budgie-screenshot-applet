datadir = get_option('datadir')

install_data('ScreenshotApplet.plugin',
             install_dir: LIB_INSTALL_DIR)

install_data('schemas/com.github.cybre.budgie-screenshot-applet.gschema.xml',
             install_dir: join_paths(datadir, 'glib-2.0' ,'schemas'))

install_data('schemas/com.github.cybre.budgie-screenshot-applet.provider.ftp.gschema.xml',
             install_dir: join_paths(datadir, 'glib-2.0' ,'schemas'))

install_data('com.github.cybre.budgie-screenshot-applet.appdata.xml',
             install_dir: join_paths(datadir, 'appdata'))

meson.add_install_script('meson_post_install.py')