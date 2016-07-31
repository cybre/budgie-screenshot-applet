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

namespace ScreenshotApplet
{
    [GtkTemplate (ui = "/com/github/cybre/screenshot-applet/settings.ui")]
    public class ActualSettings : Gtk.Grid
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
            grid_displays.no_show_all = true;

            Gnome.RRScreen rr_screen = new Gnome.RRScreen(get_screen());
            populate_monitors(settings);

            rr_screen.output_connected.connect (() => populate_monitors(settings));
            rr_screen.output_disconnected.connect (() => populate_monitors(settings));
            rr_screen.changed.connect (() => populate_monitors(settings));

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
            combobox_provider.active = 0;
            combobox_provider.set_id_column(0);
        }

        private void populate_monitors(GLib.Settings settings)
        {
            Gtk.ListStore monitors = new Gtk.ListStore(2, typeof(string), typeof(string));
            Gtk.TreeIter iter;
            Gdk.Screen screen = get_screen();
            int n_monitors = screen.get_n_monitors();

            Gnome.RRScreen rr_screen;
            Gnome.RRConfig rr_config;

            try {
                rr_screen = new Gnome.RRScreen(screen);
                rr_config = new Gnome.RRConfig.current(rr_screen);
            } catch (GLib.Error e) {
                stderr.printf(e.message, "\n");
                return;
            }

            int pos = 0;
            int active = 0;

            string[] ms = new string[n_monitors];
            string monitor_to_use = settings.get_string("monitor-to-use");

            foreach (unowned Gnome.RROutputInfo output_info in rr_config.get_outputs()) {
                string name = output_info.get_name();
                string display_name = output_info.get_display_name();
                ms[pos] = name;
                if (monitor_to_use == name) {
                    active = pos;
                }
                monitors.append(out iter);
                monitors.set(iter, 0, name, 1, display_name);
                pos++;
            }

            if (combobox_monitors.get_model() == null) {
                Gtk.CellRendererText monitor_renderer = new Gtk.CellRendererText();
                combobox_monitors.pack_start(monitor_renderer, true);
                combobox_monitors.add_attribute(monitor_renderer, "text", 1);
            }

            combobox_monitors.set_model(monitors);

            if (n_monitors > 1 && active <= n_monitors) {
                combobox_monitors.active = active;
            } else {
                switch_main_display.active = true;
                settings.set_boolean("use-main-display", true);
                combobox_monitors.active = 0;
                settings.set_string("monitor-to-use", ms[0]);
            }

            combobox_monitors.id_column = 0;

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
            combobox_effect.active = 0;
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

            Gtk.Button back_button = new Gtk.Button.from_icon_name("go-previous-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            back_button.relief = Gtk.ReliefStyle.NONE;
            back_button.can_focus = false;
            back_button.tooltip_text = "Go back";

            back_button.clicked.connect(() => {
                stack.visible_child_name = "new_screenshot_view";
            });

            Gtk.Label back_label = new Gtk.Label("<big>Settings</big>");
            back_label.halign = Gtk.Align.END;
            back_label.use_markup = true;
            back_label.get_style_context().add_class("dim-label");

            Gtk.Box back_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            back_box.pack_start(back_button, false, false, 0);
            back_box.pack_end(back_label, true, true, 10);

            ActualSettings actual_settings = ActualSettings.instance(settings);

            pack_start(back_box, false, false, 0);
            pack_start(actual_settings, true, true, 10);
        }

        public static unowned SettingsView instance(GLib.Settings? settings, Gtk.Stack stack) {
            return _instance.once(() => { return new SettingsView(settings, stack); });
        }
    }
}