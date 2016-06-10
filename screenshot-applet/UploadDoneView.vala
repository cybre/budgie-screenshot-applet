namespace ScreenshotApplet
{
    public class UploadDoneView : Gtk.Box
    {
        private Gtk.Image done_image;
        private Gtk.Label done_label;
        public Gtk.Button done_back_button;
        public Gtk.Button done_open_button;
        private Gtk.Box button_box;

        public UploadDoneView()
        {
            Object(spacing: 0, orientation: Gtk.Orientation.VERTICAL);
            this.margin = 20;
            this.width_request = 200;
            this.height_request = 150;

            done_image = new Gtk.Image.from_icon_name("emblem-ok-symbolic", Gtk.IconSize.DIALOG);
            done_image.pixel_size = 64;

            done_label = new Gtk.Label("<big>The link has been copied \nto your clipboard!</big>");
            done_label.margin_top = 10;
            done_label.set_justify(Gtk.Justification.CENTER);
            done_label.set_use_markup(true);

            done_back_button = new Gtk.Button.with_label("Back");
            done_open_button = new Gtk.Button.with_label("Open");

            button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            button_box.get_style_context().add_class("linked");
            button_box.margin_top = 20;
            button_box.pack_start(done_back_button, true, true, 0);
            button_box.pack_start(done_open_button, true, true, 0);

            this.pack_start(done_image, true, true, 0);
            this.pack_start(done_label, true, true, 0);
            this.pack_start(button_box, true, true, 0);
        }
    }
}