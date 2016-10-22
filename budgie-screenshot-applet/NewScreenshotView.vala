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

private class ScreenshotApplet.ScreenshotModeButton : Gtk.ToolButton
{
    public ScreenshotModeButton(string image, string label, string tooltip)
    {
        set_tooltip_text(tooltip);

        Gtk.Image mode_image = new Gtk.Image.from_resource("/com/github/cybre/screenshot-applet/images/%s".printf(image));
        mode_image.set_pixel_size(64);

        Gtk.Label mode_label = new Gtk.Label(label);
        mode_label.set_halign(Gtk.Align.CENTER);

        Gtk.Box button_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        button_box.set_size_request(80, 100);
        button_box.add(mode_image);
        button_box.add(mode_label);

        label_widget = button_box;

        get_child().set_can_focus(false);

        get_child().get_style_context().add_class("mode-button");
    }
}

public class ScreenshotApplet.NewScreenshotView : Gtk.Grid
{
    private Gtk.Popover popover;
    private GLib.Cancellable cancellable;
    private GLib.Cancellable cancellable_c;
    private GLib.File screenshot_file;
    private string link;
    private string filepath;
    public string provider_to_use { set; get; default = "imgur"; }
    public string window_effect { set; get; default = "none"; }
    public string monitor_to_use { set; get; default = ""; }
    public int screenshot_delay { set; get; default = 3; }
    public bool use_main_display { set; get; default = true; }
    public bool include_border { set; get; default = true; }
    public bool local_screenshots { set; get; default = false; }
    public Gtk.Entry title_entry;
    public Gtk.Button history_button;

    private static GLib.Once<NewScreenshotView> _instance;

    public signal void upload_started(GLib.MainLoop mainloop, GLib.Cancellable cancellable);
    public signal void upload_finished(string link, bool local_screenshots, Gtk.Entry title_entry, GLib.Cancellable cancellable);
    public signal void error_happened(Gtk.Entry title_entry);

    public signal void local_upload_started();
    public signal void local_upload_finished(string link);

    public signal void countdown(string mode, int delay, GLib.Cancellable cancellable);

    struct ScreenGeometry {
        int x;
        int y;
        int width;
        int height;
    }

    public NewScreenshotView(Gtk.Stack? stack, Gtk.Popover? popover)
    {
        this.popover = popover;

        title_entry = new Gtk.Entry();
        title_entry.placeholder_text = _("Title (Optional)");
        title_entry.set_max_length(50);
        title_entry.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, "edit-clear-symbolic");
        title_entry.set_icon_tooltip_text(Gtk.EntryIconPosition.SECONDARY, _("Clear"));

        title_entry.icon_press.connect(() => { title_entry.text = ""; });

