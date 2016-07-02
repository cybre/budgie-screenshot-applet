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

namespace ScreenshotApplet
{
    private class ScreenshotModeButton : Gtk.ToolButton
    {
        private Gtk.Image mode_image;
        private Gtk.Label mode_label;
        private Gtk.Box button_box;

        public ScreenshotModeButton(string image, string label)
        {
            mode_image = new Gtk.Image.from_resource("/com/github/cybre/screenshot-applet/images/%s".printf(image));
            mode_image.pixel_size = 64;

            mode_label = new Gtk.Label(label);
            mode_label.halign = Gtk.Align.CENTER;

            button_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
            button_box.set_size_request(80, 100);
            button_box.add(mode_image);
            button_box.add(mode_label);

            label_widget = button_box;

            get_child().can_focus = false;
        }
    }

    public class NewScreenshotView : Gtk.Grid
    {
        public Gtk.Entry title_entry;
        private ScreenshotModeButton screenshot_screen_button;
        private ScreenshotModeButton screenshot_window_button;
        private ScreenshotModeButton screenshot_area_button;
        private Gtk.Grid mode_selection;
        private Gtk.Box mode_selection_box;
        private Gtk.Button history_button;
        private Gtk.Popover popover;
        private string link;
        private string filepath;
        private GLib.Cancellable cancellable;
        private GLib.File screenshot_file;
        public string provider_to_use { set; get; default = "imgur"; }
        public string window_effect { set; get; default = "none"; }
        public int screenshot_delay { set; get; default = 1; }
        public bool include_border { set; get; default = true; }
        public bool local_screenshots { set; get; default = false; }
        public Gdk.Window old_window;

        public signal void upload_started(GLib.MainLoop mainloop, GLib.Cancellable cancellable);
        public signal void upload_finished(string link, bool local_screenshots, Gtk.Entry title_entry, GLib.Cancellable cancellable);
        public signal void error_happened(Gtk.Entry title_entry);

        public signal void local_upload_started();
        public signal void local_upload_finished(string link);

        public NewScreenshotView(Gtk.Stack? stack, Gtk.Popover? popover)
        {
            this.popover = popover;

            title_entry = new Gtk.Entry();
            title_entry.placeholder_text = "Title (Optional)";
            title_entry.margin = 5;
            title_entry.max_length = 50;
            title_entry.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, "edit-clear-symbolic");
            title_entry.set_icon_tooltip_text(Gtk.EntryIconPosition.SECONDARY, "Clear");

            title_entry.icon_press.connect(() => {
                title_entry.text = "";
            });

            screenshot_screen_button = new ScreenshotModeButton("screen.png", "Screen");
            screenshot_screen_button.tooltip_text = "Grab the whole screen";
            screenshot_window_button = new ScreenshotModeButton("window.png", "Window");
            screenshot_window_button.tooltip_text = "Grab the current window";
            screenshot_area_button = new ScreenshotModeButton("selection.png", "Selection");
            screenshot_area_button.tooltip_text = "Select area to grab";

            screenshot_screen_button.clicked.connect(take_screen_screenshot);
            screenshot_window_button.clicked.connect(take_window_screenshot);
            screenshot_area_button.clicked.connect(take_area_screenshot);

