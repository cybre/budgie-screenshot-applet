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

namespace ScreenshotApplet.Backend.ScreenshotMode
{

private class Window : ScreenshotAbstract
{
    public override async bool take_screenshot(out string? uri) {
        Gdk.Pixbuf? screenshot = null;
        Gdk.Window? window = null;
        Gdk.Window? window_to_use = null;
        Gdk.Screen screen = Gdk.Screen.get_default();
        GLib.List<Gdk.Window> list = null;

        uri = null;

        int delay = (BackendUtil.settings_manager.use_global_delay) ? BackendUtil.settings_manager.delay_global : BackendUtil.settings_manager.delay_window;

        GLib.Timeout.add(400 + (delay * 1000), () => {
            window = get_current_window();
            Gdk.Rectangle rect = Gdk.Rectangle();

            list = screen.get_window_stack();
            foreach (Gdk.Window item in list) {
                item.set_events(item.get_events() | Gdk.EventMask.STRUCTURE_MASK);
            }

            if (BackendUtil.settings_manager.include_border) {
                window.get_frame_extents(out rect);
                window_to_use = Gdk.get_default_root_window();
            } else {
                rect.x = 0;
                rect.y = 0;
                rect.width = window.get_width();
                rect.height = window.get_height();
                window_to_use = window;
            }

            if (rect.x < 0) {
                rect.width = rect.width + rect.x;
            }

            if (rect.y < 0) {
                rect.height = rect.height + rect.y;
            }

            if (rect.x + rect.width > Gdk.Screen.width()) {
                rect.width = Gdk.Screen.width() - rect.x;
            }

            if (rect.y + rect.height > Gdk.Screen.height()) {
                rect.height = Gdk.Screen.height() - rect.y;
            }

            screenshot = Gdk.pixbuf_get_from_window(window_to_use, rect.x, rect.y, rect.width, rect.height);

            take_screenshot.callback();
            return false;
        });

        yield;

        if (screenshot == null) {
            return false;
        }

        if (BackendUtil.settings_manager.include_pointer) {
            include_pointer(window, ref screenshot);
        }

        bool saved = false;
        saved = yield save_screenshot(screenshot, out uri);

        return saved;
    }

    private Gdk.Window? get_current_window()
    {
        Gdk.Screen screen = Gdk.Screen.get_default();
        Gdk.Window? current_window = screen.get_active_window();
        Gdk.DeviceManager manager = Gdk.Display.get_default().get_device_manager();
        Gdk.Device device = manager.get_client_pointer();

        if (current_window == null) {
            current_window = device.get_window_at_position(null, null);
        } else {
            if (window_is_desktop(current_window)) {
                return null;
            }
            //current_window = current_window.get_toplevel();
        }

        return current_window;
    }

    private bool window_is_desktop(Gdk.Window window)
    {
        Gdk.Window root_window = Gdk.get_default_root_window();
        Gdk.WindowTypeHint window_hint = window.get_type_hint();

        if (window == root_window) {
            return true;
        }

        if (window_hint == Gdk.WindowTypeHint.DESKTOP) {
            return true;
        }

        return false;
    }
}

} // End namespace