# Budgie Screenshot Applet
Take a screenshot of your desktop, a window or region; save to disk and upload. Made with ❤ for Budgie Desktop.

## Dependencies
```
budgie-1.0 >= 2
gnome-desktop-3.0
gtk+-3.0 >= 3.20
json-glib-1.0
libsoup-2.4
vala
```

These can be installed on Solus by running:  
```bash
sudo eopkg it budgie-desktop-devel libgnome-desktop-devel libjson-glib-devel libsoup-devel vala
```

### Installing

**From source**  
```bash
mkdir build && cd build
meson --prefix /usr ..
ninja
sudo ninja install
```

**Solus**  
You can install budgie-screenshot-applet from the Software Centre or via the command line:
```bash
sudo eopkg it budgie-screenshot-applet
```

---

### Screenshot
<img align="center" alt="Screenshot" src="screenshot.png"/>
