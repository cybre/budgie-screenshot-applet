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

using ScreenshotApplet.Backend;

namespace ScreenshotApplet.Widgets {

private class IndicatorIcon : Gtk.Stack
{
    private Gtk.Image taking_screenshot_icon;
    private Gtk.Stack countdown_stack;
    private Gtk.Label countdown_label1;
    private Gtk.Label countdown_label2;

    private const string[] icons = {
        "face-angel-symbolic",
        "face-cool-symbolic",
        "face-devilish-symbolic",
        "face-kiss-symbolic",
        "face-laugh-symbolic",
        "face-monkey-symbolic",
        "face-raspberry-symbolic",
        "face-smile-symbolic",
        "face-smile-big-symbolic",
        "face-smirk-symbolic",
        "face-surprise-symbolic",
        "face-wink-symbolic"
    };

    public bool countdown_in_progress = false;

    public IndicatorIcon()
    {
        this.set_transition_type(Gtk.StackTransitionType.SLIDE_DOWN);
        this.set_transition_duration(200);

        Gtk.Image normal_icon = new Gtk.Image.from_icon_name("image-x-generic-symbolic", Gtk.IconSize.MENU);
        taking_screenshot_icon = new Gtk.Image();
        Gtk.Spinner uploading_spinner = new Gtk.Spinner();
        uploading_spinner.start();
        countdown_stack = new Gtk.Stack();
        countdown_stack.set_transition_duration(200);
        countdown_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_DOWN);

        countdown_label1 = new Gtk.Label(null);
        countdown_stack.add_named(countdown_label1, "cl1");
        countdown_label2 = new Gtk.Label(null);
        countdown_stack.add_named(countdown_label2, "cl2");

        this.add_named(normal_icon, "normal");
        this.add_named(taking_screenshot_icon, "taking_screenshot");
        this.add_named(uploading_spinner, "uploading");
        this.add_named(countdown_stack, "countdown");

        show_all();

        BackendUtil.screenshot_manager.screenshot.connect(start_countdown);

        BackendUtil.uploader.upload_started.connect(() => {
            this.set_visible_child_name("uploading");
        });

        BackendUtil.uploader.upload_finished.connect(() => {
            this.set_visible_child_name("normal");
            if (!IndicatorWindow.get_instance().get_visible() && !BackendUtil.settings_manager.open_popover) {
                this.get_style_context().add_class("alert");
            }
        });
    }

    public async void start_countdown(ScreenshotType mode)
    {
        int delay = 0;
        if (BackendUtil.settings_manager.use_global_delay) {
            delay = BackendUtil.settings_manager.delay_global;
        } else {
            switch (mode) {
                case ScreenshotType.SCREEN:
                    delay = BackendUtil.settings_manager.delay_screen;
                    break;
                case ScreenshotType.WINDOW:
                    delay = BackendUtil.settings_manager.delay_window;
                    break;
                case ScreenshotType.SELECTION:
                    delay = BackendUtil.settings_manager.delay_selection;
                    break;
                default:
                    delay = 0;
                    break;
            }
        }

        taking_screenshot_icon.set_from_icon_name(icons[GLib.Random.int_range(0, icons.length)], Gtk.IconSize.MENU);

        if (delay < 2) {
            this.set_visible_child_name("taking_screenshot");
            GLib.Timeout.add_seconds(delay + 1, () => {
                if (!BackendUtil.uploader.is_upload_in_progress()) {
                    this.set_visible_child_name("normal");
                } else {
                    this.set_visible_child_name("uploading");
                }
                return false;
            });
            return;
        }

        countdown_in_progress = true;
        int passed = 0;

        this.set_visible_child_name("countdown");
        countdown_label1.set_markup(@"<b>$(delay.to_string())</b>");
        countdown_stack.set_visible_child_name("cl1");

        GLib.Timeout.add(1000, () => {
            passed++;

            if (passed == 1) {
                Views.MainView.get_instance().disable_buttons();
            }

            if (passed == delay) {
                Views.MainView.get_instance().enable_buttons();
                this.set_visible_child_name("taking_screenshot");
                countdown_in_progress = false;
            } else {
                if (countdown_stack.get_visible_child_name() == "cl1") {
                    countdown_label2.set_markup(@"<b>$((delay - passed).to_string())</b>");
                    countdown_stack.set_visible_child_name("cl2");
                } else {
                    countdown_label1.set_markup(@"<b>$((delay - passed).to_string())</b>");
                    countdown_stack.set_visible_child_name("cl1");
                }
            }

            if (passed == delay + 1) {
                if (!BackendUtil.uploader.is_upload_in_progress()) {
                    this.set_visible_child_name("normal");
                } else {
                    this.set_visible_child_name("uploading");
                }
                countdown_label1.set_text("");
                countdown_label2.set_text("");
                return false;
            }

            return true;
        });
    }
}

} // End namespace