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

public class BudgieScreenshotApplet : GLib.Object, Budgie.Plugin
{
    public Budgie.Applet get_panel_widget(string uuid) {
        return new ScreenshotApplet(uuid);
    }
}

public class ScreenshotApplet : Budgie.Applet
{
    Gtk.Popover? popover = null;
    Gtk.EventBox? box = null;
    unowned Budgie.PopoverManager? manager = null;
    protected Settings settings;
    private Gtk.Label label;
    private Gtk.Label countdown_label1;
    private Gtk.Label countdown_label2;
    private Gtk.Stack stack;
    private Gtk.Clipboard clipboard;
    private NewScreenshotView new_screenshot_view;
    private CountdownView countdown_view;
    private UploadingView uploading_view;
    private UploadDoneView upload_done_view;
    private ErrorView error_view;
    private HistoryView history_view;
    private SettingsView settings_view;
    private bool error;
    private bool countdown_in_progress = false;
    public string uuid { public set ; public get; }

    public override bool supports_settings() {
        return false;
    }

    public ScreenshotApplet(string uuid)
    {
        Object(uuid: uuid);

        settings_schema = "com.github.cybre.screenshot-applet";
        settings_prefix = "/com/github/cybre/screenshot-applet";

        settings = get_applet_settings(uuid);

        settings.changed.connect(on_settings_changed);

        Gdk.Display display = get_display();
        clipboard = Gtk.Clipboard.get_for_display(display, Gdk.SELECTION_CLIPBOARD);

        Gdk.Screen screen = Gdk.Screen.get_default();
        Gtk.Settings gtk_settings = Gtk.Settings.get_for_screen(screen);
        string gtk_theme_name = gtk_settings.gtk_theme_name.down();

        if (gtk_theme_name.has_prefix("arc")) {
            Gtk.CssProvider provider = new Gtk.CssProvider();
            provider.load_from_resource("/com/github/cybre/screenshot-applet/style.css");
            Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        Gtk.Image icon = new Gtk.Image.from_icon_name("image-x-generic-symbolic", Gtk.IconSize.MENU);
        Gtk.Image icon_cheese = new Gtk.Image.from_icon_name("face-smile-big-symbolic", Gtk.IconSize.MENU);
        Gtk.Spinner spinner = new Gtk.Spinner();
        countdown_label1 = new Gtk.Label("0");
        countdown_label2 = new Gtk.Label("0");

        Gtk.Stack icon_stack = new Gtk.Stack();
        icon_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_DOWN);
        icon_stack.set_transition_duration(300);
        icon_stack.add_named(icon, "icon");
        icon_stack.add_named(spinner, "spinner");
        icon_stack.add_named(icon_cheese, "icon_cheese");
        icon_stack.add_named(countdown_label1, "countdown1");
        icon_stack.add_named(countdown_label2, "countdown2");

        label = new Gtk.Label("Screenshot");
        label.set_halign(Gtk.Align.START);

        Gtk.Box layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        layout.pack_start(icon_stack, false, false, 3);
        layout.pack_start(label, true, true, 3);

        box = new Gtk.EventBox();
        box.add(layout);

        popover = new Gtk.Popover(box);
        popover.get_style_context().add_class("screenshot-applet");
        stack = new Gtk.Stack();
        stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);

        popover.map.connect(popover_map_event);
        popover.unmap.connect(popover_unmap_event);

        new_screenshot_view = NewScreenshotView.instance(stack, popover);
        countdown_view = CountdownView.instance();
        uploading_view = UploadingView.instance();
        upload_done_view = UploadDoneView.instance(stack, popover);
        error_view = ErrorView.instance(stack);
        history_view = HistoryView.instance(settings, clipboard, stack);
        settings_view = SettingsView.instance(settings, stack);

        history_view.history_button = new_screenshot_view.history_button;
        history_view.update_child_count();

        countdown_view.cancelled.connect(() => {
            icon_stack.set_visible_child_name("icon");
            stack.set_visible_child_name("new_screenshot_view");
        });

        new_screenshot_view.countdown.connect((delay, cancellable) => {
            countdown_view.cancellable = cancellable;
            int seconds = 1;
            if (delay == 0 || delay == 1) {
                icon_stack.set_visible_child_name("icon_cheese");
            } else {
                icon_stack.set_visible_child_name("countdown1");
                countdown_in_progress = true;
                GLib.Timeout.add_full(GLib.Priority.HIGH, 950, () => {
                    if (cancellable.is_cancelled()) {
                        countdown_in_progress = false;
                        return false;
                    }
                    if (icon_stack.visible_child_name == "countdown1") {
                        icon_stack.set_visible_child_name("countdown2");
                    } else {
                        icon_stack.set_visible_child_name("countdown1");
                    }

                    int left = delay - seconds;
                    countdown_label1.label = left.to_string();
                    countdown_label2.label = left.to_string();
                    countdown_view.change_label(left);

                    if (delay == seconds) {
                        icon_stack.set_visible_child_name("icon_cheese");
                        countdown_in_progress = false;
                        return false;
                    }

                    seconds++;

                    return true;
                });
            }

            countdown_label1.label = delay.to_string();
            countdown_view.set_label(delay);
        });

        new_screenshot_view.upload_started.connect((mainloop, cancellable) => {
            uploading_view.cancellable = cancellable;
            cancellable.cancelled.connect(() => {
                mainloop.quit();
                spinner.stop();
                icon_stack.set_visible_child_name("icon");
                stack.set_visible_child_name("new_screenshot_view");
            });

            stack.set_visible_child_name("uploading_view");
            spinner.start();
            icon_stack.set_visible_child_name("spinner");
        });

