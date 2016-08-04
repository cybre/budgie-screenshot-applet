# budgie-screenshot-applet
A Budgie applet for taking and uploading screenshots to Imgur and Imagebin.

## Dependencies
```
vala
gtk+-3.0
gio-unix-2.0
libpeas-1.0
PeasGtk-1.0
budgie-1.0
json-glib-1.0
libnotify
rest-0.7
gnome-desktop-3.0
gnome-screenshot
```

These can be installed on Solus by running:  
```
sudo eopkg it vala libgtk-3-devel glib2-devel libpeas-devel budgie-desktop-devel \
libjson-glib-devel libnotify-devel librest-devel libgnome-desktop-devel gnome-screenshot
```

### Installing

**From source**  
```
./autogen.sh --prefix=/usr
make
sudo make install
```

**Solus**  
You can install budgie-screenshot-applet from the Software Centre or via the command line:
```
sudo eopkg it budgie-screenshot-applet
```

**Arch Linux**  
The package can be installed on Arch using
```
yaourt -S screenshot-applet
```

---

### Screenshot
![Screenshot](screenshot.png)
