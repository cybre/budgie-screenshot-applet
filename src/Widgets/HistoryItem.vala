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

[GtkTemplate (ui = "/com/github/cybre/budgie-screenshot-applet/ui/history_item.ui")]
public class HistoryItem : Gtk.Box
{
    [GtkChild]
    private Gtk.Revealer? main_revealer;

    [GtkChild]
    private Gtk.Stack? main_stack;

    [GtkChild]
    public Gtk.Stack? thumbnail_stack;

    [GtkChild]
    private Gtk.EventBox? thumbnail_eventbox;

    [GtkChild]
    private Gtk.EventBox? thumbnail_eventbox_copy;

    [GtkChild]
    private Gtk.Stack? title_stack;

    [GtkChild]
    private Gtk.Label? title_label;

    [GtkChild]
    private Gtk.Entry? title_entry;

    [GtkChild]
    private Gtk.Stack? copy_stack;

    [GtkChild]
    private Gtk.Label? uri_label;

    [GtkChild]
    private Gtk.Label? time_label;

    [GtkChild]
    public Gtk.Separator? separator;

    [GtkChild]
    private Gtk.ProgressBar? upload_progressbar;

    private static bool style_been_set = false;

    private string _item_title;
    private string item_file_uri;
    private string _item_uri;

    private int64 item_timestamp;

    private string item_title {
        get {
            return _item_title;
        }
        set {
            _item_title = value;
            apply_changes();
        }
    }

    public string item_uri {
        get {
            return _item_uri;
        }
        set {
            _item_uri = value;
            apply_changes();
        }
    }

    private unowned GLib.Settings settings;

    private string STYLE_CSS = """
        GtkProgressBar.trough,
        .progressbar,
        progressbar progress,
        progressbar trough {
            min-height: ${HEIGHT}px;
        }
    """;

    public signal void deletion(bool only_item);
    public signal void upload_started();
    public signal void update_progress(int64 size, int64 progress);
    public signal void upload_finished(string? new_uri, bool status);

    public HistoryItem(int64 timestamp, string title, string file_uri, string uri, bool startup = false)
    {
        this.item_timestamp = timestamp;
        this._item_title = title;
        this.item_file_uri = file_uri;
        this._item_uri = (uri != "") ? uri : file_uri;

        settings = BackendUtil.settings_manager.get_settings();

        title_label.set_text(@"<b>$item_title</b>");
        title_label.set_use_markup(true);
        string path = item_uri.split("://")[1];
        if (item_uri.has_prefix("file://")) {
            uri_label.set_tooltip_text(path);
            if (path.has_prefix(GLib.Environment.get_home_dir())) {
                try {
                    GLib.Regex a = new GLib.Regex(GLib.Environment.get_home_dir());
                    path = a.replace(path, path.length, 0, "~", GLib.RegexMatchFlags.ANCHORED);
                } catch(GLib.RegexError e) {
                    warning(e.message);
                }
            }
        }

        uri_label.set_text(path);

        if (item_uri.has_prefix("http")) {
            copy_stack.set_visible_child_name("copy");
        }

        GLib.DateTime time = new GLib.DateTime.from_unix_local(timestamp);
        GLib.Settings gnome_settings = new GLib.Settings("org.gnome.desktop.interface");
        string time_format = gnome_settings.get_string("clock-format");
        string time_text = (time_format == "24h") ? time.format("%H:%M") : time.format("%l:%M %p");

        time_label.set_text(time_text);
        time_label.set_tooltip_text(time.format("%d %B %Y"));

        Gdk.Pixbuf real_pb;
        Gdk.Pixbuf copy_pb;

        // Create the thumbnails
        set_up_thumbnails(out real_pb, out copy_pb);

        thumbnail_eventbox.draw.connect((cr) => {
            configure_thumbnail(cr, thumbnail_eventbox.get_style_context(), real_pb);
            return Gdk.EVENT_STOP;
        });

        thumbnail_eventbox_copy.draw.connect((cr) => {
            configure_thumbnail(cr, thumbnail_eventbox_copy.get_style_context(), copy_pb);
            return Gdk.EVENT_STOP;
        });

        if (!startup) {
            GLib.Timeout.add(100, () => {
                main_revealer.set_reveal_child(true);
                this.get_style_context().add_class("new-item");
                if (BackendUtil.settings_manager.automatic_upload) {
                    upload_item.begin();
                }
                return false;
            });

            GLib.Timeout.add(1300, () => {
                this.get_style_context().remove_class("new-item");
                return false;
            });
        } else {
            main_revealer.set_reveal_child(true);
        }

        this.upload_started.connect(() => {
            main_stack.set_visible_child_name("uploading");
        });

        this.update_progress.connect((size, progress) => {
            double s = (double)size;
            double p = (double)progress;
            double fraction = p/s;
            upload_progressbar.set_fraction(fraction);
        });

        this.upload_finished.connect((new_uri, status) => {
            if (BackendUtil.uploader.is_cancelled()) {
                main_stack.set_visible_child_name("normal");
                return;
            }
            if (status) {
                item_uri = new_uri;
                string uri_text = item_uri.split("://")[1];
                uri_label.set_text(uri_text);
                copy_stack.set_visible_child_name("copy");
                main_stack.set_visible_child_name("normal");
                if (BackendUtil.settings_manager.automatic_copy) {
                    copy_uri();
                }
            } else {
                GLib.Timeout.add(500, () => {
                    main_stack.set_visible_child_name("error");
                    return false;
                });
            }

        });

        thumbnail_stack.set_no_show_all(!BackendUtil.settings_manager.show_thumbnails);

        this.show_all();
    }

