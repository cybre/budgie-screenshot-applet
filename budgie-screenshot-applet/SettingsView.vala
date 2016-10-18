/*
 * This file is part of screenshot-applet
 *
 * Copyright (C) 2016 Stefan Ric <stfric369@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

[GtkTemplate (ui = "/com/github/cybre/screenshot-applet/settings.ui")]
internal class ActualSettings : Gtk.Grid
{
    [GtkChild]
    private Gtk.Switch? switch_label;

    [GtkChild]
    private Gtk.Switch? switch_local;

    [GtkChild]
    private Gtk.ComboBox? combobox_provider;

    [GtkChild]
    private Gtk.Grid? grid_displays;

    [GtkChild]
    private Gtk.Grid? grid_monitors;

    [GtkChild]
    private Gtk.Switch? switch_main_display;

    [GtkChild]
    private Gtk.ComboBox? combobox_monitors;

    [GtkChild]
    private Gtk.SpinButton spinbutton_delay;

    [GtkChild]
    private Gtk.ComboBox? combobox_effect;

    [GtkChild]
    private Gtk.Switch? switch_border;

    private static GLib.Once<ActualSettings> _instance;

    public ActualSettings(GLib.Settings? settings)
    {
        //providers
        populate_providers();

        //monitors
        grid_displays.set_no_show_all(true);
        Gdk.Screen screen = Gdk.Screen.get_default();
        populate_monitors(settings);
        screen.monitors_changed.connect(() => { populate_monitors(settings); });
        switch_main_display.state_set.connect((state) => {
            grid_monitors.sensitive = !state;
            return false;
        });
        grid_monitors.sensitive = !switch_main_display.active;


        // effects
        populate_effects();

        // binds
        settings.bind("enable-label", switch_label, "active", SettingsBindFlags.DEFAULT);
        settings.bind("enable-local", switch_local, "active", SettingsBindFlags.DEFAULT);
        settings.bind("provider", combobox_provider, "active_id", SettingsBindFlags.DEFAULT);
        settings.bind("use-main-display", switch_main_display, "active", SettingsBindFlags.DEFAULT);
        settings.bind("monitor-to-use", combobox_monitors, "active_id", SettingsBindFlags.DEFAULT);
        settings.bind("delay", spinbutton_delay, "value", SettingsBindFlags.DEFAULT);
        settings.bind("include-border", switch_border, "active", SettingsBindFlags.DEFAULT);
        settings.bind("window-effect", combobox_effect, "active_id", SettingsBindFlags.DEFAULT);
    }

    private void populate_providers()
    {
        Gtk.ListStore providers = new Gtk.ListStore(2, typeof(string), typeof(string));
        Gtk.TreeIter iter;

        providers.append(out iter);
        providers.set(iter, 0, "imgur", 1, "Imgur.com");
        providers.append(out iter);
        providers.set(iter, 0, "ibin", 1, "Ibin.co");
        combobox_provider.set_model(providers);

        Gtk.CellRendererText renderer = new Gtk.CellRendererText();
        combobox_provider.pack_start(renderer, true);
        combobox_provider.add_attribute(renderer, "text", 1);
        combobox_provider.set_active(0);
        combobox_provider.set_id_column(0);
    }

    private void populate_monitors(GLib.Settings settings)
    {
        Gtk.ListStore monitors = new Gtk.ListStore(2, typeof(string), typeof(string));
        Gtk.TreeIter iter;
        Gdk.Screen screen = Gdk.Screen.get_default();
        int n_monitors = screen.get_n_monitors();

        Gnome.RRScreen rr_screen;
        Gnome.RRConfig rr_config;

        try {
            rr_screen = new Gnome.RRScreen(screen);
            rr_config = new Gnome.RRConfig.current(rr_screen);
        } catch (GLib.Error e) {
            warning(e.message);
            return;
        }

        int pos = 0;
        int active = 0;

        string[] names = new string[n_monitors];
        string monitor_to_use = settings.get_string("monitor-to-use");

        foreach (unowned Gnome.RROutputInfo output_info in rr_config.get_outputs()) {
            if (output_info.is_active()) {
                string name = output_info.get_name();
                string display_name = output_info.get_display_name();
                names[pos] = name;
                if (monitor_to_use == name) {
                    active = pos;
                }
                monitors.append(out iter);
                monitors.set(iter, 0, name, 1, display_name);
                pos++;
            }
        }

        if (combobox_monitors.get_model() == null) {
            Gtk.CellRendererText monitor_renderer = new Gtk.CellRendererText();
            monitor_renderer.max_width_chars = 20;
            monitor_renderer.ellipsize = Pango.EllipsizeMode.MIDDLE;
            combobox_monitors.pack_start(monitor_renderer, true);
            combobox_monitors.add_attribute(monitor_renderer, "text", 1);
        }

        combobox_monitors.set_model(monitors);

        if (n_monitors > 1 && active <= n_monitors) {
            combobox_monitors.set_active(active);
        } else {
            switch_main_display.set_active(true);
            settings.set_boolean("use-main-display", true);
            combobox_monitors.set_active(0);
            settings.set_string("monitor-to-use", names[0]);
        }

        combobox_monitors.set_id_column(0);

        grid_displays.visible = (n_monitors > 1);
    }

    private void populate_effects()
    {
        Gtk.ListStore effects = new Gtk.ListStore(2, typeof(string), typeof(string));
        Gtk.TreeIter iter;

        effects.append(out iter);
        effects.set(iter, 0, "none", 1, "None");
        effects.append(out iter);
        effects.set(iter, 0, "shadow", 1, "Drop shadow");
        effects.append(out iter);
        effects.set(iter, 0, "border", 1, "Border");
        effects.append(out iter);
        effects.set(iter, 0, "vintage", 1, "Vintage");

        combobox_effect.set_model(effects);
        Gtk.CellRendererText renderer1 = new Gtk.CellRendererText();
        combobox_effect.pack_start(renderer1, true);
        combobox_effect.add_attribute(renderer1, "text", 1);
        combobox_effect.set_active(0);
        combobox_effect.set_id_column(0);
    }

    public static unowned ActualSettings instance(GLib.Settings? settings) {
        return _instance.once(() => { return new ActualSettings(settings); });
    }
}

public class SettingsView : Gtk.Box
{
    private static GLib.Once<SettingsView> _instance;

    public SettingsView(GLib.Settings? settings, Gtk.Stack stack)
    {

        Object(spacing: 0, orientation: Gtk.Orientation.VERTICAL);

        Gtk.Button back_button = new Gtk.Button.with_label("Back");
        back_button.set_can_focus(false);
        back_button.set_tooltip_text("Go back");

        back_button.clicked.connect(() => { stack.set_visible_child_name("new_screenshot_view"); });

        Gtk.Label back_label = new Gtk.Label("<span font=\"11\">Settings</span>");
        back_label.set_halign(Gtk.Align.END);
        back_label.set_use_markup(true);
        back_label.get_style_context().add_class("dim-label");

        Gtk.Box back_subbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        back_subbox.margin = 10;
        back_subbox.pack_start(back_button, false, false, 0);
        back_subbox.pack_end(back_label, true, true, 0);

        Gtk.Box back_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        back_box.pack_start(back_subbox, true, true, 0);
        back_box.pack_end(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), true, true, 0);

        ActualSettings actual_settings = ActualSettings.instance(settings);

        Gtk.Button reset_button = new Gtk.Button.with_label("Reset to default");
        reset_button.set_relief(Gtk.ReliefStyle.NONE);
        reset_button.set_can_focus(false);
        reset_button.get_child().margin = 5;
        reset_button.get_style_context().add_class("bottom-button");

        reset_button.clicked.connect(() => {
            settings.reset("enable-label");
            settings.reset("enable-local");
            settings.reset("provider");
            settings.reset("use-main-display");
            settings.reset("monitor-to-use");
            settings.reset("delay");
            settings.reset("include-border");
            settings.reset("window-effect");
        });

        pack_start(back_box, false, false, 0);
        pack_start(actual_settings, true, true, 10);
        pack_start(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), true, true, 0);
        pack_start(reset_button, false, false, 0);
    }

    public static unowned SettingsView instance(GLib.Settings? settings, Gtk.Stack stack) {
        return _instance.once(() => { return new SettingsView(settings, stack); });
    }
}