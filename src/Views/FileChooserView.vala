/*
 * This file is part of budgie-screenshot-applet
 *
 * Copyright (C) 2016 Stefan Ric <stfric369@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

using ScreenshotApplet.Backend;

namespace ScreenshotApplet.Views
{

private class FileChooserView : Gtk.ScrolledWindow
{
    public FileChooserView()
    {
        this.set_size_request(600, 400);

        Gtk.Box main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        this.add(main_box);

        Gtk.Box header_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        main_box.add(header_box);
        header_box.get_style_context().add_class("view-header");

        Gtk.Button cancel_button = new Gtk.Button.with_label(_("Cancel"));
        header_box.pack_start(cancel_button, false, false, 0);
        cancel_button.set_can_focus(false);

        Gtk.Label center_label = new Gtk.Label(_("Select"));
        center_label.set_halign(Gtk.Align.CENTER);
        header_box.pack_start(center_label, true, true, 0);

        Gtk.Button select_button = new Gtk.Button.with_label(_("Select"));
        select_button.get_style_context().add_class("suggested-action");
        header_box.pack_end(select_button, false, false, 0);
        select_button.set_can_focus(false);

        Gtk.FileChooserWidget file_chooser_widget = new Gtk.FileChooserWidget(Gtk.FileChooserAction.SELECT_FOLDER);
        string start_path = BackendUtil.settings_manager.save_path;
        if (start_path.has_prefix("~")) {
            start_path = start_path.replace("~", GLib.Environment.get_home_dir());
        }
        file_chooser_widget.set_filename(start_path);
        file_chooser_widget.set_local_only(true);
        main_box.add(file_chooser_widget);

        cancel_button.clicked.connect(() => {
            Widgets.MainStack.set_page("settings_view");
        });

        select_button.clicked.connect(() => {
            string path = file_chooser_widget.get_filename();
            if (path != GLib.Environment.get_home_dir()) {
                if (path.has_prefix(GLib.Environment.get_home_dir())) {
                    try {
                        GLib.Regex a = new GLib.Regex(GLib.Environment.get_home_dir());
                        path = a.replace(path, path.length, 0, "~", GLib.RegexMatchFlags.ANCHORED);
                    } catch (GLib.RegexError e) {
                        warning(e.message);
                    }
                }
            }
            BackendUtil.settings_manager.save_path = path;
            Widgets.MainStack.set_page("settings_view");
        });

        file_chooser_widget.selection_changed.connect(() => {
            select_button.set_sensitive(file_chooser_widget.get_uri() != null);
        });
    }
}

} // End namespace