    private void set_up_thumbnails(out Gdk.Pixbuf? real_pb, out Gdk.Pixbuf? copy_pb)
    {
        real_pb = null;
        copy_pb = null;

        if (!GLib.File.new_for_uri(item_file_uri).query_exists()) {
            thumbnail_stack.set_tooltip_text(_("Screenshot not available"));
            return;
        }

        try {
            Gdk.Pixbuf? pb = new Gdk.Pixbuf.from_file(item_file_uri.split("://")[1]);
            int width = (pb.width > pb.height) ? -1 : 48;
            int height = (pb.height > pb.width) ? -1 : 48;

            Gdk.Pixbuf? pb1 = new Gdk.Pixbuf.from_file_at_scale(item_file_uri.split("://")[1], width, height, true);
            width = (pb1.width > pb1.height) ? pb1.height : pb1.width;
            height = (pb1.height > pb1.width) ? pb1.width : pb1.height;
            int x = (pb1.width > pb1.height) ? ((pb1.width - width) / 2) : 0;
            int y = (pb1.height > pb1.width) ? ((pb1.height - height) / 2) : 0;

            real_pb = new Gdk.Pixbuf.subpixbuf(pb1, x, y, 48, 48);
            copy_pb = real_pb.copy();
            overlay_copy_icon(copy_pb);

            pb1 = null;
        } catch (GLib.Error e) {
            warning(e.message);
        }
    }

    private void overlay_copy_icon(Gdk.Pixbuf original_pb)
    {
        Gdk.Pixbuf pb = original_pb.copy();

        pb.fill(0x00000000);
        pb.composite(original_pb, 0, 0, 48, 48, 0, 0, 1.0, 1.0, Gdk.InterpType.NEAREST, 140);

        Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default();
        Gtk.IconInfo? icon_info = icon_theme.lookup_icon("edit-copy-symbolic", 24, 0);
        assert(icon_info != null);

        Gdk.RGBA rgba = new Gdk.RGBA();
        rgba.red = 255;
        rgba.green = 255;
        rgba.blue = 255;
        rgba.alpha = 266;

        try {
            pb = icon_info.load_symbolic(rgba, null, null, null, null);
            pb.composite(original_pb, 12, 12, 24, 24, 12, 12, 1.0, 1.0, Gdk.InterpType.NEAREST, 255);
        } catch (GLib.Error e) {
            warning(e.message);
        }
    }

