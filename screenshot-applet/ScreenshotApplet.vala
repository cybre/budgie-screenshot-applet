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
        return new ScreenshotApplet(uuid);
    }
}

[GtkTemplate (ui = "/com/github/cybre/screenshot-applet/settings.ui")]
public class ScreenshotAppletSettings : Gtk.Grid
{
    [GtkChild]
    private Gtk.Switch? switch_label;

    [GtkChild]
    private Gtk.SpinButton spinbutton_delay;

    [GtkChild]
    private Gtk.ComboBox? combobox_provider;

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

        this.settings = settings;
        settings.bind("enable-label", switch_label, "active", SettingsBindFlags.DEFAULT);
        settings.bind("delay", spinbutton_delay, "value", SettingsBindFlags.DEFAULT);
        settings.bind("provider", combobox_provider, "active_id", SettingsBindFlags.DEFAULT);
    }

}

public class ScreenshotApplet : Budgie.Applet
{
    Gtk.Popover? popover = null;
    Gtk.EventBox? box = null;
    unowned Budgie.PopoverManager? manager = null;
    protected Settings settings;
    Gtk.Image img;
    Gtk.Label label;
    Gtk.Spinner spinner;
    string provider_to_use;
    string command_output;
    private string link;
    Gtk.Stack stack;
    public int screenshot_delay { public set; public get; default = 2; }
    public string uuid { public set ; public get; }
    GLib.Cancellable cancellable;
    Gtk.Widget start_page;

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

        box = new Gtk.EventBox();
        spinner = new Gtk.Spinner();
        img = new Gtk.Image.from_icon_name("image-x-generic-symbolic", Gtk.IconSize.MENU);
        var layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        layout.pack_start(spinner, false, false, 3);
        layout.pack_start(img, false, false, 3);
        label = new Gtk.Label("Screenshot");
        label.halign = Gtk.Align.START;
        layout.pack_start(label, true, true, 3);
        box.add(layout);

        var menu = new GLib.Menu();
        menu.append("Grab the whole screen", "screenshot.screen");
        menu.append("Grab the current window", "screenshot.window");
        menu.append("Select area to grab", "screenshot.area");
        popover = new Gtk.Popover.from_model(box, menu);

        stack = (Gtk.Stack) popover.get_child();

        var uploading_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        uploading_box.margin = 20;
        var uploading_image = new Gtk.Image.from_icon_name("software-update-available-symbolic", Gtk.IconSize.DIALOG);
        var uploading_label = new Gtk.Label("<big>Uploading...</big>");
        uploading_label.set_use_markup(true);
        uploading_label.margin_top = 10;
        var uploading_cancel_button = new Gtk.Button.with_label("Cancel");
        uploading_cancel_button.margin_top = 20;
        uploading_box.pack_start(uploading_image, true, true, 0);
        uploading_box.pack_start(uploading_label, true, true, 0);
        uploading_box.pack_start(uploading_cancel_button, true, true, 0);
        stack.add_named(uploading_box, "uploading_box");

        var done_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        done_box.margin = 20;
        var done_image = new Gtk.Image.from_icon_name("emblem-ok-symbolic", Gtk.IconSize.DIALOG);
        var done_label = new Gtk.Label("<big>The link has been copied \nto your clipboard!</big>");
        done_label.set_justify(Gtk.Justification.CENTER);
        done_label.set_use_markup(true);
        var done_button = new Gtk.Button.with_label("Back");
        var done_open_button = new Gtk.Button.with_label("Open");
        var button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        button_box.get_style_context().add_class("linked");
        button_box.pack_start(done_button, true, true, 0);
        button_box.pack_start(done_open_button, true, true, 0);
        button_box.margin_top = 20;
        done_box.pack_start(done_image, true, true, 0);
        done_box.pack_start(done_label, true, true, 0);
        done_box.pack_start(button_box, true, true, 0);
        stack.add_named(done_box, "done_box");

        this.start_page = stack.get_visible_child();

        this.cancellable = new GLib.Cancellable();

        uploading_cancel_button.clicked.connect(() => {
            this.cancellable.cancel();
        });

        done_button.clicked.connect(() => {
            stack.set_visible_child(this.start_page);
        });

        done_open_button.clicked.connect(() => {
            Process.spawn_command_line_async("xdg-open %s".printf(this.link));
        });

        stack.show_all();

        box.button_press_event.connect((e) => {
            if (e.button != 1) {
                return Gdk.EVENT_PROPAGATE;
            }
            if (popover.get_visible()) {
                popover.hide();
            } else {
                this.manager.show_popover(box);
                if (img.get_style_context().has_class("alert")) {
                    stack.set_transition_type(Gtk.StackTransitionType.NONE);
                    stack.set_visible_child_name("done_box");
                    img.get_style_context().remove_class("alert");
                }
                if (spinner.active) {
                    stack.set_transition_type(Gtk.StackTransitionType.NONE);
                    stack.set_visible_child_name("uploading_box");
                }
                stack.set_transition_type(Gtk.StackTransitionType.SLIDE_RIGHT);
            }
            return Gdk.EVENT_STOP;
        });

