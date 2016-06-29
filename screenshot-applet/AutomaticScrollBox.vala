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
   public class AutomaticScrollBox : Gtk.ScrolledWindow
   {
        public int max_height { default = 512; get; set; }

        public AutomaticScrollBox(Gtk.Adjustment? hadj = null, Gtk.Adjustment? vadj = null) {
            Object(hadjustment : hadj, vadjustment : vadj);
        }

        construct {
            notify["max-height"].connect(queue_resize);
        }

        public override void get_preferred_height_for_width(int width, out int minimum_height, out int natural_height)
        {
            unowned Gtk.Widget child = get_child();

            if (child != null) {
                child.get_preferred_height_for_width(width, out minimum_height, out natural_height);

                minimum_height = int.min(max_height, minimum_height);
                natural_height = int.min(max_height, natural_height);
            } else {
                minimum_height = natural_height = 0;
            }
        }

        public override void get_preferred_height(out int minimum_height, out int natural_height)
        {
            unowned Gtk.Widget child = get_child();

            if (child != null) {
                child.get_preferred_height(out minimum_height, out natural_height);

                minimum_height = int.min(max_height, minimum_height);
                natural_height = int.min(max_height, natural_height);
            } else {
                minimum_height = natural_height = 0;
            }
        }
    }
}