    private void configure_thumbnail(Cairo.Context cr, Gtk.StyleContext style_context, Gdk.Pixbuf? pb)
    {
        int EXTRA_MARGIN = 4;
        int cr_width = pb.width - EXTRA_MARGIN * 2;
        int cr_height = pb.height - EXTRA_MARGIN * 2;

        int border_radius = style_context.get_property(Gtk.STYLE_PROPERTY_BORDER_RADIUS, Gtk.StateFlags.NORMAL).get_int ();
        int crop_radius = border_radius;

        int cr_x = EXTRA_MARGIN;
        int cr_y = EXTRA_MARGIN;

        cr.move_to(cr_x + crop_radius, cr_y);
        cr.arc(cr_x + cr_width - crop_radius, cr_y + crop_radius, crop_radius, Math.PI * 1.5, Math.PI * 2);
        cr.arc(cr_x + cr_width - crop_radius, cr_y + cr_height - crop_radius, crop_radius, 0, Math.PI * 0.5);
        cr.arc(cr_x + crop_radius, cr_y + cr_height - crop_radius, crop_radius, Math.PI * 0.5, Math.PI);
        cr.arc(cr_x + crop_radius, cr_y + crop_radius, crop_radius, Math.PI, Math.PI * 1.5);
        cr.close_path();

        if (pb != null) {
            Gdk.cairo_set_source_pixbuf(cr, pb, 0, 0);
        }

        cr.fill_preserve();

        style_context.render_background(cr, EXTRA_MARGIN, EXTRA_MARGIN, cr_width, cr_height);
        style_context.render_frame(cr, EXTRA_MARGIN, EXTRA_MARGIN, cr_width, cr_height);
    }

    [GtkCallback]
    private void edit_title()
    {
        title_entry.text = item_title;
        title_stack.set_visible_child_name("edit");
        title_entry.grab_focus();
    }

    [GtkCallback]
    private void change_title()
    {
        title_stack.set_visible_child_name("normal");
        if (title_entry.get_text() == item_title) {
            return;
        }

        item_title = (title_entry.get_text() == "") ? _("Untitled") : title_entry.get_text().strip();

        title_label.set_text(@"<b>$item_title</b>");
        title_label.set_use_markup(true);
    }

    [GtkCallback]
    private bool entry_key_press(Gdk.EventKey event)
    {
        if (event.keyval == Gdk.Key.Escape) {
            title_stack.set_visible_child_name("normal");
            return true;
        }
        return false;
    }

    [GtkCallback]
    private void copy_uri()
    {
        copy_stack.set_visible_child_name("ok");
        Views.HistoryView.copy_uri(item_uri);
        GLib.Timeout.add(500, () => {
            copy_stack.set_visible_child_name("copy");
            return false;
        });
    }

