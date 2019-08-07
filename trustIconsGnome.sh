#!/bin/bash

#	AstroPi3 Gnome Icon trusting script for setupUbuntuSBC
#	This script is necessary to allow the desktop icons to load properly and be executable
#	on the Ubuntu Gnome Destkop
#﻿  Copyright (C) 2018 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

for i in $HOME/Desktop/*.desktop; do
  [ -f "${i}" ] || break
  gio set "${i}" "metadata::trusted" yes
done
for i in $HOME/Desktop/utilities/*.desktop; do
  [ -f "${i}" ] || break
  gio set "${i}" "metadata::trusted" yes
done