        var group = new GLib.SimpleActionGroup();
        var screen = new GLib.SimpleAction("screen", null);
        screen.activate.connect(take_screen_screenshot);
        group.add_action(screen);

        var window = new GLib.SimpleAction("window", null);
        window.activate.connect(take_window_screenshot);
        group.add_action(window);
        
        var area = new GLib.SimpleAction("area", null);
        area.activate.connect(take_area_screenshot);
        group.add_action(area);

        this.insert_action_group("screenshot", group);

        add(box);
        show_all();

        spinner.visible = false;

        on_settings_changed("provider");
        on_settings_changed("delay");
        on_settings_changed("enable-label");
    }

    void take_screen_screenshot()
    {
        string[] spawn_args = {
            "gnome-screenshot",
            "-d",
            screenshot_delay.to_string(),
            "-f",
            "/tmp/screenshot.png"
        };
        command_output = run_command(spawn_args);
        upload(); 
    }

    void take_window_screenshot()
    {
        string[] spawn_args = {
            "gnome-screenshot",
            "-w",
            "-d",
            screenshot_delay.to_string(),
            "-f",
            "/tmp/screenshot.png"
        };
        command_output = run_command(spawn_args);
        upload(); 
    }

    void take_area_screenshot()
    {
        string[] spawn_args = {
            "gnome-screenshot",
            "-a",
            "-f",
            "/tmp/screenshot.png"
        };
        command_output = run_command(spawn_args);
        upload(); 
    }

    private void upload()
    {
        MainLoop mainloop = new MainLoop();

        this.cancellable = new Cancellable ();
        this.cancellable.cancelled.connect (() => {
            mainloop.quit();
            spinner.stop();
            spinner.visible = false;
            img.visible = true;
            stack.set_visible_child(this.start_page);
        });

        stack.set_visible_child_name("uploading_box");
        img.visible = false;
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

        spinner.stop();
        spinner.visible = false;
        img.visible = true;

        if (popover.visible) {
            stack.set_visible_child_name("done_box");
        } else {
            img.get_style_context().add_class("alert");
        }

        var display = this.get_display();
        var clipboard = Gtk.Clipboard.get_for_display(display, Gdk.SELECTION_CLIPBOARD);

        if (this.link != "") {
            clipboard.set_text(this.link, -1);
        }
        
        mainloop.run();
    }

    private string upload_imgur()
    {
        var url = "";
        try {
            MainLoop loop = new MainLoop();
            Rest.Proxy proxy = new Rest.Proxy("https://api.imgur.com/3/", false);
            Rest.ProxyCall call = proxy.new_call();

            var uri = "file:///tmp/screenshot.png";
            var f = File.new_for_uri(uri);

            StringBuilder encode = null;
            encode_file.begin(f, (obj, res) => {
                try {
                    encode = encode_file.end(res);
                } catch (ThreadError e) {
                    string msg = e.message;
                    stderr.printf(msg);
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
                var parser = new Json.Parser();
                parser.load_from_data(payload, (ssize_t) len);
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
        } catch (Error e) {
            stderr.printf(e.message, "\n");
        }

        return url;
    }

    private async StringBuilder encode_file(GLib.File f) {
        var input = yield f.read_async(Priority.DEFAULT, null);

        int chunk_size = 128*1024;
        uint8[] buffer = new uint8[chunk_size];
        char[] encode_buffer = new char[(chunk_size / 3 + 1) * 4 + 4];
        size_t read_bytes;
        int state = 0;
        int save = 0;
        var encoded = new StringBuilder();

        read_bytes = yield input.read_async(buffer);
        while (read_bytes != 0)
        {
          buffer.length = (int) read_bytes;
          size_t enc_len = Base64.encode_step((uchar[]) buffer, false, encode_buffer,
                                               ref state, ref save);
          encoded.append_len((string) encode_buffer, (ssize_t) enc_len);
          read_bytes = yield input.read_async(buffer);
        }
        size_t enc_close = Base64.encode_close(false, encode_buffer, ref state, ref save);
        encoded.append_len((string) encode_buffer, (ssize_t) enc_close);

        return encoded;
    }

    private string upload_ibin()
    {
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
            MainLoop loop = new MainLoop();
            string[] spawn_env = Environ.get();
            int standard_output;
            Pid child_pid;

            this.cancellable.cancelled.connect (() => {
                loop.quit();
            });

            Process.spawn_async_with_pipes("/",
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
                channel.read_to_end(out line, null);
                return false;
            });

            ChildWatch.add(child_pid, (pid, status) => {
                Process.close_pid(pid);
                loop.quit();
            });

            loop.run();
            return line;
        } catch (SpawnError e) {
            stderr.printf("Error: %s\n", e.message);
        }

        return "";
    }

    protected void on_settings_changed(string key)
    {
        switch (key)
        {
            case "provider":
                provider_to_use = settings.get_string(key);
                break;
            case "delay":
                this.screenshot_delay = settings.get_int(key);
                break;
            case "enable-label":
                label.set_visible(settings.get_boolean(key));
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

[ModuleInit]
public void peas_register_types(TypeModule module)
{
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(Screenshot));
}