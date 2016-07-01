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
    public class UploadDoneView : Gtk.Box
    {
        private Gtk.Image image;
        private Gtk.Label label;
        private Gtk.Button back_button;
        private Gtk.Button open_button;
        private Gtk.Box button_box;
        public string link;

        public UploadDoneView(Gtk.Stack stack, Gtk.Popover popover)
        {
            Object(spacing: 0, orientation: Gtk.Orientation.VERTICAL);
            margin = 20;
            width_request = 200;
            height_request = 150;

            image = new Gtk.Image.from_icon_name("emblem-ok-symbolic", Gtk.IconSize.DIALOG);
            image.pixel_size = 64;

            label = new Gtk.Label("<big>The link has been copied \nto your clipboard!</big>");
            label.margin_top = 10;
            label.justify = Gtk.Justification.CENTER;
            label.use_markup = true;

            back_button = new Gtk.Button.with_label("Back");
            back_button.can_focus = false;
            open_button = new Gtk.Button.with_label("Open");
            open_button.can_focus = false;

            button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            button_box.get_style_context().add_class("linked");
            button_box.margin_top = 20;
            button_box.pack_start(back_button, true, true, 0);
            button_box.pack_start(open_button, true, true, 0);

            back_button.clicked.connect(() => {
                stack.set_visible_child_full("new_screenshot_view", Gtk.StackTransitionType.SLIDE_RIGHT);
            });

            open_button.clicked.connect(() => {
                try {
                    GLib.Process.spawn_command_line_async("xdg-open \"%s\"".printf(link));
                    popover.hide();
                } catch (GLib.SpawnError e) {
                    stderr.printf(e.message);
                }
            });

            pack_start(image, true, true, 0);
            pack_start(label, true, true, 0);
            pack_start(button_box, true, true, 0);
        }

        public void set_label(string text)
        {
            label.label = text;
        }
    }
}