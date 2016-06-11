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

public class Screenshot : GLib.Object, Budgie.Plugin {
    public Budgie.Applet get_panel_widget(string uuid)
    {
        return new ScreenshotApplet.ScreenshotApplet(uuid);
    }
}

[GtkTemplate (ui = "/com/github/cybre/screenshot-applet/settings.ui")]
public class ScreenshotAppletSettings : Gtk.Grid
{
    [GtkChild]
    private Gtk.Switch? switch_label;

    [GtkChild]
    private Gtk.ComboBox? combobox_provider;

    [GtkChild]
    private Gtk.Switch? switch_history;

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
        settings.bind("provider", combobox_provider, "active_id", SettingsBindFlags.DEFAULT);
        settings.bind("enable-history", switch_history, "active", SettingsBindFlags.DEFAULT);
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
        private Gtk.Button history_button;
        private Gdk.Display display;
        private GLib.Cancellable cancellable;
        private string link;
        private string provider_to_use { set; get; default = "imgur"; }
        private string window_effect { set; get; default = "none"; }
        private int screenshot_delay { set; get; default = 2; }
        private bool remember_history { set; get; default = true; }
        private bool include_border { set; get; default = true; }
        private bool error;
        private UploadingView uploading_view;
        private UploadDoneView upload_done_view;
        private ErrorView error_view;
        private HistoryView history_view;
        public string uuid { public set ; public get; }

        private string css = """
.no-underline {
    text-decoration-line: none;
}
""";

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

            settings = this.get_applet_settings(uuid);

            settings.changed.connect(on_settings_changed);

            display = this.get_display();
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

            unowned Gtk.StyleContext context = this.get_style_context();
            var provider = new Gtk.CssProvider();
            try {
                provider.load_from_data(this.css, this.css.length);
                var screen = this.get_screen();
                context.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (GLib.Error e) {
                stderr.printf("Error loading CSS: %s\n", e.message);
            }

            GLib.SimpleActionGroup group = new GLib.SimpleActionGroup();
            GLib.SimpleAction screen = new GLib.SimpleAction("screen", null);
            screen.activate.connect(take_screen_screenshot);
            group.add_action(screen);

            GLib.SimpleAction window = new GLib.SimpleAction("window", null);
            window.activate.connect(take_window_screenshot);
            group.add_action(window);
            
            GLib.SimpleAction area = new GLib.SimpleAction("area", null);
            area.activate.connect(take_area_screenshot);
            group.add_action(area);

            GLib.SimpleAction history = new GLib.SimpleAction("history", null);
            history.activate.connect(show_history);
            group.add_action(history);

            this.insert_action_group("screenshot", group);

            Gtk.Button screen_button = new Gtk.Button.with_label("Grab the whole screen");
            ((Gtk.Label) screen_button.get_child()).halign = Gtk.Align.START;
            screen_button.get_style_context().add_class("flat");
            screen_button.action_name = "screenshot.screen";

            Gtk.Button window_button = new Gtk.Button.with_label("Grab the current window");
            ((Gtk.Label) window_button.get_child()).halign = Gtk.Align.START;
            window_button.get_style_context().add_class("flat");
            window_button.action_name = "screenshot.window";

            Gtk.Button area_button = new Gtk.Button.with_label("Select area to grab");
            ((Gtk.Label) area_button.get_child()).halign = Gtk.Align.START;
            area_button.get_style_context().add_class("flat");
            area_button.action_name = "screenshot.area";

            history_button = new Gtk.Button.with_label("History");
            history_button.visible = this.settings.get_boolean("enable-history");
            ((Gtk.Label) history_button.get_child()).halign = Gtk.Align.START;
            history_button.get_style_context().add_class("flat");
            history_button.action_name = "screenshot.history";

            Gtk.Box start_view = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            start_view.width_request = 200;
            start_view.height_request = 150;
            start_view.pack_start(screen_button, true, true, 0);
            start_view.pack_start(window_button, true, true, 0);
            start_view.pack_start(area_button, true, true, 0);
            start_view.pack_start(history_button, true, true, 0);

            uploading_view = new UploadingView();
            upload_done_view = new UploadDoneView();
            error_view = new ErrorView();
            history_view = new HistoryView(this.settings, this.clipboard);

            stack = new Gtk.Stack();
            stack.add_named(start_view, "start_view");
            stack.add_named(uploading_view, "uploading_view");
            stack.add_named(upload_done_view, "upload_done_view");
            stack.add_named(history_view, "history_view");
            stack.add_named(error_view, "error_view");
            stack.homogeneous = false;
            stack.show_all();

            popover = new Gtk.Popover(box);
            popover.add(stack);

            this.cancellable = new GLib.Cancellable();

            uploading_view.uploading_cancel_button.clicked.connect(() => {
                cancellable.cancel();
            });

            upload_done_view.done_back_button.clicked.connect(() => {
                stack.set_transition_type(Gtk.StackTransitionType.SLIDE_RIGHT);
                stack.set_visible_child_name("start_view");
            });

           upload_done_view.done_open_button.clicked.connect(() => {
                try {
                    GLib.Process.spawn_command_line_async("xdg-open %s".printf(this.link));
                    popover.hide();
                } catch (GLib.SpawnError e) {
                    stderr.printf(e.message);
                }
            });

            error_view.error_back_button.clicked.connect(() => {
                stack.set_transition_type(Gtk.StackTransitionType.SLIDE_RIGHT);
                stack.set_visible_child_name("start_view");
            });

            history_view.history_back_button.clicked.connect(() => {
                stack.set_transition_type(Gtk.StackTransitionType.SLIDE_RIGHT);
                stack.set_visible_child_name("start_view");
            });

            box.button_press_event.connect((e) => {
                if (e.button != 1) {
                    return Gdk.EVENT_PROPAGATE;
                }
                if (popover.get_visible()) {
                    popover.hide();
                } else {
                    stack.set_transition_type(Gtk.StackTransitionType.NONE);
                    this.manager.show_popover(box);
                    if (spinner.active) {
                        stack.set_visible_child_name("uploading_view");
                    } else if (icon.get_style_context().has_class("alert") && !this.error) {
                        stack.set_visible_child_name("upload_done_view");
                        icon.get_style_context().remove_class("alert");
                    } else if (this.error) {
                        stack.set_visible_child_name("error_view");
                        icon.get_style_context().remove_class("alert");
                        this.error = false;
                    } else {
                        stack.set_visible_child_name("start_view");
                    }
                    stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT);
                }
                return Gdk.EVENT_STOP;
            });

