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

public class Screenshot : GLib.Object, Budgie.Plugin
{
    public Budgie.Applet get_panel_widget(string uuid) {
        return new ScreenshotApplet.ScreenshotApplet(uuid);
    }
}

[GtkTemplate (ui = "/com/github/cybre/screenshot-applet/settings.ui")]
public class ScreenshotAppletSettings : Gtk.Grid
{
    [GtkChild]
    private Gtk.Switch? switch_label;

    [GtkChild]
    private Gtk.Switch? switch_local;

    [GtkChild]
    private Gtk.ComboBox? combobox_provider;

    [GtkChild]
    private Gtk.SpinButton spinbutton_delay;

    [GtkChild]
    private Gtk.Switch? switch_border;

    [GtkChild]
    private Gtk.ComboBox? combobox_effect;

    private Settings? settings;

    public ScreenshotAppletSettings(Settings? settings)
    {
        Gtk.ListStore providers = new Gtk.ListStore(2, typeof(string), typeof(string));
        Gtk.TreeIter iter;

        providers.append(out iter);
        providers.set(iter, 0, "imgur", 1, "Imgur.com");
        providers.append(out iter);
        providers.set(iter, 0, "ibin", 1, "Ibin.co");
        combobox_provider.set_model(providers);

        Gtk.CellRendererText renderer = new Gtk.CellRendererText();
        combobox_provider.pack_start(renderer, true);
        combobox_provider.add_attribute(renderer, "text", 1);
        combobox_provider.active = 0;
        combobox_provider.set_id_column(0);

        Gtk.ListStore effects = new Gtk.ListStore(2, typeof(string), typeof(string));

        effects.append(out iter);
        effects.set(iter, 0, "none", 1, "None");
        effects.append(out iter);
        effects.set(iter, 0, "shadow", 1, "Drop shadow");
        effects.append(out iter);
        effects.set(iter, 0, "border", 1, "Border");
        effects.append(out iter);
        effects.set(iter, 0, "vintage", 1, "Vintage");

        combobox_effect.set_model(effects);
        Gtk.CellRendererText renderer1 = new Gtk.CellRendererText();
        combobox_effect.pack_start(renderer1, true);
        combobox_effect.add_attribute(renderer1, "text", 1);
        combobox_effect.active = 0;
        combobox_effect.set_id_column(0);

        this.settings = settings;

        settings.bind("enable-label", switch_label, "active", SettingsBindFlags.DEFAULT);
        settings.bind("enable-local", switch_local, "active", SettingsBindFlags.DEFAULT);
        settings.bind("provider", combobox_provider, "active_id", SettingsBindFlags.DEFAULT);
        settings.bind("delay", spinbutton_delay, "value", SettingsBindFlags.DEFAULT);
        settings.bind("include-border", switch_border, "active", SettingsBindFlags.DEFAULT);
        settings.bind("window-effect", combobox_effect, "active_id", SettingsBindFlags.DEFAULT);
    }
}

namespace ScreenshotApplet {
    public class ScreenshotApplet : Budgie.Applet
    {
        Gtk.Popover? popover = null;
        Gtk.EventBox? box = null;
        unowned Budgie.PopoverManager? manager = null;
        protected Settings settings;
        private Gtk.Spinner spinner;
        private Gtk.Image icon;
        private Gtk.Label label;
        private Gtk.Stack stack;
        private Gtk.Clipboard clipboard;
        private Gdk.Display display;
        private NewScreenshotView new_screenshot_view;
        private UploadingView uploading_view;
        private UploadDoneView upload_done_view;
        private ErrorView error_view;
        private HistoryView history_view;
        private bool error;
        public string uuid { public set ; public get; }

        public override Gtk.Widget? get_settings_ui() {
            return new ScreenshotAppletSettings(this.get_applet_settings(uuid));
        }

        public override bool supports_settings() {
            return true;
        }

