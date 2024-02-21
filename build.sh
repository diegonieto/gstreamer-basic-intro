#!/bin/bash

cd ~/gstreamer
~/meson/meson.py setup builddir --wipe \
	-Dbad=enabled \
	-Dlibav=disabled \
	-Dgst-plugins-ugly:x264=enabled \
	-Dgpl=enabled \
	-Dgst-plugins-bad:wayland=enabled \
	-Dgst-plugins-bad:closedcaption=enabled
