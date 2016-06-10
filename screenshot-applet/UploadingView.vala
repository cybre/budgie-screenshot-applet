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
        private Gtk.Image uploading_image;
        private Gtk.Label uploading_label;
        public Gtk.Button uploading_cancel_button;

        public UploadingView()
        {
            Object(spacing: 0, orientation: Gtk.Orientation.VERTICAL);
            this.margin = 20;
            this.width_request = 200;
            this.height_request = 150;

            uploading_image = new Gtk.Image.from_icon_name("software-update-available-symbolic", Gtk.IconSize.DIALOG);
            uploading_image.pixel_size = 64;

            uploading_label = new Gtk.Label("<big>Uploading...</big>");
            uploading_label.set_use_markup(true);
            uploading_label.margin_top = 10;

            uploading_cancel_button = new Gtk.Button.with_label("Cancel");
            uploading_cancel_button.margin_top = 20;

            this.pack_start(uploading_image, true, true, 0);
            this.pack_start(uploading_label, true, true, 0);
            this.pack_start(uploading_cancel_button, true, true, 0);
        }
    }
}