        Gtk.Button settings_button = new Gtk.Button.from_icon_name("emblem-system-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        settings_button.set_can_focus(false);
        settings_button.set_tooltip_text(_("Settings"));

        settings_button.clicked.connect(() => { stack.set_visible_child_name("settings_view"); });

        Gtk.Box top_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        top_box.margin = 10;
        top_box.pack_start(title_entry, true, true, 0);
        top_box.pack_end(settings_button, false, false, 0);

        ScreenshotModeButton screenshot_screen_button = new ScreenshotModeButton(
            "screen.png", _("Screen"), _("Grab the whole screen"));
        ScreenshotModeButton screenshot_window_button = new ScreenshotModeButton(
            "window.png", _("Window"), _("Grab the current window"));
        ScreenshotModeButton screenshot_area_button = new ScreenshotModeButton(
            "selection.png", _("Selection"), _("Select an area to grab"));

        screenshot_screen_button.clicked.connect(()=> {
            popover.hide();
            cancellable_c = new GLib.Cancellable();
            countdown("screen", screenshot_delay, cancellable_c);
        });

        screenshot_window_button.clicked.connect(()=> {
            popover.hide();
            cancellable_c = new GLib.Cancellable();
            countdown("screen", screenshot_delay, cancellable_c);
        });

        screenshot_area_button.clicked.connect(take_area_screenshot);

        Gtk.Box mode_selection_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        mode_selection_box.add(screenshot_screen_button);
        mode_selection_box.add(new Gtk.Separator(Gtk.Orientation.VERTICAL));
        mode_selection_box.add(screenshot_window_button);
        mode_selection_box.add(new Gtk.Separator(Gtk.Orientation.VERTICAL));
        mode_selection_box.add(screenshot_area_button);

        Gtk.Grid mode_selection = new Gtk.Grid();
        mode_selection.attach(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), 0, 0, 1, 1);
        mode_selection.attach(mode_selection_box, 0, 1, 1, 1);
        mode_selection.attach(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), 0, 2, 1, 1);

        history_button = new Gtk.Button.with_label(_("History"));
        history_button.set_relief(Gtk.ReliefStyle.NONE);
        history_button.set_can_focus(false);
        history_button.set_no_show_all(true);
        history_button.hide();
        history_button.get_child().margin = 5;
        history_button.get_style_context().add_class("bottom-button");

        history_button.clicked.connect(() => { stack.set_visible_child_name("history_view"); });

        attach(top_box, 0, 0, 1, 1);
        attach(mode_selection, 0, 2, 1, 1);
        attach(history_button, 0, 4, 1, 1);
    }

    public void take_screen_screenshot()
    {
        popover.hide();
        set_filepath();

        if (use_main_display) {
            string command_output = "";
            string[] spawn_args = {
                "gnome-screenshot",
                "-f",
                filepath
            };
            command_output = run_command(spawn_args);
        } else {
            take_monitor_screenshot.begin();
        }

        upload();
    }

    private async void take_monitor_screenshot()
    {
        Gdk.Screen screen = Gdk.Screen.get_default();

        Gnome.RRScreen rr_screen;
        Gnome.RRConfig rr_config;

        try {
            rr_screen = new Gnome.RRScreen(screen);
            rr_config = new Gnome.RRConfig.current(rr_screen);
        } catch (GLib.Error e) {
            warning(e.message);
            return;
        }

        ScreenGeometry? geometry = null;

        foreach (unowned Gnome.RROutputInfo output_info in rr_config.get_outputs()) {
            string name = output_info.get_name();
            if (monitor_to_use == name) {
                geometry = ScreenGeometry();
                output_info.get_geometry(out geometry.x, out geometry.y,
                    out geometry.width, out geometry.height);
            }
        }

        if (geometry == null) return;

        Gdk.Window root = screen.get_root_window();
        Gdk.Pixbuf screenshot = Gdk.pixbuf_get_from_window(root,
            geometry.x, geometry.y, geometry.width, geometry.height);

        if (screenshot == null) {
            error_happened(title_entry);
            return;
        }

        try {
            screenshot.save(filepath.split("://")[1], "png");
        } catch (GLib.Error e) {
            warning(e.message);
        }
    }

    public void take_window_screenshot()
    {
        string command_output = "";
        popover.hide();

        set_filepath();

        string[] spawn_args = {
            "gnome-screenshot",
            "-w",
            "-e",
            window_effect,
            "-f",
            filepath
        };

        if (include_border) spawn_args += "-b";
            else spawn_args += "-B";

        command_output = run_command(spawn_args);
        upload();
    }

    private void take_area_screenshot()
    {
        string command_output;
        popover.hide();

        set_filepath();

        string[] spawn_args = {
            "gnome-screenshot",
            "-a",
            "-f",
            filepath
        };

        command_output = run_command(spawn_args);
        upload();
    }

    private void set_filepath()
    {
        if (local_screenshots) {
            GLib.DateTime datetime = new GLib.DateTime.now_local();
            string screenshot_from_string = _("Screenshot from %s").printf(datetime.format("%Y-%m-%d %H-%M-%S"));
            string filename = "%s.png".printf(screenshot_from_string);

            // Use gnome-screenshot's auto-save-directory if set
            GLib.Settings g_settings = new GLib.Settings("org.gnome.gnome-screenshot");
            string auto_save_dir = g_settings.get_string("auto-save-directory");
            if (auto_save_dir != "") {
                GLib.File auto_save_dir_file = GLib.File.new_for_uri(auto_save_dir);
                // Check if the directory exists
                if (auto_save_dir_file.query_exists()) {
                    // Check if we can access the directory (writable)
                    try {
                        GLib.FileInfo info = auto_save_dir_file.query_info(
                            GLib.FileAttribute.ACCESS_CAN_WRITE, GLib.FileQueryInfoFlags.NONE);
                        bool writable = info.get_attribute_boolean(GLib.FileAttribute.ACCESS_CAN_WRITE);
                        if (writable) {
                            filepath = @"$auto_save_dir/$filename";
                            screenshot_file = GLib.File.new_for_uri(filepath);
                            return;
                        }
                    } catch (GLib.Error e) {
                        warning(e.message);
                        return;
                    }
                }
            }

            // Use the default directory if auto-save-directory isn't viable
            filepath = "file://%s/%s/%s".printf(
                GLib.Environment.get_user_special_dir(GLib.UserDirectory.PICTURES), _("Screenshots"), filename);
            screenshot_file = GLib.File.new_for_uri(filepath);

            // Create the directory if it doesn't exist
            if (!screenshot_file.get_parent().query_exists()) {
                try {
                    screenshot_file.get_parent().make_directory();
                } catch (GLib.Error e) {
                    warning(e.message);
                }
            }
        } else {
            try {
                GLib.FileIOStream iostream;
                screenshot_file = GLib.File.new_tmp("screenshot-XXXXXX.png", out iostream);
                filepath = screenshot_file.get_uri();
            } catch (GLib.Error e) {
                warning(e.message);
            }
        }
    }

    public void upload_local(string filep)
    {
        screenshot_file = GLib.File.new_for_uri(filep);
        filepath = filep;

        link = "";

        if (screenshot_file.query_exists()) {
            local_upload_started();

            switch (provider_to_use) {
                case "imgur":
                    link = upload_imgur();
                    break;
                case "ibin":
                    link = upload_ibin();
                    break;
                default:
                    break;
            }
        }

        link = link.strip();

        local_upload_finished(link);
    }

    private void upload()
    {
        if (screenshot_file.query_exists()) {
            try {
                GLib.FileInfo file_info = screenshot_file.query_info("standard::content-type", 0, null);
                if (file_info.get_content_type() == "image/png") {
                    GLib.MainLoop mainloop = new GLib.MainLoop();

                    cancellable = new GLib.Cancellable ();

                    if (!local_screenshots) {
                        upload_started(mainloop, cancellable);
                        switch (provider_to_use) {
                            case "imgur":
                                link = upload_imgur();
                                break;
                            case "ibin":
                                link = upload_ibin();
                                break;
                            default:
                                break;
                        }
                    } else {
                        link = filepath;
                    }

                    link = link.strip();

                    upload_finished(link, local_screenshots, title_entry, cancellable);

                    if (!local_screenshots) {
                        try {
                            screenshot_file.delete();
                        } catch (GLib.Error e) {
                            warning(e.message);
                        }
                    }

                    mainloop.run();
                } else {
                    error_happened(title_entry);
                }
            } catch (GLib.Error e) {
                warning(e.message);
            }
        } else {
            error_happened(title_entry);
        }
    }

    private string upload_imgur()
    {
        string url = "";
        try {
            Rest.Proxy proxy = new Rest.Proxy("https://api.imgur.com/3/", false);
            Rest.ProxyCall call = proxy.new_call();

            StringBuilder encode = null;
            GLib.MainLoop loop1 = new GLib.MainLoop();
            encode_file.begin(screenshot_file, (obj, res) => {
                encode = encode_file.end(res);
                loop1.quit();
            });
            loop1.run();

            call.set_method("POST");
            call.add_header("Authorization", "Client-ID be12a30d5172bb7");
            call.set_function("upload.json");
            call.add_params(
                    "api_key", "f410b546502f28376747262f9773ee368abb31f0",
                    "image", encode.str
            );

            GLib.MainLoop loop2 = new GLib.MainLoop();
            call.run_async((call, error, obj) => {
                cancellable.cancelled.connect (() => { loop2.quit(); });
                string payload = call.get_payload();
                if (payload != null) {
                    int64 len = call.get_payload_length();
                    Json.Parser parser = new Json.Parser();
                    try {
                        parser.load_from_data(payload, (ssize_t) len);
                    } catch (GLib.Error e) {
                        stderr.printf(e.message);
                    }
                    unowned Json.Object node_obj = parser.get_root().get_object();
                    if (node_obj != null) {
                        node_obj = node_obj.get_object_member("data");
                        if (node_obj != null) {
                            url = node_obj.get_string_member("link") ?? "";
                            if (url == "") {
                                stdout.printf("ERROR: %s\n", node_obj.get_string_member("error"));
                            }
                        }
                    }
                }
                loop2.quit();
            }, null);
            loop2.run();
        } catch (GLib.Error e) {
            warning(e.message);
        }

        return url;
    }

    private async StringBuilder encode_file(GLib.File f)
    {
        GLib.StringBuilder encoded = new GLib.StringBuilder();
        try {
            var input = yield f.read_async(GLib.Priority.DEFAULT, null);

            int chunk_size = 128*1024;
            uint8[] buffer = new uint8[chunk_size];
            char[] encode_buffer = new char[(chunk_size / 3 + 1) * 4 + 4];
            size_t read_bytes;
            int state = 0;
            int save = 0;

            read_bytes = yield input.read_async(buffer);
            while (read_bytes != 0) {
                buffer.length = (int) read_bytes;
                size_t enc_len = Base64.encode_step((uchar[]) buffer, false, encode_buffer,
                                                   ref state, ref save);
                encoded.append_len((string) encode_buffer, (ssize_t) enc_len);

                read_bytes = yield input.read_async(buffer);
            }
            size_t enc_close = Base64.encode_close(false, encode_buffer, ref state, ref save);
            encoded.append_len((string) encode_buffer, (ssize_t) enc_close);

        } catch (GLib.Error e) {
            stderr.printf(e.message);
        }

        return encoded;
    }

    private string upload_ibin()
    {
        string command_output;
        string[] spawn_args = {
                "curl",
                "-sS",
                "-F key=uRj7fbCFkTPiFYOJK5ETYzVdjkgTrqBP",
                "-F file=@%s".printf(filepath.split("://")[1]),
                "https://imagebin.ca/upload.php",
        };

        command_output = run_command(spawn_args);
        string url = "";
        for (int i = 24; i < command_output.length; i++) {
            url += ((char) command_output[i]).to_string();
        }

        return url;
    }

    private string run_command(string[] spawn_args)
    {
        try {
            GLib.MainLoop loop = new GLib.MainLoop();
            string[] spawn_env = GLib.Environ.get();
            int standard_output;
            GLib.Pid child_pid;

            cancellable.cancelled.connect(() => { loop.quit(); });

            GLib.Process.spawn_async_with_pipes("/",
                spawn_args,
                spawn_env,
                GLib.SpawnFlags.SEARCH_PATH | GLib.SpawnFlags.DO_NOT_REAP_CHILD,
                null,
                out child_pid,
                null,
                out standard_output,
                null);

            GLib.IOChannel output = new IOChannel.unix_new(standard_output);
            string line = "";
            output.add_watch(GLib.IOCondition.IN | GLib.IOCondition.HUP, (channel, condition) => {
                try {
                    channel.read_to_end(out line, null);
                } catch (GLib.Error e) {
                    stderr.printf(e.message);
                }
                return false;
            });

            GLib.ChildWatch.add(child_pid, (pid, status) => {
                GLib.Process.close_pid(pid);
                loop.quit();
            });

            loop.run();
            return line;
        } catch (GLib.SpawnError e) {
            stderr.printf("Error: %s\n", e.message);
        }

        return "";
    }

    public static unowned NewScreenshotView instance(Gtk.Stack? stack, Gtk.Popover? popover) {
        return _instance.once(() => { return new NewScreenshotView(stack, popover); });
    }
}