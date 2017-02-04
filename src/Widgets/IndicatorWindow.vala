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

namespace ScreenshotApplet.Widgets
{

public class IndicatorWindow : Gtk.Popover {
    private static IndicatorWindow? _instance = null;

    public IndicatorWindow(Gtk.Widget? window_parent) {
        GLib.Object(relative_to: window_parent);

        this.set_size_request(320, -1);
        this.get_style_context().add_class("budgie-screenshot-applet");

        IndicatorWindow._instance = this;

        MainStack main_stack = new MainStack();
        this.add(main_stack);

        this.map.connect(popover_map_event);
        this.closed.connect_after(popover_closed_event);
    }

    private void popover_map_event()
    {
        // Hack to stop the entry from grabbing focus +
        Views.MainView._title_entry.set_can_focus(false);
        GLib.Timeout.add(1, () => {
            Views.MainView._title_entry.set_can_focus(true);
            return false;
        });
    }

    private void popover_closed_event()
    {
        GLib.Timeout.add(200, () => {
            Views.MainView.contract_quick_settings(false);
            MainStack.set_page("main_view", false);
            return false;
        });
    }

    public static unowned IndicatorWindow? get_instance() {
        return _instance;
    }
}

} // End namespace