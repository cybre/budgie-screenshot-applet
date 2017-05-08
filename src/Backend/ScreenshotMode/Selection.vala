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

namespace ScreenshotApplet.Backend.ScreenshotMode
{

private class Selection : ScreenshotAbstract
{
    public override async bool take_screenshot(out string? uri) {
        Gdk.Screen screen = Gdk.Screen.get_default();
        Gdk.Window root = screen.get_root_window();
        Gdk.Pixbuf? screenshot = null;
        Widgets.AreaSelectionWindow area_window = new Widgets.AreaSelectionWindow();
        area_window.show_all();

        uri = null;

        Gdk.Window window = area_window.get_window();

        area_window.finished.connect((aborted) => {
            area_window.hide();

            if (aborted) {
                take_screenshot.callback();
                return;
            }

            // TODO: CHECK DIMENSIONS/GEOMETRY
            BackendUtil.screenshot_manager.screenshot(ScreenshotType.SELECTION);

            Gdk.Rectangle geometry;
            window.get_frame_extents(out geometry);

            int delay = (BackendUtil.settings_manager.use_global_delay) ? BackendUtil.settings_manager.delay_global : BackendUtil.settings_manager.delay_selection;

            GLib.Timeout.add(400 + (delay * 1000), () => {
                area_window.close();
                screenshot = new Gdk.Pixbuf.subpixbuf(
                    Gdk.pixbuf_get_from_window(root, 0, 0, root.get_width(), root.get_height()),
                    geometry.x, geometry.y, geometry.width, geometry.height);
                take_screenshot.callback();
                return false;
            });
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
}

} // End namespace