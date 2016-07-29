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
    public class HistoryViewItem : Gtk.Revealer
    {
        private Gtk.Box history_view_item_box;
        private Gtk.Box title_box;
        private Gtk.Box title_edit_box;
        private Gtk.Box title_main_box;
        private Gtk.Box url_main_box;
        private Gtk.Label title_label;
        private Gtk.Label url_label;
        private Gtk.Label time_label;
        private Gtk.Button title_edit_button;
        private Gtk.Button title_apply_button;
        private Gtk.Button copy_button;
        private Gtk.Button delete_button;
        private Gtk.EventBox url_event_box;
        private Gtk.Stack title_stack;
        private Gtk.Stack copy_stack;
        private Gtk.Entry title_entry;
        private GLib.Settings gnome_settings;
        private GLib.DateTime time;
        private GLib.Variant history_list;
        private GLib.Variant history_entry;
        private Gtk.Image copy_ok_image;
        private string title;
        private string url;
        private int64 timestamp;

        public signal void copy(string url);
        public signal void deletion();

        public HistoryViewItem(int n, GLib.Settings settings)
        {
            can_focus = false;
            transition_type = Gtk.RevealerTransitionType.NONE;
            transition_duration = 500;

            history_list = settings.get_value("history");
            history_entry = history_list.get_child_value(n);
            history_entry.get("(xss)", out timestamp, out title, out url);

            time = new GLib.DateTime.from_unix_local(timestamp);

            if (title == "") title = "Untitled";
            title_label = new Gtk.Label("<b>%s</b>".printf(title.strip()));
            title_label.use_markup = true;
            title_label.halign = Gtk.Align.START;
            title_label.max_width_chars = 23;
            title_label.ellipsize = Pango.EllipsizeMode.END;

            title_edit_button = new Gtk.Button.from_icon_name(
                "accessories-text-editor-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            title_edit_button.relief = Gtk.ReliefStyle.NONE;
            title_edit_button.can_focus = false;
            title_edit_button.tooltip_text = "Edit Title";

            title_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            title_box.pack_start(title_label, true, true, 0);
            title_box.pack_end(title_edit_button, false, false, 0);

            title_entry = new Gtk.Entry();
            title_entry.placeholder_text = "New Title";
            title_entry.max_length = 50;
            title_entry.margin_end = 10;

            title_entry.set_icon_from_icon_name(
                Gtk.EntryIconPosition.SECONDARY, "edit-clear-symbolic");
            title_entry.set_icon_tooltip_text(Gtk.EntryIconPosition.SECONDARY, "Clear");
            title_entry.icon_press.connect(() => {
                title_entry.text = "";
            });

            title_apply_button = new Gtk.Button.from_icon_name(
                "emblem-ok-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            title_apply_button.relief = Gtk.ReliefStyle.NONE;
            title_apply_button.can_focus = false;
            title_apply_button.tooltip_text = "Apply Changes";

            title_edit_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            title_edit_box.pack_start(title_entry, true, true, 0);
            title_edit_box.pack_end(title_apply_button, false, false, 0);

            title_stack = new Gtk.Stack();
            title_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
            title_stack.add_named(title_box, "title_box");
            title_stack.add_named(title_edit_box, "title_edit_box");

            copy_button = new Gtk.Button.from_icon_name(
                "edit-copy-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            copy_button.relief = Gtk.ReliefStyle.NONE;
            copy_button.can_focus = false;
            copy_button.tooltip_text = "Copy Screenshot URL";

            copy_ok_image = new Gtk.Image.from_icon_name(
                "emblem-ok-symbolic", Gtk.IconSize.SMALL_TOOLBAR);

            copy_stack = new Gtk.Stack();
            copy_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            copy_stack.add_named(copy_button, "copy_button");
            copy_stack.add_named(copy_ok_image, "copy_ok_image");

            string start = url.slice(0, 4);
            Gtk.Stack? action_stack = null;
            if (start == "file") {
                Gtk.Button upload_button = new Gtk.Button.from_icon_name(
                    "go-up-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
                upload_button.relief = Gtk.ReliefStyle.NONE;
                upload_button.can_focus = false;
                upload_button.tooltip_text = "Upload screenshot";

                Gtk.Spinner upload_spinner = new Gtk.Spinner();

                action_stack = new Gtk.Stack();
                action_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT;
                action_stack.add_named(upload_button, "upload_button");
                action_stack.add_named(upload_spinner, "upload_spinner");
                action_stack.add_named(copy_stack, "copy_stack");
                action_stack.show_all();
                action_stack.visible_child_name = "upload_button";

                NewScreenshotView new_screenshot_view = new NewScreenshotView(null, null);
                new_screenshot_view.provider_to_use = settings.get_string("provider");

                settings.changed.connect((key) => {
                    if (key == "provider") {
                        new_screenshot_view.provider_to_use = settings.get_string(key);
                    }
                });

                upload_button.clicked.connect(() => {
                    new_screenshot_view.upload_local(url);
                });

                new_screenshot_view.local_upload_started.connect(() => {
                    action_stack.visible_child_name = "upload_spinner";
                    upload_spinner.active = true;
                });

                new_screenshot_view.local_upload_finished.connect((link) => {
                    upload_spinner.active = false;
                    string link_start = link.slice(0, 4);
                    if (link != "" && link_start == "http") {
                        action_stack.visible_child_name = "copy_stack";
                        string old_url = url;
                        url = link;
                        url_label.set_text(link.split("://")[1]);
                        apply_changes(settings, old_url);
                    } else {
                        Gtk.Image error_image = new Gtk.Image.from_icon_name(
                            "action-unavailable-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
                        upload_button.image = error_image;
                        upload_button.tooltip_text = "Upload failed! Click to try again.";
                        action_stack.visible_child_name = "upload_button";
                    }
                });
            }

            delete_button = new Gtk.Button.from_icon_name(
                "list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            delete_button.relief = Gtk.ReliefStyle.NONE;
            delete_button.can_focus = false;
            delete_button.tooltip_text = "Delete Screenshot";

            title_main_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            title_main_box.pack_start(title_stack, true, true, 0);
            title_main_box.pack_end(delete_button, false, false, 0);

            if (start == "http") {
                title_main_box.pack_end(copy_stack, false, false, 0);
            } else {
                title_main_box.pack_end(action_stack, false, false, 0);
            }

            string[] url_split = url.split("://");
            url_label = new Gtk.Label(url_split[1].strip());
            url_label.halign = Gtk.Align.START;
            url_label.get_style_context().add_class("dim-label");
            url_label.max_width_chars = 23;
            url_label.ellipsize = Pango.EllipsizeMode.MIDDLE;

            url_event_box = new Gtk.EventBox();
            url_event_box.tooltip_text = "Click to open this screenshot";
            url_event_box.add(url_label);
            url_event_box.button_press_event.connect(() => {
                try {
                    GLib.Process.spawn_command_line_async("xdg-open \"%s\"".printf(url));
                } catch (GLib.SpawnError e) {
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

            time_label = new Gtk.Label(time_text);
            time_label.tooltip_text = time.format("%d %B %Y");
            time_label.valign = Gtk.Align.CENTER;
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

            url_main_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            url_main_box.pack_start(url_event_box, true, true, 0);
            url_main_box.pack_end(time_label, false, false, 0);

            title_edit_button.clicked.connect(() => {
                title_entry.text = title;
                title_stack.visible_child_name = "title_edit_box";
                title_entry.grab_focus();
            });

            title_apply_button.clicked.connect(() => {
                if (title_entry.text != title) {
                    apply_changes(settings, url);
                }
                title_stack.visible_child_name = "title_box";
            });

            title_entry.activate.connect(() => {
                if (title_entry.text != title) {
                    apply_changes(settings, url);
                }
                title_stack.visible_child_name = "title_box";
            });

            title_entry.key_press_event.connect((event) => {
                if (event.keyval == Gdk.Key.Escape) {
                    title_stack.visible_child_name = "title_box";
                    return true;
                }
                return false;
            });

            copy_button.clicked.connect(() => {
                copy_stack.visible_child_name = "copy_ok_image";
                copy(url);
                GLib.Timeout.add(500, () => {
                    copy_stack.visible_child_name = "copy_button";
                    return false;
                });
            });

            delete_button.clicked.connect(() => {
                delete_item(settings);
            });

            history_view_item_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            history_view_item_box.margin_top = 5;
            history_view_item_box.margin_bottom = 5;
            history_view_item_box.margin_start = 10;
            history_view_item_box.margin_end = 10;
            history_view_item_box.pack_start(title_main_box, true, true, 0);
            history_view_item_box.pack_start(url_main_box, true, true, 0);

            add(history_view_item_box);
            reveal_child = false;
            show_all();
        }

        private void delete_item(GLib.Settings settings)
        {
            history_list = settings.get_value("history");
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

            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            transition_duration = 150;

            /* The revealer close animation never gets triggered for
               the first item in the list for some reason
               so this will destroy the parent without the close animation.
               Might be a GTK+ bug. */
            notify["child-revealed"].connect_after(() => {
                get_parent().destroy();
            });

            reveal_child = false;
        }

        private void apply_changes(GLib.Settings settings, string current_url)
        {
            if (title_entry.text == "") {
                title = "Untitled";
            } else {
                title = title_entry.text.strip();
            }

            title_label.set_text("<b>%s</b>".printf(title));
            title_label.use_markup = true;

            history_list = settings.get_value("history");
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
}