gnome = import('gnome')

LOCALE_DIR = join_paths(get_option('prefix'), get_option('localedir'))

data_dir = join_paths(meson.source_root(), 'data')
vapi_dir = join_paths(meson.source_root(), 'vapi')

gresource_file = join_paths(data_dir, 'com.github.cybre.budgie-screenshot-applet.gresource.xml')
res = gnome.compile_resources('bsa-resources', gresource_file, source_dir: data_dir)

conf_data = configuration_data()
conf_data.set('PACKAGE_NAME', meson.project_name())
conf_data.set('LOCALE_DIR', LOCALE_DIR)
configure_file(input: 'config.h.in', output: 'config.h', configuration: conf_data)

bsa_sources = ['ScreenshotApplet.vala',
               'Views/FileChooserView.vala',
               'Views/HistoryView.vala',
               'Views/MainView.vala',
               'Views/SettingsView.vala',
               'Widgets/AreaSelectionWindow.vala',
               'Widgets/AutomaticScrollBox.vala',
               'Widgets/HistoryItem.vala',
               'Widgets/IndicatorIcon.vala',
               'Widgets/IndicatorWindow.vala',
               'Widgets/MainStack.vala',
               'Widgets/ScreenshotModeButton.vala',
               'Backend/BackendUtil.vala',
               'Backend/ScreenshotManager.vala',
               'Backend/SettingsManager.vala',
               'Backend/Uploader.vala',
               'Backend/Providers/IProvider.vala',
               'Backend/Providers/FTP.vala',
               'Backend/Providers/Ibin.vala',
               'Backend/Providers/Imgur.vala',
               'Backend/Providers/NilxNil.vala',
               'Backend/Providers/Tempfiles.vala',
               'Backend/ScreenshotMode/ScreenshotAbstract.vala',
               'Backend/ScreenshotMode/Screen.vala',
               'Backend/ScreenshotMode/Window.vala',
               'Backend/ScreenshotMode/Selection.vala',
               res]

dep_gnome = dependency('gnome-desktop-3.0')

posix_dep = meson.get_compiler('vala').find_library('posix')

bsa_deps = [dependency('gtk+-3.0', version: '>=3.18'),
            dependency('budgie-1.0', version: '>=2'),
            dep_gnome,
            dependency('json-glib-1.0'),
            dependency('libsoup-2.4'),
            dependency('libcurl'),
            posix_dep]

bsa_vala_args = ['--pkg=config',
                 '--thread',
                 '--vapidir=' + vapi_dir,
                 '--gresources=' + gresource_file,
                 '--target-glib=2.38',
                 '--enable-deprecated']

if dep_gnome.version().version_compare('>=3.21.0')
    rpath = dep_gnome.get_pkgconfig_variable('typelibdir')
    bsa_vala_args += ['--girdir', rpath]
endif

bsa_c_args = ['-include', 'config.h',
              '-DGNOME_DESKTOP_USE_UNSTABLE_API']

shared_library('screenshotapplet', bsa_sources,
               dependencies: bsa_deps,
               vala_args: bsa_vala_args,
               c_args: bsa_c_args,
               install: true,
               install_dir: LIB_INSTALL_DIR)