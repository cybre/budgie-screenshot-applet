/*
 * This file is part of screenshot-applet
 *
 * Copyright (C) 2016-2017 Stefan Ric <stfric369@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace ScreenshotApplet.Widgets
{

public class ScreenshotModeButton : Gtk.ToolButton
{
    public ScreenshotModeButton(string image, string label, string tooltip)
    {
        set_tooltip_text(tooltip);

        Gtk.Image mode_image = new Gtk.Image.from_resource(@"/com/github/cybre/budgie-screenshot-applet/images/$image");
        mode_image.set_pixel_size(64);

        Gtk.Label mode_label = new Gtk.Label(label);
        mode_label.set_halign(Gtk.Align.CENTER);

        Gtk.Box button_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        button_box.set_size_request(80, 100);
        button_box.pack_start(mode_image, true, true, 0);
        button_box.pack_start(mode_label, true, true, 0);

        label_widget = button_box;

        get_child().set_can_focus(false);
        get_child().get_style_context().add_class("screenshot-mode-button");
    }
}

} // End namespace