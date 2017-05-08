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

private class BackendUtil
{
    public static SettingsManager? settings_manager = null;
    public static ScreenshotManager? screenshot_manager = null;
    public static Uploader? uploader = null;

    public BackendUtil(GLib.Settings settings) {
        settings_manager = new SettingsManager(settings);
        screenshot_manager = new ScreenshotManager();
        uploader = new Uploader();
    }
}

}