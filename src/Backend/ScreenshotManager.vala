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

namespace ScreenshotApplet
{
    enum ScreenshotType {
        SCREEN,
        WINDOW,
        SELECTION
    }
}

namespace ScreenshotApplet.Backend
{

private class ScreenshotManager
{
    private GLib.HashTable<string, ScreenshotMode.ScreenshotAbstract> screenshot_modes;

    public signal void screenshot(ScreenshotType mode);

    public ScreenshotManager() {
        screenshot_modes = new GLib.HashTable<string, ScreenshotMode.ScreenshotAbstract>(str_hash, str_equal);

        screenshot_modes.set((ScreenshotType.SCREEN).to_string(), new ScreenshotMode.Screen());
        screenshot_modes.set((ScreenshotType.WINDOW).to_string(), new ScreenshotMode.Window());
        screenshot_modes.set((ScreenshotType.SELECTION).to_string(), new ScreenshotMode.Selection());
    }

    public async void take_screenshot(ScreenshotType mode, string title)
    {
        unowned ScreenshotMode.ScreenshotAbstract? screenshot_mode = screenshot_modes.get(mode.to_string());

        if (screenshot_mode == null) {
            return;
        }

        string? URI = null;

        bool status = true;

        if (mode != ScreenshotType.SELECTION) {
            screenshot(mode);
        }

        status = yield screenshot_mode.take_screenshot(out URI);

        if (!status) {
            return;
        }

        Views.MainView._title_entry.set_text("");

        if (BackendUtil.settings_manager.dont_save) {
            return;
        }

        Gtk.RecentManager.get_default().add_item(URI);

        Widgets.MainStack.set_page("history_view");

        GLib.DateTime datetime = new GLib.DateTime.now_local();
        int64 timestamp = datetime.to_unix();

        Views.HistoryView.get_instance().add_to_history.begin(timestamp, title, URI);

        if (BackendUtil.settings_manager.open_popover) {
            GLib.Idle.add(() => {
                Applet.get_instance().open_popover();
                return false;
            });
        }
    }
}

} // End namespace