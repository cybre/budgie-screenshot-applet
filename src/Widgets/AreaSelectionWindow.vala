/*
 * This file is part of budgie-screenshot-applet
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

private class AreaSelectionWindow : Gtk.Window
{
    private Gdk.Point start_point;
    private bool button_pressed = false;

    public signal void finished(bool aborted);

    construct {
        type = Gtk.WindowType.POPUP;
    }

    public AreaSelectionWindow()
    {
        Gdk.Screen screen = Gdk.Screen.get_default();

        this.set_visual(screen.get_rgba_visual());
        this.set_app_paintable(true);
        this.set_decorated(false);
        this.set_deletable(false);
        this.set_has_resize_grip(false);
        this.set_skip_taskbar_hint(true);
        this.set_skip_pager_hint(true);
        this.set_keep_above(true);
        this.set_default_size(screen.get_width(), screen.get_height());
    }

    public override bool button_press_event(Gdk.EventButton e)
    {
        if (button_pressed || e.button != 1) {
            if (e.button == 3) {
                finished(true);
            }
            return true;
        }

        button_pressed = true;

        start_point.x = (int)e.x_root;
        start_point.y = (int)e.y_root;

        return true;
    }

    public override bool button_release_event(Gdk.EventButton e)
    {
        if (!button_pressed || e.button != 1) {
            return true;
        }

        button_pressed = false;
        finished(false);

        return true;
    }

   public override bool motion_notify_event(Gdk.EventMotion e)
   {
        if (!button_pressed) {
            return true;
        }

        int x = start_point.x;
        int y = start_point.y;

        int width = (x - (int)e.x_root).abs();
        int height = (y - (int)e.y_root).abs();

        if (width < 1 || height < 1) {
            return true;
        }

        x = int.min(x, (int)e.x_root);
        y = int.min(y, (int)e.y_root);

        this.move(x, y);
        this.resize(width, height);

        return true;
    }

    public override bool key_press_event(Gdk.EventKey e)
    {
        if (e.keyval == Gdk.Key.Escape) {
            finished(true);
        }

        return true;
    }

    public override void show_all()
    {
        base.show_all ();
        var manager = Gdk.Display.get_default().get_device_manager();
        var pointer = manager.get_client_pointer();
        var keyboard = pointer.get_associated_device();
        var window = this.get_window();

        var status = pointer.grab(window,
                    Gdk.GrabOwnership.NONE,
                    false,
                    Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.POINTER_MOTION_MASK,
                    new Gdk.Cursor.for_display(window.get_display(), Gdk.CursorType.CROSSHAIR),
                    Gtk.get_current_event_time());

        if (status != Gdk.GrabStatus.SUCCESS) {
            pointer.ungrab(Gtk.get_current_event_time ());
        }

        if (keyboard != null) {
            status = keyboard.grab(window,
                    Gdk.GrabOwnership.NONE,
                    false,
                    Gdk.EventMask.KEY_PRESS_MASK,
                    null,
                    Gtk.get_current_event_time());

            if (status != Gdk.GrabStatus.SUCCESS) {
                keyboard.ungrab(Gtk.get_current_event_time());
            }
        }
    }

    public override bool draw(Cairo.Context ctx)
    {
        if (!button_pressed) {
            return true;
        }

        int w = this.get_allocated_width();
        int h = this.get_allocated_height();

        Gtk.StyleContext style = this.get_style_context();

        ctx.set_operator(Cairo.Operator.SOURCE);
        ctx.set_source_rgba(0, 0, 0, 0);
        ctx.paint();

        style.save();
        style.add_class(Gtk.STYLE_CLASS_RUBBERBAND);

        style.render_background(ctx, 0, 0, w, h);
        style.render_frame(ctx, 0, 0, w, h);

        style.restore();

        return base.draw(ctx);
    }

    public new void close()
    {
        get_window().set_cursor(null);
        base.close();
    }
}

} // End namespace