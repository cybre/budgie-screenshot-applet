# screenshot-applet
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
```

These can be installed on Solus by running:  
```
sudo eopkg it vala libgtk-3-devel glib2-devel libpeas-devel budgie-desktop-devel \
libjson-glib-devel libnotify-devel librest-devel
```

You will also need Gnome Screenshot to be able to use this applet.  
`sudo eopkg it gnome-screenshot`

## Installing
```
./autogen.sh --prefix=/usr
make
sudo make install
```

A package in the Solus repo will soon be available.