        new_screenshot_view.upload_finished.connect((link, local_screenshots, title_entry, cancellable) => {
            upload_done_view.link = link;
            spinner.stop();
            icon_stack.set_visible_child_name("icon");

            if (cancellable.is_cancelled()) {
                return;
            }

            if (!popover.visible) {
                icon.get_style_context().add_class("alert");
            }

            if ((link == null || link == "")) {
                error_view.set_label("<big>We couldn't upload your image</big>\nCheck your internet connection.");
                if (popover.visible) {
                    stack.set_visible_child_name("error_view");
                }
                error = true;
                return;
            }

            if (link.has_prefix("file") || link.has_prefix("http")) {
                history_view.add_to_history(link, title_entry.text);

                if (local_screenshots) {
                    try {
                        Gdk.Pixbuf pb = new Gdk.Pixbuf.from_file(link.split("://")[1]);
                        clipboard.set_image(pb);
                    } catch (GLib.Error e) {
                        warning(e.message);
                    }
                } else {
                    clipboard.set_text(link, -1);
                }
                if (popover.visible && !cancellable.is_cancelled()) {
                    stack.set_visible_child_name("upload_done_view");
                }
                error = false;
            }
            title_entry.text = "";
        });

        new_screenshot_view.error_happened.connect((title_entry) => {
            icon_stack.set_visible_child_name("icon");
            error_view.set_label("<big>Couldn't open file</big>\nFile is missing or not an image.");
            title_entry.text = "";
            icon.get_style_context().add_class("alert");
            error = true;
        });

        stack.add_named(new_screenshot_view, "new_screenshot_view");
        stack.add_named(history_view, "history_view");
        stack.add_named(countdown_view, "countdown_view");
        stack.add_named(uploading_view, "uploading_view");
        stack.add_named(upload_done_view, "upload_done_view");
        stack.add_named(error_view, "error_view");
        stack.add_named(settings_view, "settings_view");
        stack.set_homogeneous(false);
        stack.show_all();
        stack.set_visible_child_name("new_screenshot_view");

        popover.add(stack);

        box.button_press_event.connect((e) => {
            if (popover.get_visible()) {
                popover.hide();
            } else {
                string child_to_show = "new_screenshot_view";
                if (e.button == 1) {
                    stack.set_transition_type(Gtk.StackTransitionType.NONE);
                    if (countdown_in_progress) {
                        child_to_show = "countdown_view";
                    } else if (spinner.active) {
                        child_to_show = "uploading_view";
                    } else if (icon.get_style_context().has_class("alert") && !error) {
                        child_to_show = "upload_done_view";
                        icon.get_style_context().remove_class("alert");
                    } else if (error) {
                        child_to_show = "error_view";
                        icon.get_style_context().remove_class("alert");
                        error = false;
                    } else {
                        child_to_show = "new_screenshot_view";
                    }
                } else if (e.button == 2) {
                    child_to_show = "settings_view";
                } else if (e.button == 3) {
                    child_to_show = "history_view";
                } else {
                    return Gdk.EVENT_PROPAGATE;
                }
                stack.set_visible_child_name(child_to_show);
                stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
                manager.show_popover(box);
            }
            return Gdk.EVENT_STOP;
        });

        GLib.Variant history_list = settings.get_value("history");
        for (int i=0; i<history_list.n_children(); i++) {
            history_view.update_history.begin(i, true);
        }

        add(box);
        show_all();

        on_settings_changed("enable-label");
        on_settings_changed("enable-local");
        on_settings_changed("provider");
        on_settings_changed("use-main-display");
        on_settings_changed("monitor-to-use");
        on_settings_changed("delay");
        on_settings_changed("include-border");
        on_settings_changed("window-effect");
    }

    private void popover_map_event()
    {
        // Hack to stop the entry from grabbing focus +
        new_screenshot_view.title_entry.set_can_focus(false);
        GLib.Timeout.add(1, () => {
            new_screenshot_view.title_entry.set_can_focus(true);
            return false;
        });
    }

    private void popover_unmap_event() {
        stack.set_visible_child_full("new_screenshot_view", Gtk.StackTransitionType.NONE);
    }

    protected void on_settings_changed(string key)
    {
        switch (key) {
            case "enable-label":
                label.visible = settings.get_boolean(key);
                break;
            case "enable-local":
                new_screenshot_view.local_screenshots = settings.get_boolean(key);
                if (settings.get_boolean(key)) {
                    upload_done_view.set_label("<big>The screenshot has been saved</big>");
                } else {
                    upload_done_view.set_label("<big>The link has been copied \nto your clipboard!</big>");
                }
                break;
            case "provider":
                new_screenshot_view.provider_to_use = settings.get_string(key);
                break;
            case "use-main-display":
                new_screenshot_view.use_main_display = settings.get_boolean(key);
                break;
            case "monitor-to-use":
                new_screenshot_view.monitor_to_use = settings.get_string(key);
                break;
            case "delay":
                new_screenshot_view.screenshot_delay = settings.get_int(key);
                countdown_label1.label = settings.get_int(key).to_string();
                countdown_view.set_label(settings.get_int(key));
                break;
            case "include-border":
                new_screenshot_view.include_border = settings.get_boolean(key);
                break;
            case "window-effect":
                new_screenshot_view.window_effect = settings.get_string(key);
                break;
            default:
                break;
        }
    }

    public override void update_popovers(Budgie.PopoverManager? manager)
    {
        manager.register_popover(box, popover);
        this.manager = manager;
    }
}

[ModuleInit]
public void peas_register_types(TypeModule module)
{
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(BudgieScreenshotApplet));
}