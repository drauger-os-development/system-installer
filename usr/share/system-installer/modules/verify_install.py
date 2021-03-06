#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  verify_install.py
#
#  Copyright 2020 Thomas Castleman <contact@draugeros.org>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#
#
"""Verify that installation completed correctly"""
from __future__ import print_function
from sys import stderr
from os import listdir, path, remove
from shutil import move, rmtree
import apt

import modules.purge as purge


def __eprint__(*args, **kwargs):
    """Make it easier for us to print to stderr"""
    print(*args, file=stderr, **kwargs)


def verify(username, password):
    """Verify installation success"""
    __eprint__("\t###\tverify_install.py STARTED\t###\t")
    home_contents = listdir("/home")
    cache = apt.cache.Cache()
    cache.open()
    if (("system-installer" in cache) and cache["system-installer"].is_installed):
        cache["system-installer"].mark_delete()
    if path.isdir("/home/home/live"):
        move("/home/home/live", "/home/" + username)
    try:
        remove("/home/" + username + "/Desktop/system-installer.desktop")
    except FileNotFoundError:
        try:
            rmtree("/home/" + username + "/.config/xfce4/panel/launcher-3")
        except FileNotFoundError:
            pass
    if path.isfile("/etc/kernel/postinst.d/zz-update-systemd-boot"):
        with cache.actiongroup():
            for each in cache:
                if (("grub" in each.name) and each.is_installed):
                    each.mark_delete()
    cache.commit()
    purge.autoremove(cache)
    cache.close()
    __eprint__("\t###\tverify_install.py CLOSED\t###\t")
