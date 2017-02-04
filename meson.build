project('budgie-screenshot-applet', 'vala', 'c',
        version: '0.4.0',
        meson_version: '>=0.36.0',
        license: 'GPL2')

LOCALE_DIR = get_option('prefix') + '/' + get_option('localedir')
LIB_INSTALL_DIR = get_option('prefix') + '/' + get_option('libdir') + '/budgie-desktop/plugins/budgie-screenshot-applet'

bsa_deps = [dependency('budgie-1.0', version: '>=2'),
            dependency('gnome-desktop-3.0'),
            dependency('json-glib-1.0'),
            dependency('libsoup-2.4')]

subdir('src')
subdir('data')
subdir('po')