/*
 * This file is part of screenshot-applet
 *
 * Copyright (C) 2016-2017 Stefan Ric <stfric369@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

using ScreenshotApplet.Backend;
using ScreenshotApplet.Widgets;

namespace ScreenshotApplet.Views
{

[GtkTemplate (ui = "/com/github/cybre/budgie-screenshot-applet/ui/main_view.ui")]
public class MainView : Gtk.Box
{
    [GtkChild]
    public Gtk.Entry? title_entry;

    [GtkChild]
    private Gtk.Box? screenshot_buttons_box;

    [GtkChild]
    public Gtk.Revealer? quick_settings_revealer;

    [GtkChild]
    private Gtk.Stack? quick_settings_stack;

    [GtkChild]
    private Gtk.SpinButton? screen_delay_spin;

    [GtkChild]
    private Gtk.ComboBox? screen_monitor_combobox;

    [GtkChild]
    private Gtk.SpinButton? window_delay_spin;

    [GtkChild]
    private Gtk.Switch? window_border_switch;

    [GtkChild]
    private Gtk.SpinButton? selection_delay_spin;

    private static MainView? _instance = null;
    public static Gtk.Entry _title_entry;

    public MainView()
    {
        MainView._instance = this;

        _title_entry = title_entry;

        GLib.Settings settings = BackendUtil.settings_manager.get_settings();

        int active = 0;
        screen_monitor_combobox.set_model(BackendUtil.settings_manager.get_monitor_list(out active));
        Gtk.CellRendererText screen_monitor_renderer = new Gtk.CellRendererText();
        screen_monitor_renderer.max_width_chars = 13;
        screen_monitor_renderer.ellipsize = Pango.EllipsizeMode.MIDDLE;
        screen_monitor_combobox.pack_start(screen_monitor_renderer, true);
        screen_monitor_combobox.add_attribute(screen_monitor_renderer, "text", 1);
        screen_monitor_combobox.set_id_column(0);
        screen_monitor_combobox.set_active(active);

        settings.bind("delay-screen", screen_delay_spin, "value", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("monitor-to-use", screen_monitor_combobox, "active_id", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("delay-window", window_delay_spin, "value", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("include-border", window_border_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("delay-selection", selection_delay_spin, "value", GLib.SettingsBindFlags.DEFAULT);

        Gdk.Screen screen = Gdk.Screen.get_default();
        screen.monitors_changed.connect(() => {
            screen_monitor_combobox.set_model(BackendUtil.settings_manager.get_monitor_list(out active));
            screen_monitor_combobox.set_active(active);
        });;
    }

    [GtkCallback]
    private bool screenshot_button_callback(Gtk.Widget widget, Gdk.EventButton event)
    {
        string mode_string = widget.name;
        ScreenshotType mode = ScreenshotType.SCREEN;

        switch (mode_string) {
            case "screen":
                mode = ScreenshotType.SCREEN;
                break;
            case "window":
                mode = ScreenshotType.WINDOW;
                break;
            case "selection":
                mode = ScreenshotType.SELECTION;
                break;
            default:
                break;
        }
        if (event.button == 1) {
            contract_quick_settings(false);
            IndicatorWindow.get_instance().hide();
            BackendUtil.screenshot_manager.take_screenshot.begin(mode, title_entry.get_text());
        } else if (event.button == 3) {
            if (quick_settings_stack.get_visible_child_name() == mode_string) {
                toggle_quick_settings();
            } else {
                expand_quick_settings();
                quick_settings_stack.set_visible_child_name(mode_string);
            }
        }

        return true;
    }

    private void toggle_quick_settings()
    {
        if (!quick_settings_revealer.get_child_revealed()) {
            expand_quick_settings();
        } else {
            contract_quick_settings();
        }
    }

    private void expand_quick_settings()
    {
        quick_settings_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_UP);
        quick_settings_revealer.set_reveal_child(true);
    }

    public static void contract_quick_settings(bool animate = true) {
        if (!animate) {
            _instance.quick_settings_revealer.set_transition_type(Gtk.RevealerTransitionType.NONE);
        }
        _instance.quick_settings_revealer.set_reveal_child(false);
    }

    [GtkCallback]
    private void clear_title_entry() {
        title_entry.set_text("");
    }

    [GtkCallback]
    private void open_settings() {
        MainStack.set_page("settings_view");
    }

    [GtkCallback]
    private void open_history() {
        MainStack.set_page("history_view");
    }

    public void disable_buttons() {
        screenshot_buttons_box.set_sensitive(false);
    }

    public void enable_buttons() {
        screenshot_buttons_box.set_sensitive(true);
    }

    public static unowned MainView get_instance() {
        return _instance;
    }
}

} // End namespace
