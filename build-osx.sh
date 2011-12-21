#!/usr/bin/env bash

BUNDLE="$PWD/Lonely Planet.app"
PACKAGES="cairo gdk-pixbuf glib libcroco librsvg pango pixman sdl"
LIBS="libcroco-0.6.3.0.1.dylib
libgdk_pixbuf-2.0.0.dylib
libgio-2.0.0.dylib
libglib-2.0.0.dylib
libgmodule-2.0.0.dylib
libgobject-2.0.0.dylib
libgthread-2.0.0.dylib
libpango-1.0.0.dylib
libpangocairo-1.0.0.dylib
libpangoft2-1.0.0.dylib
libpixman-1.0.24.0.dylib
librsvg-2.2.dylib"

echo "Installing required homebrew packages: $PACKAGES"
echo "Note: This will only have an effect for missing packages."
for package in $PACKAGES; do
    brew install $package
done
echo "Done."

echo "Creating a copy of the bundle skeleton..."
ditto "$PWD/osx/Skeleton.app" "$BUNDLE"
echo "Done."

echo "Copying required lib from /usr/local/lib into the bundle..."
for lib in $LIBS; do
    ditto /usr/local/lib/$lib "$BUNDLE/Contents/Resources/lib/"
done
echo "Done."

echo "Compiling the game..."
source $PWD/devrc
rock -g -v "+-arch" "+x86_64" "+-Wl,-framework,Cocoa" -lSDLmain -lSDL
echo "Done."

echo "Copying configuration, assets and executable into the bundle..."
ditto $PWD/alone "./$BUNDLE/Contents/Resources/"
ditto $PWD/alone.config "./$BUNDLE/Contents/Resources/"
ditto $PWD/assets "./$BUNDLE/Contents/Resources/assets"
echo "Done."

echo " [ SUCCESS ] !"