            mode_selection = new Gtk.Grid();
            mode_selection.attach(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), 0, 0, 1, 1);
            mode_selection_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            mode_selection_box.add(screenshot_screen_button);
            mode_selection_box.add(new Gtk.Separator(Gtk.Orientation.VERTICAL));
            mode_selection_box.add(screenshot_window_button);
            mode_selection_box.add(new Gtk.Separator(Gtk.Orientation.VERTICAL));
            mode_selection_box.add(screenshot_area_button);
            mode_selection.attach(mode_selection_box, 0, 1, 1, 1);
            mode_selection.attach(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), 0, 2, 1, 1);

            history_button = new Gtk.Button.with_label("History");
            history_button.relief = Gtk.ReliefStyle.NONE;
            history_button.can_focus = false;

            history_button.clicked.connect(() => {
                stack.set_visible_child_full("history_view", Gtk.StackTransitionType.SLIDE_LEFT);
            });

            attach(title_entry, 0, 0, 1, 1);
            attach(mode_selection, 0, 2, 1, 1);
            attach(history_button, 0, 4, 1, 1);
        }

        private void take_screen_screenshot()
        {
            string command_output;
            popover.visible = false;

            set_filepath();

            string[] spawn_args = {
                "gnome-screenshot",
                "-d",
                screenshot_delay.to_string(),
                "-f",
                filepath
            };

            command_output = run_command(spawn_args);
            upload();
        }

        private void take_window_screenshot()
        {
            string command_output;
            popover.visible = false;

            if (old_window != null) {
                old_window.focus(0);
            }

            set_filepath();

            string[] spawn_args = {
                "gnome-screenshot",
                "-w",
                "-d",
                screenshot_delay.to_string(),
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
            popover.visible = false;

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
                string filename = "Screenshot from %s.png".printf(datetime.format("%Y-%m-%d %H-%M-%S"));
                filepath = "%s/%s".printf("file://%s/Screenshots".printf(GLib.Environment.get_user_special_dir(GLib.UserDirectory.PICTURES)), filename);
                screenshot_file = GLib.File.new_for_uri(filepath);
                if (!screenshot_file.get_parent().query_exists()) {
                    try {
                        screenshot_file.get_parent().make_directory();
                    } catch (GLib.Error e) {
                        stderr.printf(e.message, "\n");
                    }
                }
            } else {
                try {
                    GLib.FileIOStream iostream;
                    screenshot_file = GLib.File.new_tmp("screenshot-XXXXXX.png", out iostream);
                    filepath = screenshot_file.get_uri();
                } catch (GLib.Error e) {
                    stderr.printf(e.message, "\n");
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

                        upload_started(mainloop, cancellable);

                        if (!local_screenshots) {
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
                                stderr.printf(e.message, "\n");
                            }
                        }

                        mainloop.run();
                    } else {
                        error_happened(title_entry);
                    }
                } catch (GLib.Error e) {
                    stderr.printf(e.message, "\n");
                }
            } else {
                error_happened(title_entry);
            }
        }

        private string upload_imgur()
        {
            string url = "";
            try {
                GLib.MainLoop loop = new GLib.MainLoop();
                Rest.Proxy proxy = new Rest.Proxy("https://api.imgur.com/3/", false);
                Rest.ProxyCall call = proxy.new_call();

                StringBuilder encode = null;
                encode_file.begin(screenshot_file, (obj, res) => {
                    try {
                        encode = encode_file.end(res);
                    } catch (GLib.ThreadError e) {
                        stderr.printf(e.message);
                    }
                    loop.quit();
                });
                loop.run();

                call.set_method("POST");
                call.add_header("Authorization", "Client-ID be12a30d5172bb7");
                call.set_function("upload.json");
                call.add_params(
                        "api_key", "f410b546502f28376747262f9773ee368abb31f0",
                        "image", encode.str
                );

                cancellable.cancelled.connect (() => {
                    loop.quit();
                });

                call.run_async((call, error, obj) => {
                    string payload = call.get_payload();
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
                            url = node_obj.get_string_member("link");
                        }
                    }
                    loop.quit();
                }, null);
                loop.run();
            } catch (GLib.Error e) {
                stderr.printf(e.message, "\n");
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
                string[] spawn_env = Environ.get();
                int standard_output;
                Pid child_pid;

                cancellable.cancelled.connect (() => {
                    loop.quit();
                });

                GLib.Process.spawn_async_with_pipes("/",
                    spawn_args,
                    spawn_env,
                    SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                    null,
                    out child_pid,
                    null,
                    out standard_output,
                    null);

                IOChannel output = new IOChannel.unix_new(standard_output);
                string line = "";
                output.add_watch(IOCondition.IN | IOCondition.HUP, (channel, condition) => {
                    try {
                        channel.read_to_end(out line, null);
                    } catch (GLib.Error e) {
                        stderr.printf(e.message);
                    }
                    return false;
                });

                ChildWatch.add(child_pid, (pid, status) => {
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
    }
}