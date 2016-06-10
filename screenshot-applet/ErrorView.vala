namespace ScreenshotApplet
{
    public class ErrorView : Gtk.Box
    {
        private Gtk.Image error_image;
        private Gtk.Label error_label;
        public Gtk.Button error_back_button;

        public ErrorView()
        {
            Object(spacing: 0, orientation: Gtk.Orientation.VERTICAL);
            this.margin = 20;
            this.width_request = 200;
            this.height_request = 150;

            error_image = new Gtk.Image.from_icon_name("emblem-important-symbolic", Gtk.IconSize.DIALOG);
            error_image.pixel_size = 64;

            error_label = new Gtk.Label("<big>We couldn't upload your image</big>\nCheck your internet connection.");
            error_label.margin_top = 10;
            error_label.set_justify(Gtk.Justification.CENTER);
            error_label.set_use_markup(true);

            error_back_button = new Gtk.Button.with_label("Back");
            error_back_button.margin_top = 20;

            this.pack_start(error_image, true, true, 0);
            this.pack_start(error_label, true, true, 0);
            this.pack_start(error_back_button, true, true, 0);
        }
    }
}