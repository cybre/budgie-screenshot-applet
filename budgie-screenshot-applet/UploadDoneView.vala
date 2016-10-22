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

public class ScreenshotApplet.UploadDoneView : Gtk.Box
{
    private Gtk.Label label;
    public string link;

    private static GLib.Once<UploadDoneView> _instance;

    public UploadDoneView(Gtk.Stack stack, Gtk.Popover popover)
    {
        Object(spacing: 0, orientation: Gtk.Orientation.VERTICAL, margin: 20);
        set_size_request(200, 150);

        Gtk.Image image = new Gtk.Image.from_icon_name("emblem-ok-symbolic", Gtk.IconSize.DIALOG);
        image.set_pixel_size(64);

        label = new Gtk.Label("");
        label.set_max_width_chars(25);
        label.set_line_wrap(true);
        label.set_margin_top(10);
        label.set_justify(Gtk.Justification.CENTER);
        label.set_use_markup(true);

        Gtk.Button back_button = new Gtk.Button.with_label(_("Back"));
        back_button.set_can_focus(false);
        Gtk.Button history_button = new Gtk.Button.with_label(_("History"));
        history_button.set_can_focus(false);
        Gtk.Button open_button = new Gtk.Button.with_label(_("Open"));
        open_button.set_can_focus(false);

        Gtk.Box button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        button_box.set_margin_top(20);
        button_box.get_style_context().add_class("linked");
        button_box.pack_start(back_button, true, true, 0);
        button_box.pack_start(history_button, true, true, 0);
        button_box.pack_start(open_button, true, true, 0);

        back_button.clicked.connect(() => { stack.set_visible_child_name("new_screenshot_view"); });
        history_button.clicked.connect(() => { stack.set_visible_child_name("history_view"); });

        open_button.clicked.connect(() => {
            try {
                Gtk.show_uri(Gdk.Screen.get_default(), link, Gdk.CURRENT_TIME);
            } catch (GLib.Error e) {
                stderr.printf(e.message);
            }
            popover.hide();
            popover.unmap.connect(() => { stack.set_visible_child_name("new_screenshot_view"); });
        });

        pack_start(image, true, true, 0);
        pack_start(label, true, true, 0);
        pack_end(button_box, true, true, 0);
    }

    public void set_label(string text) {
        label.label = text;
    }

    public static unowned UploadDoneView instance(Gtk.Stack stack, Gtk.Popover popover) {
        return _instance.once(() => { return new UploadDoneView(stack, popover); });
    }
}