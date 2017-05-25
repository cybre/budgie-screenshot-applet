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

namespace ScreenshotApplet.Backend.Providers
{

private class Ibin : IProvider
{
    private Soup.SessionAsync session;

    public Ibin()
    {
        session = new Soup.SessionAsync();
        session.ssl_strict = false;
        Soup.Logger logger = new Soup.Logger(Soup.LoggerLogLevel.MINIMAL, -1);
        session.add_feature(logger);
    }

    public override async bool upload_image(string uri, out string? link)
    {
        link = null;

        GLib.File screenshot_file = GLib.File.new_for_uri(uri);

        uint8[] data;

        try {
            GLib.FileUtils.get_data(uri.split("://")[1], out data);
        } catch (GLib.FileError e) {
            warning(e.message);
            return false;
        }

        Soup.Buffer buffer = new Soup.Buffer.take(data);

        string mime_type = "application/octet-stream";
        Soup.Multipart multipart = new Soup.Multipart(mime_type);
        multipart.append_form_string("key", "uRj7fbCFkTPiFYOJK5ETYzVdjkgTrqBP");
        multipart.append_form_file("file", screenshot_file.get_basename(), mime_type, buffer);

        Soup.Message message = Soup.Form.request_new_from_multipart("https://imagebin.ca/upload.php", multipart);

        message.wrote_body_data.connect((chunk) => {
            progress_updated(message.request_body.length, chunk.length);
        });

        GLib.HashTable<string, string> content_type_params;
        message.request_headers.get_content_type(out content_type_params);
        message.request_headers.set_content_type(Soup.FORM_MIME_TYPE_MULTIPART, content_type_params);

        string? payload = null;

        session.send_message(message);

        payload = (string)message.response_body.data;

        if (payload == null) {
            return false;
        }

        string? url = payload.split("url:")[1];
        if (url == null || !url.has_prefix("http")) {
            return false;
        }

        link = url.strip();

        return true;
    }

    public override string get_name() {
        return "Ibin";
    }

    public override async void cancel_upload() {
        GLib.Idle.add(() => {
            session.abort();
            return false;
        });
    }
}

}