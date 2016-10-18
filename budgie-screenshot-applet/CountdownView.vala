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

public class CountdownView : Gtk.Box
{
    public GLib.Cancellable cancellable;
    private Gtk.Stack stack;
    public Gtk.Label label1;
    private Gtk.Label label2;
    private Gtk.Button cancel_button;

    private static GLib.Once<CountdownView> _instance;

    public signal void cancelled();

    public CountdownView()
    {
        Object(spacing: 0, orientation: Gtk.Orientation.VERTICAL, margin: 20);
        set_size_request(200, 150);

        label1 = new Gtk.Label("");
        label1.set_use_markup(true);

        label2 = new Gtk.Label("");
        label2.set_use_markup(true);

        Gtk.Image cheese_image = new Gtk.Image.from_icon_name("face-smile-big-symbolic", Gtk.IconSize.DIALOG);
        cheese_image.set_pixel_size(64);

        Gtk.Label cheese_label = new Gtk.Label("<span font='20'>Cheese!</span>");
        cheese_label.set_use_markup(true);

        Gtk.Box cheese_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        cheese_box.add(cheese_image);
        cheese_box.add(cheese_label);

        stack = new Gtk.Stack();
        stack.set_transition_type(Gtk.StackTransitionType.SLIDE_DOWN);
        stack.set_transition_duration(200);
        stack.add_named(label1, "label1");
        stack.add_named(label2, "label2");
        stack.add_named(cheese_box, "cheese");

        cancel_button = new Gtk.Button.with_label("Cancel");
        cancel_button.set_margin_top(20);
        cancel_button.set_can_focus(false);

        cancel_button.clicked.connect(() => { cancelled(); cancellable.cancel(); });

        pack_start(stack, true, true, 0);
        pack_start(cancel_button, true, true, 0);
    }

    public void change_label(int left)
    {
        if (stack.visible_child_name == "label1") {
            stack.set_visible_child_name("label2");
        } else {
            stack.set_visible_child_name("label1");
        }

        label1.label = "<span font='50'>%i</span>".printf(left);
        label2.label = "<span font='50'>%i</span>".printf(left);

        if (left == 0) {
            cancel_button.hide();
            stack.set_margin_top(20);
            stack.set_transition_duration(100);
            stack.set_visible_child_name("cheese");
        }
    }

    public void set_label(int label, int size = 50) {
        label1.label = "<span font='%i'>%i</span>".printf(size, label);
        stack.set_visible_child_name("label1");
        cancel_button.show();
        stack.set_margin_top(0);
        stack.set_transition_duration(200);
    }

    public static unowned CountdownView instance() {
        return _instance.once(() => { return new CountdownView(); });
    }
}