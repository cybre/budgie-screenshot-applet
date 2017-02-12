gnome = import('gnome')

LOCALE_DIR = get_option('prefix') + '/' + get_option('localedir')
LIB_INSTALL_DIR = get_option('prefix') + '/' + get_option('libdir') + '/budgie-desktop/plugins/budgie-screenshot-applet'

res = gnome.compile_resources('bsa-resources', '../data/budgie-screenshot-applet.gresource.xml', source_dir: '../data')

conf_data = configuration_data()
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
               'Widgets/QuickSettings.vala',
               'Widgets/ScreenshotModeButton.vala',
               'Backend/BackendUtil.vala',
               'Backend/ScreenshotManager.vala',
               'Backend/SettingsManager.vala',
               'Backend/Uploader.vala',
               'Backend/Providers/IProvider.vala',
               'Backend/Providers/Ibin.vala',
               'Backend/Providers/Imgur.vala',
               'Backend/Providers/NilxNil.vala',
               'Backend/ScreenshotMode/ScreenshotAbstract.vala',
               'Backend/ScreenshotMode/Screen.vala',
               'Backend/ScreenshotMode/Window.vala',
               'Backend/ScreenshotMode/Selection.vala',
               res]

bsa_deps = [dependency('budgie-1.0', version: '>=2'),
            dependency('gnome-desktop-3.0'),
            dependency('json-glib-1.0'),
            dependency('libsoup-2.4')]

bsa_vala_args = ['--pkg=config',
                 '--vapidir=../vapi',
                 '--gresources=../data/budgie-screenshot-applet.gresource.xml',
                 '--target-glib=2.38',
                 '--enable-deprecated']

bsa_c_args = ['-include', 'config.h',
              '-DGNOME_DESKTOP_USE_UNSTABLE_API']

shared_library('screenshotapplet', bsa_sources,
               dependencies: bsa_deps,
               vala_args: bsa_vala_args,
               c_args: bsa_c_args,
               install: true,
               install_dir: LIB_INSTALL_DIR)

install_data('ScreenshotApplet.plugin', install_dir: LIB_INSTALL_DIR)