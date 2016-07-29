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
    public class ErrorView : Gtk.Box
    {
        private Gtk.Label label;

        private static GLib.Once<ErrorView> _instance;

        public ErrorView(Gtk.Stack stack)
        {
            Object(spacing: 0, orientation: Gtk.Orientation.VERTICAL);
            margin = 20;
            width_request = 200;
            height_request = 150;

            Gtk.Image image = new Gtk.Image.from_icon_name("emblem-important-symbolic", Gtk.IconSize.DIALOG);
            image.pixel_size = 64;

            label = new Gtk.Label("<big>We couldn't upload your image</big>\nCheck your internet connection.");
            label.margin_top = 10;
            label.justify = Gtk.Justification.CENTER;
            label.use_markup = true;

            Gtk.Button back_button = new Gtk.Button.with_label("Back");
            back_button.margin_top = 20;
            back_button.can_focus = false;

            back_button.clicked.connect(() => {
                stack.visible_child_name = "new_screenshot_view";
            });

            pack_start(image, true, true, 0);
            pack_start(label, true, true, 0);
            pack_start(back_button, true, true, 0);
        }

        public void set_label(string text)
        {
            label.label = text;
        }

        public static unowned ErrorView instance(Gtk.Stack stack) {
            return _instance.once(() => { return new ErrorView(stack); });
        }
    }
}