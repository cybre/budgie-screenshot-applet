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

public abstract class ScreenshotAbstract
{
    public abstract async bool take_screenshot(out string? uri);

    public void include_pointer(Gdk.Window? window, ref Gdk.Pixbuf screenshot)
    {
        Gdk.Cursor cursor = new Gdk.Cursor.for_display(Gdk.Display.get_default(), Gdk.CursorType.LEFT_PTR);
        Gdk.Pixbuf cursor_pixbuf = cursor.get_image();

        if (cursor_pixbuf != null) {
            Gdk.DeviceManager manager = Gdk.Display.get_default().get_device_manager();
            Gdk.Device device = manager.get_client_pointer();

            int cx, cy;
            window.get_device_position(device, out cx, out cy, null);

            Gdk.Rectangle win_rect;
            window.get_frame_extents(out win_rect);

            int width_offset = 0;
            int height_offset = 0;

            if (BackendUtil.settings_manager.include_border) {
                width_offset = win_rect.width - window.get_width();
                height_offset = win_rect.height - window.get_height();
            }

            Gdk.Rectangle cursor_rect = Gdk.Rectangle();
            cursor_rect.x = cx + win_rect.x + width_offset;
            cursor_rect.y = cy + win_rect.y + height_offset;
            cursor_rect.width = cursor_pixbuf.get_width();
            cursor_rect.height = cursor_pixbuf.get_height();

            if (win_rect.intersect(cursor_rect, null)) {
                int xhot, yhot;
                xhot = int.parse(cursor_pixbuf.get_option("x_hot"));
                yhot = int.parse(cursor_pixbuf.get_option("y_hot"));

                int cursor_x, cursor_y;
                cursor_x = cx - xhot + width_offset;
                cursor_y = cy - yhot + height_offset;

                if (cursor_x < 0 || cursor_y < 0) {
                    return;
                }

                if (cursor_x + cursor_rect.width > screenshot.width) {
                    cursor_rect.width = screenshot.width - cursor_x;
                }

                if (cursor_y + cursor_rect.height > screenshot.height) {
                    cursor_rect.height = screenshot.height - cursor_y;
                }

                cursor_pixbuf.composite(screenshot, cursor_x, cursor_y, cursor_rect.width, cursor_rect.height, cursor_x, cursor_y, 1.0, 1.0, Gdk.InterpType.BILINEAR, 255);
            }
        }
    }

    public async bool save_screenshot(Gdk.Pixbuf? screenshot, out string? uri) {
        uri = null;

        if (screenshot == null) {
            return false;
        }

        string save_path = BackendUtil.settings_manager.save_path;

        if (save_path == "") {
            save_path = GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, GLib.Environment.get_user_special_dir(GLib.UserDirectory.PICTURES), _("Screenshots"));
            if (save_path.has_prefix(GLib.Environment.get_home_dir())) {
                try {
                    GLib.Regex a = new GLib.Regex(GLib.Environment.get_home_dir());
                    save_path = a.replace(save_path, save_path.length, 0, "~", GLib.RegexMatchFlags.ANCHORED);
                } catch (GLib.RegexError e) {
                    warning(e.message);
                }
            }
            BackendUtil.settings_manager.save_path = save_path;
        }

        if (save_path.has_prefix("~")) {
            save_path = save_path.replace("~", GLib.Environment.get_home_dir());
        }

        GLib.File save_path_file = GLib.File.new_for_path(save_path);

        if (!save_path_file.query_exists()) {
            try {
                save_path_file.make_directory();
            } catch (GLib.Error e) {
                warning(e.message);
                return false;
            }
        }

        try {
            GLib.FileInfo info = save_path_file.query_info(
                GLib.FileAttribute.ACCESS_CAN_WRITE, GLib.FileQueryInfoFlags.NONE);
            bool writable = info.get_attribute_boolean(GLib.FileAttribute.ACCESS_CAN_WRITE);
            if (!writable) {
                warning("Destination not writable");
                return false;
            }
        } catch (GLib.Error e) {
            warning(e.message);
            return false;
        }

        GLib.DateTime datetime = new GLib.DateTime.now_local();
        string filename = _("Screenshot from %s").printf(datetime.format("%Y-%m-%d %H:%M:%S")) + ".png";

        save_path = @"$save_path/$filename";

        GLib.Idle.add(()=> {
            try {
                screenshot.save(save_path, "png");
            } catch (GLib.Error e) {
                warning(e.message);
            }
            save_screenshot.callback();
            return false;
        });

        yield;

        screenshot = null;

        if (!GLib.File.new_for_path(save_path).query_exists()) {
            return false;
        }

        uri = @"file://$save_path";

        return true;
    }
}

} // End namespace