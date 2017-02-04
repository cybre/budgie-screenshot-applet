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

using ScreenshotApplet.Backend;

namespace ScreenshotApplet.Widgets
{

public class QuickSettings : Gtk.Stack
{
    private GLib.Settings settings;
    private Gtk.ComboBox screen_monitor_combobox;
    private Gtk.SpinButton selection_delay_spin;
    private Gtk.SpinButton screen_delay_spin;
    private Gtk.SpinButton window_delay_spin;

    public QuickSettings()
    {
        GLib.Object(transition_type: Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);

        this.settings = BackendUtil.settings_manager.get_settings();

        // Screen
        Gtk.Grid screen_grid = construct_grid();
        this.add_named(screen_grid, "screen");

        Gtk.Label screen_delay_label = construct_label(_("Delay"), _("Screenshot delay"));
        screen_grid.attach(screen_delay_label, 0, 0, 1, 1);
        screen_delay_spin = new Gtk.SpinButton.with_range(0, 60, 1);
        screen_grid.attach(screen_delay_spin, 0, 1, 1, 1);

        settings.bind("delay-screen", screen_delay_spin, "value", SettingsBindFlags.DEFAULT);

        Gtk.Label screen_monitor_label = construct_label(_("Monitor"), _("Monitor to use"));
        screen_grid.attach(screen_monitor_label, 1, 0, 1, 1);
        int active;
        screen_monitor_combobox = new Gtk.ComboBox.with_model(BackendUtil.settings_manager.get_monitor_list(out active));
        Gtk.CellRendererText screen_monitor_renderer = new Gtk.CellRendererText();
        screen_monitor_renderer.max_width_chars = 13;
        screen_monitor_renderer.ellipsize = Pango.EllipsizeMode.MIDDLE;
        screen_monitor_combobox.pack_start(screen_monitor_renderer, true);
        screen_monitor_combobox.add_attribute(screen_monitor_renderer, "text", 1);
        screen_monitor_combobox.set_id_column(0);
        screen_monitor_combobox.set_active(active);
        screen_grid.attach(screen_monitor_combobox, 1, 1, 1, 1);

        settings.bind("monitor-to-use", screen_monitor_combobox, "active_id", SettingsBindFlags.DEFAULT);

        // Window
        Gtk.Grid window_grid = construct_grid();
        this.add_named(window_grid, "window");

        Gtk.Label window_delay_label = construct_label(_("Delay"), _("Screenshot delay"));
        window_grid.attach(window_delay_label, 0, 0, 1, 1);
        window_delay_spin = new Gtk.SpinButton.with_range(0, 60, 1);
        window_grid.attach(window_delay_spin, 0, 1, 1, 1);

        settings.bind("delay-window", window_delay_spin, "value", SettingsBindFlags.DEFAULT);

        Gtk.Label window_border_label = construct_label(_("Include border"), _("Wether to include the window border"));
        window_grid.attach(window_border_label, 1, 0, 1, 1);
        Gtk.Switch window_border_switch = new Gtk.Switch();
        window_border_switch.set_halign(Gtk.Align.START);
        window_grid.attach(window_border_switch, 1, 1, 1, 1);

        settings.bind("include-border", window_border_switch, "active", SettingsBindFlags.DEFAULT);

        // Selection
        Gtk.Grid selection_grid = construct_grid();
        this.add_named(selection_grid, "selection");

        Gtk.Label selection_delay_label = construct_label(_("Delay"), _("Screenshot delay"));
        selection_grid.attach(selection_delay_label, 0, 0, 1, 1);
        selection_delay_spin = new Gtk.SpinButton.with_range(0, 60, 1);
        selection_delay_spin.set_halign(Gtk.Align.START);
        selection_grid.attach(selection_delay_spin, 0, 1, 1, 1);

        settings.bind("delay-selection", selection_delay_spin, "value", SettingsBindFlags.DEFAULT);

        Gdk.Screen screen = Gdk.Screen.get_default();
        screen.monitors_changed.connect(() => {
            screen_monitor_combobox.set_model(BackendUtil.settings_manager.get_monitor_list(out active));
            screen_monitor_combobox.set_active(active);
        });;
    }

    private Gtk.Grid construct_grid()
    {
        Gtk.Grid grid = new Gtk.Grid();
        grid.get_style_context().add_class("quick-settings");
        grid.set_row_spacing(5);
        grid.set_column_spacing(40);
        grid.set_column_homogeneous(true);

        return grid;
    }

    private Gtk.Label construct_label(string text, string tooltip)
    {
        Gtk.Label label = new Gtk.Label(text);
        label.set_halign(Gtk.Align.START);
        label.set_tooltip_text(tooltip);

        return label;
    }
}

} // End namespace