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

private class Uploader : GLib.Object
{
    private GLib.HashTable<string, Providers.IProvider> upload_providers;
    private GLib.Queue<Widgets.HistoryItem>? upload_queue = null;
    private Providers.IProvider? provider = null;
    private GLib.Cancellable? cancellable = null;
    private bool upload_in_progress = false;

    public signal void upload_started();
    public signal void upload_finished();

    public Uploader()
    {
        upload_providers = new GLib.HashTable<string, Providers.IProvider>(str_hash, str_equal);
        upload_queue = new GLib.Queue<Widgets.HistoryItem>();

        // Upload providers
        upload_providers.set("0x0", new Providers.NilxNil());
        upload_providers.set("ibin", new Providers.Ibin());
        upload_providers.set("imgur", new Providers.Imgur());
        upload_providers.set("ftp", new Providers.FTP());
    }

    public async void start_upload()
    {
        upload_started();
        upload_in_progress = true;

        Widgets.HistoryItem? item = null;

        while ((item = upload_queue.pop_head()) != null) {
            provider = upload_providers.get(BackendUtil.settings_manager.upload_provider);
            if (provider == null) {
                item.upload_finished(null, false);
                break;
            }

            cancellable = new GLib.Cancellable();
            item.upload_started();

            bool status = false;
            string url = item.item_uri;

            stdout.putc('\n');

            int64 leng = 0;
            ulong sig = provider.progress_updated.connect((size, chunk) => {
                leng += chunk;
                item.update_progress(size, leng);
            });

            status = yield provider.upload_image(url, out url);

            provider.disconnect(sig);

            item.upload_finished(url, status);
        }

        upload_finished();
        upload_in_progress = false;
        Curl.global_cleanup();
    }

    public void add_to_queue(Widgets.HistoryItem item) {
        upload_queue.push_tail(item);
    }

    public void remove_from_queue(Widgets.HistoryItem item) {
        upload_queue.remove(item);
    }

    public async void cancel_upload() {
        cancellable.cancel();
        provider.cancel_upload.begin();
    }

    public bool is_cancelled() {
        return cancellable.is_cancelled();
    }

    public bool is_upload_in_progress() {
        return upload_in_progress;
    }

    public unowned GLib.HashTable<string, Providers.IProvider> get_providers() {
        return upload_providers;
    }
}

} // End namespace
