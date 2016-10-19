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

public class ScreenshotApplet.ErrorView : Gtk.Box
{
    private Gtk.Label label;

    private static GLib.Once<ErrorView> _instance;

    public ErrorView(Gtk.Stack stack)
    {
        Object(spacing: 0, orientation: Gtk.Orientation.VERTICAL, margin: 20);
        set_size_request(200, 150);

        Gtk.Image image = new Gtk.Image.from_icon_name("emblem-important-symbolic", Gtk.IconSize.DIALOG);
        image.set_pixel_size(64);

        label = new Gtk.Label("<big>%s</big>\n%s".printf(
            _("We couldn't upload your image"), _("Check your internet connection.")));
        label.set_margin_top(10);
        label.set_justify(Gtk.Justification.CENTER);
        label.set_use_markup(true);

        Gtk.Button back_button = new Gtk.Button.with_label(_("Back"));
        back_button.set_margin_top(20);
        back_button.set_can_focus(false);

        back_button.clicked.connect(() => { stack.set_visible_child_name("new_screenshot_view"); });

        pack_start(image, true, true, 0);
        pack_start(label, true, true, 0);
        pack_start(back_button, true, true, 0);
    }

    public void set_label(string text) {
        label.label = text;
    }

    public static unowned ErrorView instance(Gtk.Stack stack) {
        return _instance.once(() => { return new ErrorView(stack); });
    }
}