/*
 * This file is part of budgie-screenshot-applet
 *
 * Copyright (C) 2016-2017 Stefan Ric <stfric369@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

using ScreenshotApplet.Widgets;
using ScreenshotApplet.Backend;

namespace ScreenshotApplet.Views
{

internal class SettingsContent : Gtk.Bin
{
    public SettingsContent() { }
}

[GtkTemplate (ui = "/com/github/cybre/budgie-screenshot-applet/ui/settings_view.ui")]
private class SettingsView : Gtk.Box
{
    [GtkChild]
    private Gtk.Stack? settings_stack;

    [GtkChild]
    private Gtk.Stack? global_settings_stack;

    [GtkChild]
    private Gtk.Switch? global_delay_switch;

    [GtkChild]
    private Gtk.SpinButton? global_delay_spin;

    [GtkChild]
    private Gtk.Switch? automatic_upload_switch;

    [GtkChild]
    private Gtk.ComboBox upload_provider_combobox;

    [GtkChild]
    private Gtk.Switch? automatic_copy_switch;

    [GtkChild]
    private Gtk.Switch? include_pointer_switch;

    [GtkChild]
    private Gtk.Switch? show_thumbnails_switch;

    [GtkChild]
    private Gtk.Switch? delete_files_switch;

    [GtkChild]
    private Gtk.Switch? open_popover_switch;

    [GtkChild]
    private Gtk.Switch? dont_save_switch;

    [GtkChild]
    private Gtk.Entry? save_destination_entry;

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

    [GtkChild]
    private Gtk.Label? reset_button_label;

    [GtkChild]
    private Gtk.Button? provider_config_button;

    [GtkChild]
    private Gtk.Box? provider_settings_content;

    [GtkChild]
    private Gtk.StackSwitcher? settings_stack_swither;

    private SettingsContent provider_settings_widget;

    private GLib.Settings settings;

    public SettingsView()
    {
        settings_stack.notify["visible-child"].connect(() => {
            switch (settings_stack.get_visible_child_name()) {
                case "global":
                    reset_button_label.set_label(_("Reset global settings"));
                    break;
                case "individual":
                    reset_button_label.set_label(_("Reset individual settings"));
                    break;
                default:
                    break;
            }
        });

        global_settings_stack.notify["visible-child"].connect(() => {
            switch (global_settings_stack.get_visible_child_name()) {
                case "global":
                    reset_button_label.set_label(_("Reset global settings"));
                    settings_stack_swither.set_sensitive(true);
                    break;
                case "provider_settings":
                    reset_button_label.set_label(_("Reset provider settings"));
                    settings_stack_swither.set_sensitive(false);
                    break;
                default:
                    break;
            }
        });

        provider_settings_widget = new SettingsContent();
        provider_settings_content.add(provider_settings_widget);

        upload_provider_combobox.set_model(get_provider_list());
        Gtk.CellRendererText upload_provider_renderer = new Gtk.CellRendererText();
        upload_provider_renderer.max_width_chars = 13;
        upload_provider_renderer.ellipsize = Pango.EllipsizeMode.MIDDLE;
        upload_provider_combobox.pack_start(upload_provider_renderer, true);
        upload_provider_combobox.add_attribute(upload_provider_renderer, "text", 1);
        upload_provider_combobox.set_id_column(0);

        int active = 0;
        screen_monitor_combobox.set_model(BackendUtil.settings_manager.get_monitor_list(out active));
        Gtk.CellRendererText screen_monitor_renderer = new Gtk.CellRendererText();
        screen_monitor_renderer.max_width_chars = 13;
        screen_monitor_renderer.ellipsize = Pango.EllipsizeMode.MIDDLE;
        screen_monitor_combobox.pack_start(screen_monitor_renderer, true);
        screen_monitor_combobox.add_attribute(screen_monitor_renderer, "text", 1);
        screen_monitor_combobox.set_id_column(0);
        screen_monitor_combobox.set_active(active);

        settings = BackendUtil.settings_manager.get_settings();
        settings.bind("use-global-delay", global_delay_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("delay-global", global_delay_spin, "value", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("automatic-upload", automatic_upload_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("upload-provider", upload_provider_combobox, "active_id", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("automatic-copy", automatic_copy_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("include-pointer", include_pointer_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("show-thumbnails", show_thumbnails_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("delete-files", delete_files_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("open-popover", open_popover_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("dont-save", dont_save_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("save-path", save_destination_entry, "text", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("delay-screen", screen_delay_spin, "value", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("monitor-to-use", screen_monitor_combobox, "active_id", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("delay-window", window_delay_spin, "value", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("include-border", window_border_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("delay-selection", selection_delay_spin, "value", GLib.SettingsBindFlags.DEFAULT);

        Gdk.Screen screen = Gdk.Screen.get_default();
        screen.monitors_changed.connect(() => {
            screen_monitor_combobox.set_model(BackendUtil.settings_manager.get_monitor_list(out active));
            screen_monitor_combobox.set_active(active);
        });

        global_delay_switch.state_set.connect((state) => {
            global_delay_spin.set_sensitive(state);
            return false;
        });

        global_delay_spin.set_sensitive(global_delay_switch.state);

        settings.changed["upload-provider"].connect(() => {
            string provider = settings.get_string("upload-provider");
            bool supports_settings = BackendUtil.uploader.get_providers().get(provider).supports_settings();
            provider_config_button.set_sensitive(supports_settings);
        });

        string provider = settings.get_string("upload-provider");
        bool supports_settings = BackendUtil.uploader.get_providers().get(provider).supports_settings();
        provider_config_button.set_sensitive(supports_settings);
    }

    [GtkCallback]
    private void go_back() {
        if (settings_stack.get_visible_child_name() == "global" &&
            global_settings_stack.get_visible_child_name() == "provider_settings") {
            global_settings_stack.set_visible_child_name("global");
            return;
        }

        MainStack.set_page("main_view");
    }

    [GtkCallback]
    private void open_provider_settings() {
        Gtk.Widget? current_widget = provider_settings_widget.get_child();
        if (current_widget != null) {
            current_widget.destroy();
        }
        string provider_name = settings.get_string("upload-provider");
        Providers.IProvider provider = BackendUtil.uploader.get_providers().get(provider_name);
        Gtk.Widget? new_widget = provider.get_settings_widget();
        if (new_widget != null) {
            provider_settings_widget.add(new_widget);
            global_settings_stack.set_visible_child_name("provider_settings");
        }
    }

    [GtkCallback]
    private void close_settings() {
        global_settings_stack.set_visible_child_name("global");
    }

    [GtkCallback]
    private void open_filechooser() {
        MainStack.set_page("file_chooser_view");
    }

    [GtkCallback]
    private void restore_settings() {
        if (global_settings_stack.get_visible_child_name() == "global") {
            BackendUtil.settings_manager.reset_all(settings_stack.get_visible_child_name());
        } else {
            BackendUtil.settings_manager.reset_all("provider");
        }
    }

    private Gtk.ListStore get_provider_list()
    {
        Gtk.ListStore providers = new Gtk.ListStore(2, typeof(string), typeof(string));
        Gtk.TreeIter? iter = null;

        BackendUtil.uploader.get_providers().foreach((key, val) => {
            providers.append(out iter);
            providers.set(iter, 0, key, 1, val.get_name());
        });

        return providers;
    }
}

} // End namespace