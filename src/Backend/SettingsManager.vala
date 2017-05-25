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

namespace ScreenshotApplet.Backend
{

class SettingsManager : GLib.Object
{
    private GLib.Settings settings;

    public bool ask_to_upload {
        get {
            return settings.get_boolean("ask-to-upload");
        }
    }

    public bool automatic_copy {
        get {
            return settings.get_boolean("automatic-copy");
        }
    }

    public bool automatic_upload {
        get {
            return settings.get_boolean("automatic-upload");
        }
    }

    public bool dont_save {
        get {
            return settings.get_boolean("dont-save");
        }
    }

    public int delay_global {
        get {
            return settings.get_int("delay-global");
        }
    }

    public int delay_screen {
        get {
            return settings.get_int("delay-screen");
        }
    }

    public int delay_selection {
        get {
            return settings.get_int("delay-selection");
        }
    }

    public int delay_window {
        get {
            return settings.get_int("delay-window");
        }
    }

    public bool delete_files {
        get {
            return settings.get_boolean("delete-files");
        }
    }

    public bool include_border {
        get {
            return settings.get_boolean("include-border");
        }
    }

    public bool include_pointer {
        get {
            return settings.get_boolean("include-pointer");
        }
    }

    public string monitor_to_use {
        owned get {
            return settings.get_string("monitor-to-use");
        }
        set {
            settings.set_string("monitor-to-use", value);
        }
    }

    public bool open_popover {
        get {
            return settings.get_boolean("open-popover");
        }
    }

    public bool save_history {
        get {
            return settings.get_boolean("save-history");
        }
    }

    public string save_path {
        owned get {
            return settings.get_string("save-path");
        }
        set {
            settings.set_string("save-path", value);
        }
    }

    public bool show_thumbnails {
        get {
            return settings.get_boolean("show-thumbnails");
        }
        set {}
    }

    public string upload_provider {
        owned get {
            return settings.get_string("upload-provider");
        }
    }

    public bool use_global_delay {
        get {
            return settings.get_boolean("use-global-delay");
        }
    }

    // All of the keys we use
    private const string[] global_keys = {
        "ask-to-upload",
        "automatic-copy",
        "automatic-upload",
        "delay-global",
        "delete-files",
        "open-popover",
        "save-history",
        "save-path",
        "show-thumbnails",
        "upload-provider",
        "use-global-delay"
    };

    private const string[] individual_keys = {
        "delay-screen",
        "delay-selection",
        "delay-window",
        "include-border",
        "monitor-to-use"
    };

    public SettingsManager(GLib.Settings applet_settings) {
        settings = applet_settings;

        // Initialize save_path if not set
        if (save_path == "") {
            string path = "%s/%s".printf(GLib.Environment.get_user_special_dir(GLib.UserDirectory.PICTURES), _("Screenshots"));
            if (path.has_prefix(GLib.Environment.get_home_dir())) {
                try {
                    GLib.Regex a = new GLib.Regex(GLib.Environment.get_home_dir());
                    path = a.replace(path, path.length, 0, "~", GLib.RegexMatchFlags.ANCHORED);
                } catch(GLib.RegexError e) {
                    warning(e.message);
                }
            }
            save_path = path;
        }

    }

    public void reset_all(string type) {

        if (type == "provider") {
            GLib.Settings? psettings = BackendUtil.uploader.get_providers().get(upload_provider).get_settings();
            if (psettings == null) {
                return;
            }
            foreach (string key in psettings.list_keys()) {
                psettings.reset(key);
            }
            return;
        }

        if (type == "individual") {
            foreach (string key in individual_keys) {
                settings.reset(key);
            }
            return;
        }

        foreach (string key in global_keys) {
            settings.reset(key);
            if (key == "save-path") {
                string path = "%s/%s".printf(
                    GLib.Environment.get_user_special_dir(GLib.UserDirectory.PICTURES), _("Screenshots"));
                if (path.has_prefix(GLib.Environment.get_home_dir())) {
                    try {
                        GLib.Regex a = new GLib.Regex(GLib.Environment.get_home_dir());
                        path = a.replace(path, path.length, 0, "~", GLib.RegexMatchFlags.ANCHORED);
                    } catch (GLib.RegexError e) {
                        warning(e.message);
                    }
                }
                save_path = path;
            }
        }
    }

    public Gtk.ListStore? get_monitor_list(out int active)
    {
        Gtk.ListStore monitors = new Gtk.ListStore(2, typeof(string), typeof(string));
        Gtk.TreeIter iter;

        active = 0;

        Gdk.Screen screen = Gdk.Screen.get_default();
        int n_monitors = screen.get_n_monitors();

        Gnome.RRScreen rr_screen;
        Gnome.RRConfig rr_config;

        try {
            rr_screen = new Gnome.RRScreen(screen);
            rr_config = new Gnome.RRConfig.current(rr_screen);
        } catch (GLib.Error e) {
            warning(e.message);
            return null;
        }

        int pos = 0;

        string[] names = new string[n_monitors];

        if (n_monitors > 1) {
            monitors.append(out iter);
            monitors.set(iter, 0, "all", 1, _("All monitors"));
            names[pos] = "all";
            if (monitor_to_use == "all") {
                active = pos;
            }
            pos++;
        }

        foreach (unowned Gnome.RROutputInfo output_info in rr_config.get_outputs()) {
            if (output_info.is_active()) {
                string name = output_info.get_name();
                string display_name = output_info.get_display_name();
                names[pos] = name;

                if (monitor_to_use == name) {
                    active = pos;
                }

                monitors.append(out iter);
                monitors.set(iter, 0, name, 1, display_name);

                pos++;
            }
        }

        return monitors;
    }

    public unowned GLib.Settings get_settings() {
        return settings;
    }
}

} // End namespace