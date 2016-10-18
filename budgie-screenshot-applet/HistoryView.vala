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

public class HistoryView : Gtk.Box
{
    private Gtk.Button clear_all_button;
    private Gtk.ListBox history_listbox;
    private GLib.Settings settings;
    private Gtk.Clipboard clipboard;
    private AutomaticScrollBox history_scroller;
    private HistoryViewItem history_view_item;
    public Gtk.Button history_button;

    private static GLib.Once<HistoryView> _instance;

    public HistoryView(GLib.Settings settings, Gtk.Clipboard clipboard, Gtk.Stack stack)
    {
        Object(spacing: 0, orientation: Gtk.Orientation.VERTICAL);
        set_size_request(300, -1);

        this.settings = settings;
        this.clipboard = clipboard;

        Gtk.Button history_back_button = new Gtk.Button.with_label("Back");
        history_back_button.set_tooltip_text("Back");
        history_back_button.set_can_focus(false);

        history_back_button.clicked.connect(() => { stack.set_visible_child_name("new_screenshot_view"); });

        Gtk.Label history_header_label = new Gtk.Label("<span font=\"11\">Recent Screenshots</span>");
        history_header_label.set_use_markup(true);
        history_header_label.set_halign(Gtk.Align.END);
        history_header_label.get_style_context().add_class("dim-label");

        Gtk.Separator separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);

        Gtk.Box history_header_sub_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        history_header_sub_box.margin = 10;
        history_header_sub_box.pack_start(history_back_button, false, false, 0);
        history_header_sub_box.pack_end(history_header_label, true, true, 0);

        Gtk.Box history_header_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        history_header_box.pack_start(history_header_sub_box, true, true, 0);
        history_header_box.pack_start(separator, true, true, 0);

        history_listbox = new Gtk.ListBox();
        history_listbox.set_selection_mode(Gtk.SelectionMode.NONE);
        history_scroller = new AutomaticScrollBox(null, null);
        history_scroller.max_height = 265;
        history_scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        history_scroller.add(history_listbox);

        clear_all_button = new Gtk.Button.with_label("Clear all Screenshots");
        clear_all_button.get_child().margin = 5;
        clear_all_button.get_child().margin_start = 0;
        clear_all_button.clicked.connect(clear_all);
        clear_all_button.set_can_focus(false);
        clear_all_button.set_relief(Gtk.ReliefStyle.NONE);
        clear_all_button.get_style_context().add_class("bottom-button");

        Gtk.Separator clear_all_separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);

        Gtk.Box clear_all_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        clear_all_box.pack_start(clear_all_separator, false, false, 0);
        clear_all_box.pack_end(clear_all_button, false, true, 0);

        Gtk.Image placeholder_image = new Gtk.Image.from_icon_name(
            "action-unavailable-symbolic", Gtk.IconSize.DIALOG);
        placeholder_image.set_pixel_size(64);
        Gtk.Label placeholder_label = new Gtk.Label("<big>Nothing to see here</big>");
        placeholder_label.set_use_markup(true);
        Gtk.Box placeholder_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
        placeholder_box.margin = 40;
        placeholder_box.get_style_context().add_class("dim-label");
        placeholder_box.set_halign(Gtk.Align.CENTER);
        placeholder_box.set_valign(Gtk.Align.CENTER);
        placeholder_box.pack_start(placeholder_image, false, false, 6);
        placeholder_box.pack_start(placeholder_label, false, false, 0);

        history_listbox.set_placeholder(placeholder_box);
        placeholder_box.show_all();

        pack_start(history_header_box, false, false, 0);
        pack_start(history_scroller, true, true, 0);
        pack_start(clear_all_box, true, true, 0);
        show_all();
    }

    public void update_child_count()
    {
        uint len = history_listbox.get_children().length();
        clear_all_button.sensitive = history_button.visible = !(len == 0);
    }

    public async void update_history(int n, bool startup)
    {
        Gtk.ListBoxRow? separator_item = null;
        if (history_listbox.get_children().length() != 0) {
            Gtk.Separator separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
            separator.set_can_focus(false);
            separator_item = new Gtk.ListBoxRow();
            separator_item.set_selectable(false);
            separator_item.set_can_focus(false);
            separator_item.set_activatable(false);
            separator_item.add(separator);
            history_listbox.prepend(separator_item);
        }

        history_view_item = new HistoryViewItem(n, settings);
        history_listbox.prepend(history_view_item);

        Gtk.ListBoxRow parent = (Gtk.ListBoxRow) history_view_item.get_parent();
        parent.set_selectable(false);
        parent.set_can_focus(false);
        parent.set_activatable(false);

        history_listbox.show_all();

        if (startup) {
            history_view_item.set_reveal_child(true);
        } else {
            history_view_item.set_transition_type(Gtk.RevealerTransitionType.SLIDE_UP);
            GLib.Timeout.add(1, () => {
                history_view_item.set_reveal_child(true);
                return false;
            });
        }

        history_view_item.copy.connect((url) => { clipboard.set_text(url, -1); });

        history_view_item.deletion.connect(() => {
            int index = parent.get_index();

            if (history_listbox.get_children().length() == 1) {
                parent.destroy();
                update_child_count();
                return;
            }

            if (index == 0) {
                Gtk.Widget row_after = history_listbox.get_row_at_index(index + 1);
                if (row_after != null) row_after.destroy();
            } else {
                Gtk.Widget row_before = history_listbox.get_row_at_index(index - 1);
                if (row_before != null) row_before.destroy();
            }

            update_child_count();
        });

        update_child_count();
    }

    public void add_to_history(string link, string title)
    {
        GLib.Variant history_list = settings.get_value("history");

        GLib.DateTime datetime = new GLib.DateTime.now_local();
        int64 timestamp = datetime.to_unix();
        if (title == "") title = "Untitled";

        GLib.Variant timestamp_variant = new GLib.Variant.int64(timestamp);
        GLib.Variant title_variant = new GLib.Variant.string(title);
        GLib.Variant link_variant = new GLib.Variant.string(link);

        GLib.Variant[]? history_variant_list = null;
        for (int i=0; i<history_list.n_children(); i++) {
            GLib.Variant history_variant = history_list.get_child_value(i);
            history_variant_list += history_variant;
        }

        GLib.Variant history_entry_tuple = new GLib.Variant.tuple(
            {timestamp_variant, title_variant, link_variant});
        history_variant_list += history_entry_tuple;
        GLib.Variant history_entry_array = new GLib.Variant.array(null, history_variant_list);
        settings.set_value("history", history_entry_array);
        update_history.begin(history_variant_list.length - 1, false);
    }

    public void clear_all()
    {
        settings.reset("history");
        foreach (Gtk.Widget child in history_listbox.get_children()) {
            child.destroy();
        }
        update_child_count();
    }

    public static unowned HistoryView instance(GLib.Settings settings, Gtk.Clipboard clipboard, Gtk.Stack stack) {
        return _instance.once(() => { return new HistoryView(settings, clipboard, stack); });
    }
}