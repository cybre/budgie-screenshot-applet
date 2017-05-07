/*
 * This file is part of budgie-screenshot-applet
 *
 * Copyright (C) 2016 Stefan Ric <stfric369@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace ScreenshotApplet
{

public class Plugin : GLib.Object, Budgie.Plugin
{
    public Budgie.Applet get_panel_widget(string uuid) {
        return new Applet(uuid);
    }
}

public class Applet : Budgie.Applet
{
    private Gtk.EventBox event_box;
    private Widgets.IndicatorWindow? popover = null;
    private GLib.Settings? settings = null;
    private Backend.BackendUtil? backend_util = null;
    private unowned Budgie.PopoverManager? manager = null;
    public string uuid { public set; public get; }

    private static Applet? _instance = null;

    public Applet(string uuid)
    {
        GLib.Object(uuid: uuid);

        Applet._instance = this;

        // Initialise gettext
        GLib.Intl.setlocale(GLib.LocaleCategory.ALL, "");
        GLib.Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
        GLib.Intl.textdomain(Config.GETTEXT_PACKAGE);

        // Get our settings
        settings_schema = "com.github.cybre.budgie-screenshot-applet";
        settings_prefix = "/com/github/cybre/budgie-screenshot-applet";
        this.settings = get_applet_settings(uuid);

        backend_util = new Backend.BackendUtil(this.settings);

        // Bake in our theme
        Gdk.Screen screen = this.get_display().get_default_screen();
        Gtk.CssProvider provider = new Gtk.CssProvider();
        string gtk_version = @"$(Gtk.get_major_version()).$(Gtk.get_minor_version())";
        string style_file = "/com/github/cybre/budgie-screenshot-applet/style/style.css";
        if (gtk_version == "3.18") {
            style_file = "/com/github/cybre/budgie-screenshot-applet/style/style-318.css";
        }
        GLib.Idle.add(() => {
            provider.load_from_resource(style_file);
            Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            return false;
        });

        event_box = new Gtk.EventBox();
        this.add(event_box);

        Widgets.IndicatorIcon icon_widget = new Widgets.IndicatorIcon();
        event_box.add(icon_widget);

        popover = new Widgets.IndicatorWindow(event_box);

        this.show_all();

        event_box.button_press_event.connect((e)=> {
            if (e.button != 1) {
                return Gdk.EVENT_PROPAGATE;
            }

            if (popover.get_visible()) {
                popover.hide();
            } else {
                if (icon_widget.get_style_context().has_class("alert") ||
                Backend.BackendUtil.uploader.is_upload_in_progress()) {
                    Widgets.MainStack.set_page("history_view", false);
                }
                icon_widget.get_style_context().remove_class("alert");
                open_popover();
            }

            return Gdk.EVENT_STOP;
        });
    }

    public override bool supports_settings() {
        return false;
    }

    public override void update_popovers(Budgie.PopoverManager? manager)
    {
        manager.register_popover(event_box, popover);
        this.manager = manager;
    }

    public void open_popover() {
        this.manager.show_popover(event_box);
    }

    public static unowned Applet? get_instance() {
        return _instance;
    }
}

} // End namespace

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
    Peas.ObjectModule objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin),
        typeof(ScreenshotApplet.Plugin));
}