            string[] history_list = this.settings.get_strv("history");
            foreach (string history_entry in history_list) {
                history_view.update_history(history_entry);
            }

            add(box);
            show_all();

            spinner.visible = false;

            on_settings_changed("enable-label");
            on_settings_changed("provider");
            on_settings_changed("enable-history");
            on_settings_changed("delay");
            on_settings_changed("include-border");
            on_settings_changed("window-effect");
        }

        void take_screen_screenshot()
        {
            string command_output;
            popover.hide();

            string[] spawn_args = {
                "gnome-screenshot",
                "-d",
                this.screenshot_delay.to_string(),
                "-f",
                "/tmp/screenshot.png"
            };

            command_output = run_command(spawn_args);
            upload();
        }

        void take_window_screenshot()
        {
            string command_output;
            popover.hide();

            string[] spawn_args = {
                "gnome-screenshot",
                "-w",
                "-d",
                this.screenshot_delay.to_string(),
                "-e",
                this.window_effect,
                "-f",
                "/tmp/screenshot.png"
            };

            if (this.include_border) spawn_args += "-b";
                else spawn_args += "-B";

            command_output = run_command(spawn_args);
            upload(); 
        }

        void take_area_screenshot()
        {
            string command_output;
            popover.hide();
            string[] spawn_args = {
                "gnome-screenshot",
                "-a",
                "-f",
                "/tmp/screenshot.png"
            };
            command_output = run_command(spawn_args);
            upload(); 
        }

        void show_history()
        {
            stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT);
            stack.set_visible_child_name("history_view");
        }

        private void upload()
        {
            GLib.MainLoop mainloop = new GLib.MainLoop();

            this.cancellable = new GLib.Cancellable ();
            this.cancellable.cancelled.connect(() => {
                mainloop.quit();
                spinner.stop();
                spinner.visible = false;
                icon.visible = true;
                stack.set_visible_child_name("start_view");
            });

            stack.set_visible_child_name("uploading_view");
            icon.visible = false;
            spinner.start();
            spinner.visible = true;

            switch (provider_to_use) {
                case "imgur":
                    this.link = upload_imgur();
                    break;
                case "ibin":
                    this.link = upload_ibin();
                    break;
                default:
                    break;
            }

            this.link = this.link.strip();

            spinner.stop();
            spinner.visible = false;
            icon.visible = true;

            if (popover.visible == false && !this.cancellable.is_cancelled()) {
                icon.get_style_context().add_class("alert");
            }

            if (this.link != "") {
                if (this.remember_history) {
                    history_view.add_to_history(this.link);
                }
                this.clipboard.set_text(this.link, -1);
                if (popover.visible && !this.cancellable.is_cancelled()) {
                    stack.set_visible_child_name("upload_done_view");
                }
                this.error = false;
            } else if (!this.cancellable.is_cancelled()) {
                if (popover.visible) {
                    stack.set_visible_child_name("error_view");
                }
                this.error = true;
            }
            
            mainloop.run();
        }

        private string upload_imgur()
        {
            string url = "";
            try {
                GLib.MainLoop loop = new GLib.MainLoop();
                Rest.Proxy proxy = new Rest.Proxy("https://api.imgur.com/3/", false);
                Rest.ProxyCall call = proxy.new_call();

                string uri = "file:///tmp/screenshot.png";
                GLib.File f = GLib.File.new_for_uri(uri);

                StringBuilder encode = null;
                encode_file.begin(f, (obj, res) => {
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

                this.cancellable.cancelled.connect (() => {
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
                    "-F file=@/tmp/screenshot.png",
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

                this.cancellable.cancelled.connect (() => {
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

        protected void on_settings_changed(string key)
        {
            switch (key)
            {
                case "enable-label":
                    label.visible = settings.get_boolean(key);
                    break;
                case "provider":
                    this.provider_to_use = settings.get_string(key);
                    break;
                case "enable-history":
                    this.remember_history = settings.get_boolean(key);
                    this.history_button.visible = settings.get_boolean(key);
                    if (!settings.get_boolean(key)) {
                        history_view.clear_all();
                    }
                    break;
                case "delay":
                    this.screenshot_delay = settings.get_int(key);
                    break;
                case "include-border":
                    this.include_border = settings.get_boolean(key);
                    break;
                case "window-effect":
                    this.window_effect = settings.get_string(key);
                    break;
                default:
                    break;
            }
        }

        public override void update_popovers(Budgie.PopoverManager? manager)
        {
            manager.register_popover(this.box, this.popover);
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