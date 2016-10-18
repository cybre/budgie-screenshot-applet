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

public class ScreenshotApplet.HistoryViewItem : Gtk.Revealer
{
    private GLib.Settings gnome_settings;
    private GLib.DateTime time;
    private Gtk.Label url_label;
    private Gtk.Entry title_entry;
    private Gtk.Label title_label;
    private string title;
    private string url;
    private int64 timestamp;

    public signal void copy(string url);
    public signal void deletion();

    public HistoryViewItem(int n, GLib.Settings settings)
    {
        set_can_focus(false);
        set_transition_type(Gtk.RevealerTransitionType.NONE);
        set_transition_duration(500);

        GLib.Variant history_list = settings.get_value("history");
        GLib.Variant history_entry = history_list.get_child_value(n);
        history_entry.get("(xss)", out timestamp, out title, out url);

        time = new GLib.DateTime.from_unix_local(timestamp);

        if (title == "") title = "Untitled";
        title_label = new Gtk.Label("<b>%s</b>".printf(title.strip()));
        title_label.set_use_markup(true);
        title_label.set_halign(Gtk.Align.START);
        title_label.set_max_width_chars(23);
        title_label.set_ellipsize(Pango.EllipsizeMode.END);

        Gtk.Button title_edit_button = new Gtk.Button.from_icon_name(
            "accessories-text-editor-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        title_edit_button.set_relief(Gtk.ReliefStyle.NONE);
        title_edit_button.set_can_focus(false);
        title_edit_button.set_tooltip_text("Edit Title");
        title_edit_button.get_style_context().add_class("action-button");

        Gtk.Box title_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        title_box.pack_start(title_label, true, true, 0);
        title_box.pack_end(title_edit_button, false, false, 0);

        title_entry = new Gtk.Entry();
        title_entry.placeholder_text = "New Title";
        title_entry.set_max_length(50);
        title_entry.set_margin_end(10);

        title_entry.set_icon_from_icon_name(
            Gtk.EntryIconPosition.SECONDARY, "edit-clear-symbolic");
        title_entry.set_icon_tooltip_text(Gtk.EntryIconPosition.SECONDARY, "Clear");
        title_entry.icon_press.connect(() => { title_entry.text = ""; });

        Gtk.Button title_apply_button = new Gtk.Button.from_icon_name(
            "emblem-ok-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        title_apply_button.set_relief(Gtk.ReliefStyle.NONE);
        title_apply_button.set_can_focus(false);
        title_apply_button.set_tooltip_text("Apply Changes");
        title_apply_button.get_style_context().add_class("action-button");

        Gtk.Box title_edit_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        title_edit_box.pack_start(title_entry, true, true, 0);
        title_edit_box.pack_end(title_apply_button, false, false, 0);

        Gtk.Stack title_stack = new Gtk.Stack();
        title_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
        title_stack.add_named(title_box, "title_box");
        title_stack.add_named(title_edit_box, "title_edit_box");

        Gtk.Button copy_button = new Gtk.Button.from_icon_name(
            "edit-copy-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        copy_button.set_relief(Gtk.ReliefStyle.NONE);
        copy_button.set_can_focus(false);
        copy_button.set_tooltip_text("Copy Screenshot URL");
        copy_button.get_style_context().add_class("action-button");

        Gtk.Image copy_ok_image = new Gtk.Image.from_icon_name(
            "emblem-ok-symbolic", Gtk.IconSize.SMALL_TOOLBAR);

        Gtk.Stack copy_stack = new Gtk.Stack();
        copy_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
        copy_stack.add_named(copy_button, "copy_button");
        copy_stack.add_named(copy_ok_image, "copy_ok_image");

        Gtk.Stack? action_stack = null;
        if (url.has_prefix("file")) {
            Gtk.Button upload_button = new Gtk.Button.from_icon_name(
                "go-up-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            upload_button.set_relief(Gtk.ReliefStyle.NONE);
            upload_button.set_can_focus(false);
            upload_button.set_tooltip_text("Upload screenshot");
            upload_button.get_style_context().add_class("action-button");

            Gtk.Spinner upload_spinner = new Gtk.Spinner();

            action_stack = new Gtk.Stack();
            action_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT);
            action_stack.add_named(upload_button, "upload_button");
            action_stack.add_named(upload_spinner, "upload_spinner");
            action_stack.add_named(copy_stack, "copy_stack");
            action_stack.show_all();
            action_stack.set_visible_child_name("upload_button");

            NewScreenshotView new_screenshot_view = new NewScreenshotView(null, null);
            new_screenshot_view.provider_to_use = settings.get_string("provider");

            settings.changed.connect((key) => {
                if (key == "provider") {
                    new_screenshot_view.provider_to_use = settings.get_string(key);
                }
            });

            upload_button.clicked.connect(() => { new_screenshot_view.upload_local(url); });

            new_screenshot_view.local_upload_started.connect(() => {
                action_stack.set_visible_child_name("upload_spinner");
                upload_spinner.start();
            });

            new_screenshot_view.local_upload_finished.connect((link) => {
                upload_spinner.stop();
                if (link != "" && link.has_prefix("http")) {
                    action_stack.set_visible_child_name("copy_stack");
                    string old_url = url;
                    url = link;
                    url_label.set_text(link.split("://")[1]);
                    apply_changes(settings, old_url);
                    copy(link);
                } else {
                    Gtk.Image error_image = new Gtk.Image.from_icon_name(
                        "action-unavailable-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
                    upload_button.image = error_image;
                    upload_button.set_tooltip_text("Upload failed! Click to try again.");
                    action_stack.set_visible_child_name("upload_button");
                }
            });
        }

        Gtk.Button delete_button = new Gtk.Button.from_icon_name(
            "list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        delete_button.set_relief(Gtk.ReliefStyle.NONE);
        delete_button.set_can_focus(false);
        delete_button.set_tooltip_text("Delete Screenshot");
        delete_button.get_style_context().add_class("action-button");

        Gtk.Box title_main_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        title_main_box.pack_start(title_stack, true, true, 0);
        title_main_box.pack_end(delete_button, false, false, 0);

        if (url.has_prefix("http")) {
            title_main_box.pack_end(copy_stack, false, false, 0);
        } else {
            title_main_box.pack_end(action_stack, false, false, 0);
        }

        string[] url_split = url.split("://");
        url_label = new Gtk.Label(url_split[1].strip());
        url_label.set_halign(Gtk.Align.START);
        url_label.get_style_context().add_class("dim-label");
        url_label.set_max_width_chars(23);
        url_label.set_ellipsize(Pango.EllipsizeMode.MIDDLE);

        Gtk.EventBox url_event_box = new Gtk.EventBox();
        url_event_box.set_tooltip_text("Click to open this screenshot");
        url_event_box.add(url_label);
        url_event_box.button_press_event.connect(() => {
            try {
                Gtk.show_uri(Gdk.Screen.get_default(), url, Gdk.CURRENT_TIME);
            } catch (GLib.Error e) {
                stderr.printf(e.message);
            }
            return true;
        });

        gnome_settings = new GLib.Settings("org.gnome.desktop.interface");
        string time_format = gnome_settings.get_string("clock-format");

        string? time_text = null;

        if (time_format == "24h") {
            time_text = time.format("%H:%M");
        } else if (time_format == "12h") {
            time_text = time.format("%l:%M %p");
        }

        Gtk.Label time_label = new Gtk.Label(time_text);
        time_label.set_tooltip_text(time.format("%d %B %Y"));
        time_label.set_valign(Gtk.Align.CENTER);
        time_label.get_style_context().add_class("dim-label");

        gnome_settings.changed.connect((key) => {
            if (key == "clock-format") {
                time_format = gnome_settings.get_string("clock-format");
                if (time_format == "24h") {
                    time_text = time.format("%H:%M");
                } else if (time_format == "12h") {
                    time_text = time.format("%l:%M %p");
                }
                time_label.label = time_text;
            }
        });

        Gtk.Box url_main_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        url_main_box.pack_start(url_event_box, true, true, 0);
        url_main_box.pack_end(time_label, false, false, 0);

        title_edit_button.clicked.connect(() => {
            title_entry.text = title;
            title_stack.set_visible_child_name("title_edit_box");
            title_entry.grab_focus();
        });

        title_apply_button.clicked.connect(() => {
            if (title_entry.text != title) {
                apply_changes(settings, url);
            }
            title_stack.set_visible_child_name("title_box");
        });

        title_entry.activate.connect(() => {
            if (title_entry.text != title) {
                apply_changes(settings, url);
            }
            title_stack.set_visible_child_name("title_box");
        });

        title_entry.key_press_event.connect((event) => {
            if (event.keyval == Gdk.Key.Escape) {
                title_stack.set_visible_child_name("title_box");
                return true;
            }
            return false;
        });

        copy_button.clicked.connect(() => {
            copy_stack.set_visible_child_name("copy_ok_image");
            copy(url);
            GLib.Timeout.add(500, () => {
                copy_stack.set_visible_child_name("copy_button");
                return false;
            });
        });

        delete_button.clicked.connect(() => { delete_item(settings); });

        Gtk.Box history_view_item_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        history_view_item_box.margin = 5;
        history_view_item_box.pack_start(title_main_box, true, true, 0);
        history_view_item_box.pack_start(url_main_box, true, true, 0);

        add(history_view_item_box);
        set_reveal_child(false);
        show_all();
    }

    private void delete_item(GLib.Settings settings)
    {
        GLib.Variant history_list = settings.get_value("history");
        GLib.Variant[]? history_l = null;
        GLib.Variant? history_entry_curr = null;

        if (history_list.n_children() == 1) {
            settings.reset("history");
        } else {
            for (int i=0; i<history_list.n_children(); i++) {
                history_entry_curr = history_list.get_child_value(i);
                string? entry_url = null;
                history_entry_curr.get("(xss)", null, null, out entry_url);
                if (entry_url != url) {
                    history_l += history_entry_curr;
                }
            }

            GLib.Variant history_entry_array = new GLib.Variant.array(null, history_l);
            settings.set_value("history", history_entry_array);
        }

        deletion();

        set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
        set_transition_duration(150);

        /* The revealer close animation never gets triggered for
           the first item in the list for some reason
           so this will destroy the parent without the close animation.
           Might be a GTK+ bug. */
        notify["child-revealed"].connect_after(() => {
            if (get_parent() != null) get_parent().destroy();
        });

        set_reveal_child(false);
    }

    private void apply_changes(GLib.Settings settings, string current_url)
    {
        title = (title_entry.text == "") ? "Untitled" : title_entry.text.strip();

        title_label.set_text("<b>%s</b>".printf(title));
        title_label.set_use_markup(true);

        GLib.Variant history_list = settings.get_value("history");
        GLib.Variant[]? history_variant_list = null;
        GLib.Variant? history_entry_curr = null;
        GLib.Variant? history_entry_new = null;

        for (int i=0; i<history_list.n_children(); i++) {
            history_entry_curr = history_list.get_child_value(i);
            string? entry_url = null;
            history_entry_curr.get("(xss)", null, null, out entry_url);
            if (entry_url == current_url) {
                GLib.Variant entry_timestamp_variant = new GLib.Variant.int64(timestamp);
                GLib.Variant entry_title_variant = new GLib.Variant.string(title);
                GLib.Variant entry_url_variant = new GLib.Variant.string(url);
                history_entry_new = new GLib.Variant.tuple(
                    {entry_timestamp_variant, entry_title_variant, entry_url_variant});
                history_variant_list += history_entry_new;
            } else {
                history_variant_list += history_entry_curr;
            }
        }

        GLib.Variant history_entry_array = new GLib.Variant.array(null, history_variant_list);
        settings.set_value("history", history_entry_array);
    }
}