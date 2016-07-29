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
    public class UploadingView : Gtk.Box
    {
        public GLib.Cancellable cancellable;

        private static GLib.Once<UploadingView> _instance;

        public UploadingView()
        {
            Object(spacing: 0, orientation: Gtk.Orientation.VERTICAL);
            margin = 20;
            width_request = 200;
            height_request = 150;

            Gtk.Image image = new Gtk.Image.from_icon_name("software-update-available-symbolic", Gtk.IconSize.DIALOG);
            image.pixel_size = 64;

            Gtk.Label label = new Gtk.Label("<big>Uploading...</big>");
            label.use_markup = true;
            label.margin_top = 10;

            Gtk.Button cancel_button = new Gtk.Button.with_label("Cancel");
            cancel_button.margin_top = 20;
            cancel_button.can_focus = false;

            cancel_button.clicked.connect(() => {
                cancellable.cancel();
            });

            pack_start(image, true, true, 0);
            pack_start(label, true, true, 0);
            pack_start(cancel_button, true, true, 0);
        }

        public static unowned UploadingView instance() {
            return _instance.once(() => { return new UploadingView(); });
        }
    }
}