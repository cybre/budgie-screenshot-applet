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
        private Gtk.Switch? switch_primary_monitor;

        [GtkChild]
        private Gtk.Revealer revealer_monitor;

        [GtkChild]
        private Gtk.ComboBox? combobox_monitor;

        [GtkChild]
        private Gtk.SpinButton spinbutton_delay;

        [GtkChild]
        private Gtk.ComboBox? combobox_effect;

        [GtkChild]
        private Gtk.Switch? switch_border;

        public ActualSettings(GLib.Settings? settings)
        {
            //providers
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


            //monitors
            switch_primary_monitor.state_set.connect((state) => {
                revealer_monitor.reveal_child = !state;
                return false;
            });
            revealer_monitor.reveal_child = !switch_primary_monitor.active;

            Gtk.ListStore monitors = new Gtk.ListStore(2, typeof(string), typeof(string));

            Gdk.Screen screen = get_screen();
            int n_monitors = screen.get_n_monitors();
            for (int i = 0; i < n_monitors; i++) {
                string name = screen.get_monitor_plug_name(i) ?? "PLUG_MONITOR_%i".printf(i);
                monitors.append(out iter);
                monitors.set(iter, 0, (string) i, 1, name);
            }

            combobox_monitor.set_model(monitors);

            Gtk.CellRendererText monitor_renderer = new Gtk.CellRendererText();
            combobox_monitor.pack_start(monitor_renderer, true);
            combobox_monitor.add_attribute(monitor_renderer, "text", 1);
            combobox_monitor.set_id_column(0);
            combobox_monitor.active = 0;


            // effects
            Gtk.ListStore effects = new Gtk.ListStore(2, typeof(string), typeof(string));

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

            // binds
            settings.bind("enable-label", switch_label, "active", SettingsBindFlags.DEFAULT);
            settings.bind("enable-local", switch_local, "active", SettingsBindFlags.DEFAULT);
            settings.bind("provider", combobox_provider, "active_id", SettingsBindFlags.DEFAULT);
            settings.bind("use-primary-monitor", switch_primary_monitor, "active", SettingsBindFlags.DEFAULT);
            settings.bind("monitor-to-use", combobox_monitor, "active_id", SettingsBindFlags.DEFAULT);
            settings.bind("delay", spinbutton_delay, "value", SettingsBindFlags.DEFAULT);
            settings.bind("include-border", switch_border, "active", SettingsBindFlags.DEFAULT);
            settings.bind("window-effect", combobox_effect, "active_id", SettingsBindFlags.DEFAULT);
        }
    }

    public class SettingsView : Gtk.Box
    {
        private Gtk.Button back_button;
        private Gtk.Label back_label;
        private Gtk.Box back_box;
        private ActualSettings actual_settings;

        public SettingsView(GLib.Settings? settings, Gtk.Stack stack)
        {

            Object(spacing: 0, orientation: Gtk.Orientation.VERTICAL);

            back_button = new Gtk.Button.from_icon_name("go-previous-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            back_button.relief = Gtk.ReliefStyle.NONE;
            back_button.can_focus = false;
            back_button.tooltip_text = "Go back";

            back_button.clicked.connect(() => {
                stack.set_visible_child_full("new_screenshot_view", Gtk.StackTransitionType.SLIDE_RIGHT);
            });

            back_label = new Gtk.Label("<big>Settings</big>");
            back_label.halign = Gtk.Align.END;
            back_label.use_markup = true;
            back_label.get_style_context().add_class("dim-label");

            back_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            back_box.pack_start(back_button, false, false, 0);
            back_box.pack_end(back_label, true, true, 10);

            actual_settings = new ActualSettings(settings);

            pack_start(back_box, false, false, 0);
            pack_start(actual_settings, true, true, 10);
        }
    }
}