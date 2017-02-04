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

interface IProvider : GLib.Object
{
    public abstract async bool upload_image(string uri, out string? link);
    public abstract string get_name();
    public abstract async void cancel_upload();
}

} // End namespace