        public ScreenshotApplet(string uuid)
        {
            Object(uuid: uuid);

            settings_schema = "com.github.cybre.screenshot-applet";
            settings_prefix = "/com/github/cybre/screenshot-applet";

            settings = get_applet_settings(uuid);

            settings.changed.connect(on_settings_changed);

            display = get_display();
            clipboard = Gtk.Clipboard.get_for_display(display, Gdk.SELECTION_CLIPBOARD);

            box = new Gtk.EventBox();
            spinner = new Gtk.Spinner();
            icon = new Gtk.Image.from_icon_name("image-x-generic-symbolic", Gtk.IconSize.MENU);
            Gtk.Box layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            layout.pack_start(spinner, false, false, 3);
            layout.pack_start(icon, false, false, 3);
            label = new Gtk.Label("Screenshot");
            label.halign = Gtk.Align.START;
            layout.pack_start(label, true, true, 3);
            box.add(layout);

            popover = new Gtk.Popover(box);
            stack = new Gtk.Stack();

            popover.map.connect(popover_map_event);

            new_screenshot_view = new NewScreenshotView(stack, popover);
            uploading_view = new UploadingView();
            upload_done_view = new UploadDoneView(stack, popover);
            error_view = new ErrorView(stack);
            history_view = new HistoryView(settings, clipboard, stack);

            new_screenshot_view.upload_started.connect((mainloop, cancellable) => {
                uploading_view.cancellable = cancellable;
                cancellable.cancelled.connect(() => {
                    mainloop.quit();
                    spinner.active = false;
                    spinner.visible = false;
                    icon.visible = true;
                    stack.set_visible_child_full("new_screenshot_view", Gtk.StackTransitionType.SLIDE_RIGHT);
                });

                stack.visible_child_name = "uploading_view";
                icon.visible = false;
                spinner.active = true;
                spinner.visible = true;
            });

            new_screenshot_view.upload_finished.connect((link, local_screenshots, title_entry, cancellable) => {
                upload_done_view.link = link;
                spinner.active = false;
                spinner.visible = false;
                icon.visible = true;
                if (popover.visible == false && !cancellable.is_cancelled()) {
                    icon.get_style_context().add_class("alert");
                }

                if (link != "") {
                    history_view.add_to_history(link, title_entry.text);

                    if (local_screenshots) {
                        try {
                            Gdk.Pixbuf pb = new Gdk.Pixbuf.from_file(link.split("://")[1]);
                            clipboard.set_image(pb);
                        } catch (GLib.Error e) {
                            stderr.printf(e.message, "\n");
                        }
                    } else {
                        clipboard.set_text(link, -1);
                    }
                    if (popover.visible && !cancellable.is_cancelled()) {
                        stack.visible_child_name = "upload_done_view";
                    }
                    error = false;
                } else if (!cancellable.is_cancelled()) {
                    error_view.set_label("<big>We couldn't upload your image</big>\nCheck your internet connection.");
                    if (popover.visible) {
                        stack.visible_child_name = "error_view";
                    }
                    error = true;
                }
                title_entry.text = "";
            });

            new_screenshot_view.error_happened.connect((title_entry) => {
                error_view.set_label("<big>Couldn't open file</big>\nFile is missing or not an image.");
                title_entry.text = "";
                icon.get_style_context().add_class("alert");
                error = true;
            });

            stack.add_named(new_screenshot_view, "new_screenshot_view");
            stack.add_named(uploading_view, "uploading_view");
            stack.add_named(upload_done_view, "upload_done_view");
            stack.add_named(history_view, "history_view");
            stack.add_named(error_view, "error_view");
            stack.homogeneous = false;
            stack.show_all();
            stack.visible_child_name = "new_screenshot_view";

            popover.add(stack);

            box.button_press_event.connect((e) => {
                if (popover.get_visible()) {
                    popover.hide();
                } else {
                    if (e.button == 1) {
                        stack.transition_type = Gtk.StackTransitionType.NONE;
                        manager.show_popover(box);
                        if (spinner.active) {
                            stack.visible_child_name = "uploading_view";
                        } else if (icon.get_style_context().has_class("alert") && !error) {
                            stack.visible_child_name = "upload_done_view";
                            icon.get_style_context().remove_class("alert");
                        } else if (error) {
                            stack.visible_child_name = "error_view";
                            icon.get_style_context().remove_class("alert");
                            error = false;
                        } else {
                            stack.visible_child_name = "new_screenshot_view";
                        }
                        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT;
                    } else if (e.button == 3) {
                        stack.set_visible_child_full("history_view", Gtk.StackTransitionType.SLIDE_LEFT);
                    } else {
                        return Gdk.EVENT_PROPAGATE;
                    }
                    manager.show_popover(box);
                }
                return Gdk.EVENT_STOP;
            });

            GLib.Variant history_list = settings.get_value("history");
            for (int i=0; i<history_list.n_children(); i++) {
                history_view.update_history(i, true);
            }

            add(box);
            show_all();

            spinner.visible = false;

            on_settings_changed("enable-label");
            on_settings_changed("enable-local");
            on_settings_changed("provider");
            on_settings_changed("delay");
            on_settings_changed("include-border");
            on_settings_changed("window-effect");
        }

        private async void popover_map_event()
        {
            /* This makes sure the window that was focused before opening
               the popover gets focused when taking a screenshot because
               budgie-panel grabs the focus when the popover gets closed. */
            if (Gdk.Screen.get_default().get_active_window().get_toplevel() != box.get_window().get_toplevel()) {
                new_screenshot_view.old_window = Gdk.Screen.get_default().get_active_window();
            }

            // Hack to stop the entry from grabbing focus +
            new_screenshot_view.title_entry.can_focus = false;
            yield sleep_async(1);
            new_screenshot_view.title_entry.can_focus = true;
        }

        private async void sleep_async(int timeout)
        {
            uint timeout_src = 0;
            timeout_src = GLib.Timeout.add(timeout, sleep_async.callback);
            yield;
            GLib.Source.remove(timeout_src);
        }

        protected void on_settings_changed(string key)
        {
            switch (key)
            {
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
                case "delay":
                    new_screenshot_view.screenshot_delay = settings.get_int(key);
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
}

[ModuleInit]
public void peas_register_types(TypeModule module)
{
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(Screenshot));
}