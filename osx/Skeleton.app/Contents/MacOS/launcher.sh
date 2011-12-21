#!/bin/sh

# http://letoinedevs.blogspot.com/2011/10/make-mac-os-x-application-bundle-for.html

name="`basename $0`"
tmp="`pwd`/$0"
tmp=`dirname "$tmp"`
tmp=`dirname "$tmp"`
bundle=`dirname "$tmp"`
bundleContents="$bundle"/Contents
bundleResources="$bundleContents"/Resources
bundleLib="$bundleResources"/lib

export DYLD_LIBRARY_PATH="$bundleLib:$DYLD_LIBRARY_PATH"

cd "$bundleResources"
exec "./alone"
