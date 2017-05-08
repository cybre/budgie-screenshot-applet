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

private class Screen : ScreenshotAbstract
{
    public override async bool take_screenshot(out string? uri) {
        string monitor_to_use = BackendUtil.settings_manager.monitor_to_use;
        Gdk.Pixbuf? screenshot;
        bool status = false;

        uri = null;

        if (monitor_to_use == "all") {
            status = yield screen_screenshot(out screenshot);
        } else {
            status = yield monitor_screenshot(monitor_to_use, out screenshot);
        }

        if (!status) {
            return false;
        }

        if (BackendUtil.settings_manager.include_pointer) {
            include_pointer(Gdk.get_default_root_window(), ref screenshot);
        }

        bool saved = false;
        saved = yield save_screenshot(screenshot, out uri);

        screenshot = null;

        return saved;
    }

    private async bool monitor_screenshot(string monitor_to_use, out Gdk.Pixbuf screenshot)
    {
        Gdk.Screen screen = Gdk.Screen.get_default();

        Gdk.Rectangle? geometry = null;

        screenshot = null;

        foreach (unowned Gnome.RROutputInfo output_info in get_outputs()) {
            string name = output_info.get_name();
            if (monitor_to_use == name) {
                geometry = Gdk.Rectangle();
                output_info.get_geometry(out geometry.x, out geometry.y,
                    out geometry.width, out geometry.height);
            }
        }

        if (geometry == null) {
            return false;
        }

        Gdk.Window root = screen.get_root_window();
        screenshot = yield capture(root, geometry);

        if (screenshot == null) {
            return false;
        }

        return true;
    }

    private async bool screen_screenshot(out Gdk.Pixbuf screenshot)
    {
        Gdk.Screen screen = Gdk.Screen.get_default();
        Cairo.RectangleInt rect = Cairo.RectangleInt();

        rect.x = 0;
        rect.y = 0;
        rect.width = screen.get_width();
        rect.height = screen.get_height();

        Cairo.Region region = get_monitor_region();
        Cairo.Region invisible_region = new Cairo.Region.rectangle(rect);
        invisible_region.subtract(region);

        Gdk.Window root = screen.get_root_window();
        screenshot = yield capture(root, (Gdk.Rectangle)rect);

        if (screenshot == null) {
            return false;
        }

        blackify_region(ref screenshot, invisible_region);

        return true;
    }

    private async Gdk.Pixbuf capture(Gdk.Window root, Gdk.Rectangle geometry) {
        Gdk.Pixbuf? ss = null;

        int delay = (BackendUtil.settings_manager.use_global_delay) ? BackendUtil.settings_manager.delay_global : BackendUtil.settings_manager.delay_screen;

        GLib.Timeout.add(400 + (delay * 1000), () => {
            ss = Gdk.pixbuf_get_from_window(root, geometry.x, geometry.y, geometry.width, geometry.height);
            capture.callback();
            return false;
        });

        yield;

        return ss;
    }

    private Gnome.RROutputInfo[]? get_outputs()
    {
        Gdk.Screen screen = Gdk.Screen.get_default();

        Gnome.RRScreen rr_screen;
        Gnome.RRConfig rr_config;

        try {
            rr_screen = new Gnome.RRScreen(screen);
            rr_config = new Gnome.RRConfig.current(rr_screen);
        } catch (GLib.Error e) {
            warning(e.message);
            return null;
        }

        return rr_config.get_outputs();
    }

    private Cairo.Region get_monitor_region()
    {
        Gdk.Screen screen = Gdk.Screen.get_default();
        Cairo.Region region = new Cairo.Region();

        for (int i=0; i < screen.get_n_monitors(); i++) {
            Gdk.Rectangle rect;
            screen.get_monitor_geometry(i, out rect);
            region.union_rectangle(rect);
        }

        return region;
    }

    private void blackify_region(ref Gdk.Pixbuf pb, Cairo.Region region)
    {
        Gdk.Rectangle pb_rect = Gdk.Rectangle();
        pb_rect.x = 0;
        pb_rect.y = 0;
        pb_rect.width = pb.get_width();
        pb_rect.height = pb.get_height();

        for (int i = 0; i < region.num_rectangles(); i++) {
            Gdk.Rectangle rect = (Gdk.Rectangle)region.get_rectangle(i);
            Gdk.Rectangle dest;
            if (rect.intersect(pb_rect, out dest)) {
                blackify_rectangle(ref pb, dest);
            }
        }
    }

    private void blackify_rectangle(ref Gdk.Pixbuf pb, Cairo.RectangleInt rect)
    {
        Gdk.Pixbuf small_pb = new Gdk.Pixbuf(Gdk.Colorspace.RGB, false, 8, rect.width, rect.height);
        small_pb.fill(0x000000ff);
        small_pb.copy_area(0, 0, rect.width, rect.height, pb, rect.x, rect.y);
    }

}

} // End namespace