    [GtkCallback]
    private async void upload_item()
    {
        // I'm doing this here, fuck it
        if (!style_been_set) {
            Gtk.Allocation allocation;
            this.get_allocation(out allocation);
            STYLE_CSS = STYLE_CSS.replace("${HEIGHT}", (allocation.height - 2).to_string());
            Gtk.CssProvider provider = new Gtk.CssProvider();
            try {
                provider.load_from_data(STYLE_CSS, STYLE_CSS.length);
                Gtk.StyleContext.add_provider_for_screen(this.get_display().get_default_screen(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                style_been_set = true;
            } catch (Error e) {
                warning(e.message);
            }
        }

        BackendUtil.uploader.add_to_queue(this);

        if (BackendUtil.uploader.is_upload_in_progress()) {
            main_stack.set_visible_child_name("waiting");
        } else {
            BackendUtil.uploader.start_upload.begin();
        }
    }

    [GtkCallback]
    private async void cancel_upload() {
        GLib.Idle.add(() => {
            main_stack.set_visible_child_name("normal");
            return false;
        });
        BackendUtil.uploader.cancel_upload.begin();
        upload_progressbar.set_fraction(0);
    }

    public void delete_file() {
        GLib.File file = GLib.File.new_for_uri(item_file_uri);
        if (!file.query_exists()) {
            return;
        }
        file.delete_async.begin(GLib.Priority.DEFAULT, null, (obj, res) => {
            try {
                file.delete_async.end(res);
            } catch (GLib.Error e) {
                warning(e.message);
            }
        });
    }

    [GtkCallback]
    public void delete_item()
    {
        if (BackendUtil.settings_manager.delete_files) {
            delete_file();
        }
        GLib.Variant history_list = settings.get_value("history");
        GLib.Variant[]? history_l = null;
        GLib.Variant? history_entry_curr = null;

        if (history_list.n_children() == 1) {
            // There's only one item, just reset the key.
            settings.reset("history");
            Gtk.Widget? parent = this.get_parent();
            if (parent != null) {
                deletion(true);
                parent.destroy();
            }
            return;
        } else {
            for (int i=0; i<history_list.n_children(); i++) {
                history_entry_curr = history_list.get_child_value(i);
                string? file_uri = null;
                history_entry_curr.get("(xsss)", null, null, out file_uri, null);
                if (file_uri != item_file_uri) {
                    history_l += history_entry_curr;
                }
            }

            GLib.Variant history_entry_array = new GLib.Variant.array(null, history_l);
            settings.set_value("history", history_entry_array);
        }

        main_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
        main_revealer.set_transition_duration(200);

        /* The revealer close animation never gets triggered for
         * the first item in the list for some reason
         * so this will destroy the parent without the close animation.
         * Might be a GTK+ bug.
         */
        main_revealer.notify["child-revealed"].connect_after(() => {
            Gtk.Widget? parent = this.get_parent();
            if (parent != null) {
                deletion(false);
                parent.destroy();
            }
        });

        main_stack.set_transition_duration(350);
        main_stack.set_visible_child_full("deleting", Gtk.StackTransitionType.SLIDE_RIGHT);
        main_revealer.set_reveal_child(false);
    }

    [GtkCallback]
    private bool open_uri()
    {
        if (!GLib.File.new_for_uri(item_file_uri).query_exists() && item_uri == "") {
            return Gdk.EVENT_PROPAGATE;
        }

        try {
            Gtk.show_uri(Gdk.Screen.get_default(), item_uri, Gdk.CURRENT_TIME);
        } catch (GLib.Error e) {
            warning(e.message);
        }

        return Gdk.EVENT_STOP;
    }

    [GtkCallback]
    private bool thumbnail_clicked(Gdk.EventButton event)
    {
        if (!GLib.File.new_for_uri(item_file_uri).query_exists()) {
            return Gdk.EVENT_PROPAGATE;
        }

        if (event.button == 1) {
            try {
                Gtk.show_uri(Gdk.Screen.get_default(), item_file_uri, Gdk.CURRENT_TIME);
            } catch (GLib.Error e) {
                warning(e.message);
            }
        } else if (event.button == 3) {
            thumbnail_stack.set_visible_child_name("copied");
            Views.HistoryView.copy_uri(item_file_uri);
            GLib.Timeout.add(500, () => {
                thumbnail_stack.set_visible_child_name("normal");
                return false;
            });
        } else {
            return Gdk.EVENT_PROPAGATE;
        }

        return Gdk.EVENT_STOP;
    }

    [GtkCallback]
    private void cancel_after_fail() {
        main_stack.set_visible_child_name("normal");
    }

    [GtkCallback]
    private void cancel_queued_upload() {
        main_stack.set_visible_child_name("normal");
        BackendUtil.uploader.remove_from_queue(this);
    }

    private void apply_changes()
    {
        GLib.Variant history_list = settings.get_value("history");
        GLib.Variant[]? history_variant_list = null;
        GLib.Variant? history_entry_curr = null;
        GLib.Variant? history_entry_new = null;

        for (int i=0; i<history_list.n_children(); i++) {
            history_entry_curr = history_list.get_child_value(i);
            string? file_uri = null;
            history_entry_curr.get("(xsss)", null, null, out file_uri, null);
            if (file_uri == item_file_uri) {
                GLib.Variant[] entry_variant_array = {
                    new GLib.Variant.int64(item_timestamp),
                    new GLib.Variant.string(item_title),
                    new GLib.Variant.string(item_file_uri),
                    new GLib.Variant.string(item_uri)
                };
                history_entry_new = new GLib.Variant.tuple(entry_variant_array);
                history_variant_list += history_entry_new;
            } else {
                history_variant_list += history_entry_curr;
            }
        }

        GLib.Variant history_entry_array = new GLib.Variant.array(null, history_variant_list);
        settings.set_value("history", history_entry_array);
    }
}

} // End namespace
