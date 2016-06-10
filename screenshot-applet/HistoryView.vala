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
    public class HistoryView : Gtk.Box
    {
        private Gtk.Box history_header_box;
        private Gtk.ScrolledWindow history_scroller;
        private Gtk.Image placeholder_image;
        private Gtk.Box placeholder_box;
        private Gtk.Label placeholder_label;
        private GLib.Settings settings;
        private Gtk.Clipboard clipboard;
        public Gtk.ListBox history_listbox;
        public Gtk.Button history_clear_all_button;
        public Gtk.Label history_header_label;
        public Gtk.Button history_back_button;

        public HistoryView(GLib.Settings settings, Gtk.Clipboard clipboard)
        {
            Object(spacing: 0, orientation: Gtk.Orientation.VERTICAL);
            this.width_request = 300;
            this.height_request = 400;

            this.settings = settings;
            this.clipboard = clipboard;

            history_back_button = new Gtk.Button.from_icon_name("go-previous-symbolic", Gtk.IconSize.MENU);
            history_back_button.relief = Gtk.ReliefStyle.NONE;
            history_back_button.tooltip_text = "Back";
            history_back_button.margin = 3;

            history_header_label = new Gtk.Label("Grab a screenshot :)");
            history_header_label.set_line_wrap(true);
            history_header_label.set_line_wrap_mode(Pango.WrapMode.WORD);
            history_header_label.halign = Gtk.Align.CENTER;

            history_clear_all_button = new Gtk.Button.from_icon_name("list-remove-all-symbolic", Gtk.IconSize.MENU);
            history_clear_all_button.relief = Gtk.ReliefStyle.NONE;
            history_clear_all_button.tooltip_text = "Clear All";
            history_clear_all_button.margin = 3;
            history_clear_all_button.clicked.connect(this.clear_all);

            history_header_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
            history_header_box.get_style_context().add_class("list");
            history_header_box.pack_start(history_back_button, false, false, 0);
            history_header_box.pack_start(history_header_label, true, true, 0);
            history_header_box.pack_end(history_clear_all_button, false, false, 0);

            history_listbox = new Gtk.ListBox();
            history_listbox.selection_mode = Gtk.SelectionMode.NONE;
            history_scroller = new Gtk.ScrolledWindow(null, null);
            history_scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            history_scroller.add(history_listbox);

            this.pack_start(history_header_box, false, false, 0);
            this.pack_start(history_scroller, true, true, 0);

            placeholder_image = new Gtk.Image.from_icon_name("action-unavailable-symbolic", Gtk.IconSize.DIALOG);
            placeholder_image.pixel_size = 64;
            placeholder_label = new Gtk.Label("<big>Nothing to see here</big>");
            placeholder_label.use_markup = true;
            placeholder_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
            placeholder_box.get_style_context().add_class("dim-label");
            placeholder_box.halign = Gtk.Align.CENTER;
            placeholder_box.valign = Gtk.Align.CENTER;
            placeholder_box.pack_start(placeholder_image, false, false, 6);
            placeholder_box.pack_start(placeholder_label, false, false, 0);

            history_listbox.set_placeholder(placeholder_box);
            placeholder_box.show_all();

            update_child_count();
        }

        private void update_child_count()
        {
            uint len = history_listbox.get_children().length();

            string? text = null;
            if (len > 1) {
                text = "%u screenshots taken".printf(len);
            } else if (len == 1) {
                text = "1 screenshot taken";
            } else {
                text = "Grab a screenshot :)";
            }    

            history_header_label.set_text(text);
            if (len == 0) {
                history_clear_all_button.sensitive = false;
            } else {
                history_clear_all_button.sensitive = true;
            }
        }

        public void update_history(string? history_entry)
        {   
            string[] h_split = history_entry.split("|");
            string time = h_split[0];
            string url = h_split[1];

            Gtk.Label date_label = new Gtk.Label("<small>%s</small>".printf(time));
            date_label.yalign = 0.60f;
            date_label.margin = 5;
            date_label.set_use_markup(true);
            date_label.get_style_context().add_class("dim-label");

            Gtk.LinkButton link_button = new Gtk.LinkButton(url);
            ((Gtk.Label) link_button.get_child()).halign = Gtk.Align.START;
            ((Gtk.Label) link_button.get_child()).max_width_chars = 24;
            ((Gtk.Label) link_button.get_child()).ellipsize = Pango.EllipsizeMode.MIDDLE;
            link_button.get_child().get_style_context().add_class("no-underline");

            Gtk.Button copy_button = new Gtk.Button.from_icon_name("edit-copy-symbolic", 
                Gtk.IconSize.MENU);
            copy_button.relief = Gtk.ReliefStyle.NONE;
            copy_button.margin = 3;

            copy_button.clicked.connect(() => {
                this.clipboard.set_text(url, -1);
            });

            Gtk.Box copy_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            copy_box.pack_start(date_label, false, false, 0);
            copy_box.pack_start(link_button, true, true, 0);
            copy_box.pack_end(copy_button, false, false, 5);

            history_listbox.prepend(copy_box);
            history_listbox.show_all();

            update_child_count();
        }

        public void add_to_history(string link)
        {
            string[] history_list = this.settings.get_strv("history");
            GLib.DateTime datetime = new GLib.DateTime.now_local();
            int64 timestamp = datetime.to_unix();
            GLib.DateTime time = new GLib.DateTime.from_unix_local(timestamp);
            history_list += time.format("%H:%M") + "|" + link;
            this.settings.set_strv("history", history_list);
            update_history(history_list[history_list.length - 1]);
        }

        public void clear_all()
        {
            this.settings.reset("history");
            foreach (Gtk.Widget child in history_listbox.get_children()) {
                child.destroy();
            }
            update_child_count();
        }
    }
}