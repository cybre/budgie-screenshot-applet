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

namespace ScreenshotApplet.Backend.Providers
{

private class Imgur : IProvider, GLib.Object
{
    private Soup.SessionAsync session;

    public Imgur()
    {
        session = new Soup.SessionAsync();
        session.ssl_strict = false;
        // Add a logger:
        Soup.Logger logger = new Soup.Logger(Soup.LoggerLogLevel.MINIMAL, -1);
        session.add_feature(logger);
    }

    private async bool upload_image(string uri, out string? link)
    {
        link = null;

        uint8[] data;

        try {
            GLib.FileUtils.get_data(uri.split("://")[1], out data);
        } catch (GLib.FileError e) {
            warning(e.message);
            return false;
        }

        string image = GLib.Base64.encode(data);

        Soup.Message message = new Soup.Message("POST", "https://api.imgur.com/3/upload.json");
        message.request_headers.append("Authorization", "Client-ID be12a30d5172bb7");
        string req = "api_key=f410b546502f28376747262f9773ee368abb31f0&image=" + GLib.Uri.escape_string(image);
        message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, req.data);

        string? payload = null;

        session.send_message(message);

        payload = (string)message.response_body.data;

        if (payload == null) {
            return false;
        }

        Json.Parser parser = new Json.Parser();
        try {
            int64 len = payload.length;
            parser.load_from_data(payload, (ssize_t)len);
        } catch (GLib.Error e) {
            stderr.printf(e.message);
        }

        unowned Json.Object node_obj = parser.get_root().get_object();
        if (node_obj == null) {
            return false;
        }

        node_obj = node_obj.get_object_member("data");
        if (node_obj == null) {
            return false;
        }

        string? url = node_obj.get_string_member("link") ?? null;
        if (url == null) {
            warning("ERROR: %s\n", node_obj.get_string_member("error"));
            return false;
        }

        link = url;

        return true;
    }

    public string get_name() {
        return "Imgur";
    }

    public async void cancel_upload() {
        GLib.Idle.add(() => {
            session.abort();
            return false;
        });
    }
}

}