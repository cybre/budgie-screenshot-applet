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


namespace ScreenshotApplet.ProviderSettings
{

[GtkTemplate (ui = "/com/github/cybre/budgie-screenshot-applet/ui/providers/ftp_settings.ui")]
public class FTPSettings : Gtk.Grid
{
    [GtkChild]
    private Gtk.Entry? ftp_uri_entry;

    [GtkChild]
    private Gtk.ComboBoxText? connection_mode_combo;

    [GtkChild]
    private Gtk.Entry? username_entry;

    [GtkChild]
    private Gtk.Entry? password_entry;

    [GtkChild]
    private Gtk.Entry? website_url_entry;

    public FTPSettings(GLib.Settings settings)
    {
        settings.bind("ftp-uri", ftp_uri_entry, "text", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("connection-mode", connection_mode_combo, "active_id", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("username", username_entry, "text", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("username", username_entry, "text", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("password", password_entry, "text", GLib.SettingsBindFlags.DEFAULT);
        settings.bind("website-url", website_url_entry, "text", GLib.SettingsBindFlags.DEFAULT);
    }
}

}

namespace ScreenshotApplet.Backend.Providers
{

private class FTP : IProvider
{
    private GLib.Settings settings;
    public GLib.Cancellable cancellable;
    public static FTP? _instance = null;
    public int64 file_size = 0;

    public FTP()
    {
        _instance = this;

        string id_prefix = BackendUtil.settings_manager.get_settings().schema_id;
        string schema_id = @"$id_prefix.provider.ftp";
        string path_prefix = BackendUtil.settings_manager.get_settings().path;
        string schema_path = @"$(path_prefix)provider/ftp/";
        settings = new Settings.with_path(schema_id, schema_path);
    }

    public override async bool upload_image(string uri, out string? link)
    {
        link = null;
        bool status = false;

        try {
            uint8[] data;

            try {
                GLib.FileUtils.get_data(uri.split("://")[1], out data);
                file_size = (int64)data.length;
            } catch (GLib.FileError e) {
                warning(e.message);
                return false;
            }
            GLib.File file = GLib.File.new_for_uri(uri);
            Posix.FILE? posix_file = Posix.FILE.open(file.get_path(), "r");

            string basename = file.get_basename();

            string ftp_uri = settings.get_string("ftp-uri");
            string connection_mode = settings.get_string("connection-mode");
            string username = settings.get_string("username");
            string password = settings.get_string("password");
            string website_url = settings.get_string("website-url");

            string curl_url = "";
            if (ftp_uri.has_suffix("/")) {
                curl_url = @"$ftp_uri$basename";
            } else {
                curl_url = @"$ftp_uri/$basename";
            }

            string image_link = "";
            if (website_url.has_suffix("/")) {
                image_link = @"$website_url$basename";
            } else {
                image_link = @"$website_url/$basename";
            }

            cancellable = new GLib.Cancellable();

            Curl.Easy handle = new Curl.Easy();
            handle.setopt(Curl.Option.URL, curl_url);
            handle.setopt(Curl.Option.UPLOAD, 1);
            handle.setopt(Curl.Option.INFILE, (void*)posix_file);
            handle.setopt(Curl.Option.USERNAME, username);
            handle.setopt(Curl.Option.PASSWORD, password);
            handle.setopt(Curl.Option.FOLLOWLOCATION, true);
            handle.setopt(Curl.Option.VERBOSE, 1);
            Curl.ProgressCallback d = (user_data, dltotal, dlnow, ultotal, ulnow) => {
                if (_instance.cancellable.is_cancelled()) {
                    return 1;
                }
                int64 total = _instance.file_size.abs();
                int64 now = ((int64)ulnow).abs();
                stdout.printf("total: %s\nnow: %s\n", _instance.file_size.to_string(), now.to_string());
                _instance.progress_updated(total, now);
                return 0;
            };
            handle.setopt(Curl.Option.XFERINFOFUNCTION, d);
            handle.setopt(Curl.Option.NOPROGRESS, 0);

            if (connection_mode == "active") {
                handle.setopt(Curl.Option.FTPPORT, "-");
                handle.setopt(Curl.Option.FTP_CREATE_MISSING_DIRS, 1);
            }

            Curl.Code? res = null;
            SourceFunc callback = upload_image.callback;

            GLib.Thread<void*> thread = new GLib.Thread<void*>.try(null, () => {
                res = handle.perform();
                Idle.add((owned)callback);
                return null;
            });

            yield;

            if (res == Curl.Code.OK) {
                stdout.printf("\nYES\n");
                link = image_link;
                status = true;
            }
        } catch (GLib.Error e) {
            warning(e.message);
        }

        return status;
    }

    public int progress_function(void* user_data, uint64 dltotal, uint64 dlnow, uint64 ultotal, uint64 ulnow)
    {
        stdout.printf("progress_function\n");
        if (cancellable.is_cancelled()) {
            return 1;
        }

        return 0;
    }


    public override string get_name() {
        return "S/FTP";
    }

    public override async void cancel_upload() {
        cancellable.cancel();
    }

    public override bool supports_settings() {
        return true;
    }

    public override Gtk.Widget? get_settings_widget() {
        return new ProviderSettings.FTPSettings(settings);
    }

    public override GLib.Settings? get_settings() {
        return settings;
    }
}

}