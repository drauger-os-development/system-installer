#!/bin/bash
# -*- coding: utf-8 -*-
#
#  installer.sh
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
#this file handles most of the installation process OUTSIDE the chroot
echo "	###	$0 STARTED	###	" 1>&2
echo "1"
SETTINGS="$1"
GLOBAL_IFS="$IFS" 
echo "3"
SETTINGS=$(echo "$SETTINGS" | sed 's/ , /:/g')
IFS=":"
SETTINGS=($SETTINGS)
IFS="$GLOBAL_IFS"
AUTO_PART=${SETTINGS[0]}
ROOT=${SETTINGS[1]}
EFI=${SETTINGS[2]}
HOME_DATA=${SETTINGS[3]}
SWAP=${SETTINGS[4]}
LANG_SET=${SETTINGS[5]}
TIME_ZONE=${SETTINGS[6]}
USERNAME=${SETTINGS[7]}
COMP_NAME=${SETTINGS[8]}
PASS=${SETTINGS[9]}
EXTRAS=${SETTINGS[10]}
UPDATES=${SETTINGS[11]}
LOGIN=${SETTINGS[12]}
MODEL=${SETTINGS[13]}
LAYOUT=${SETTINGS[14]}
VARIENT=${SETTINGS[15]}
#STEP 1: Partion and format the drive
if [ "$AUTO_PART" == "True" ]; then
	PARTITIONING=$(/usr/share/system-installer/modules/auto-partitioner.sh "$ROOT" "$EFI" "$HOME_DATA")
	ROOT=$(echo "$PARTITIONING" | awk '{print $2}' | sed 's/:/ /g' | awk '{print $2}')
	EFI=$(echo "$PARTITIONING" | awk '{print $1}' | sed 's/:/ /g' | awk '{print $2}')
	HOME_DATA=$(echo "$PARTITIONING" | awk '{print $3}' | sed 's/:/ /g' | awk '{print $2}')
fi
set -Ee
set -o pipefail
echo "12"
#STEP 2: Mount the new partitions
mount "$ROOT" /mnt
if [ "$EFI" != "NULL" ]; then
	mkdir -p /mnt/boot/efi
	mount "$EFI" /mnt/boot/efi
fi
# echo "$HOME_DATA" | grep -q "NULL" 1>/dev/null 2>/dev/null
# TEST="$?"
# if [ "$TEST" != "0" ]; then
if [ "$HOME_DATA" != "NULL" ]; then
	mkdir -p /mnt/home
	mount "$HOME_DATA" /mnt/home
fi
if [ "$SWAP" != "FILE" ]; then
	swapon "$SWAP"
else
	echo "SWAP FILE NOT CREATED YET" 1>&2
fi
echo "14"
#STEP 3: Unsquash the sqaushfs and get the files where they need to go
SQUASHFS=$(grep 'squashfs_Location=' /etc/system-installer/default.config | sed 's/squashfs_Location=//')
if [ "$SQUASHFS" == "" ] || [ ! -f "$SQUASHFS" ]; then
	echo "SQUASHFS FILE DOES NOT EXIST" 1>&2
	/usr/share/system-installer/UI/error.py "SQUASHFS FILE DOES NOT EXIST"
	exit 2
fi
echo "17"
cd /mnt
{
	echo "CLEANING INSTALLATION DIRECTORY."
	#cleaning the long way in order to handle some bugs
#	list=$(ls -A)
#	for each in $list; do
#		if [ "$each" != "boot" ] || [ "$each" != "home" ]; then
#			rm -rf "$each"
#		elif [ "$each" == "boot" ]; then
#			cd boot
#			list2=$(ls -A)
#			for each2 in $list2; do
#				if [ "$each2" != "efi" ]; then
#					rm -rf "$each2"
#				else
#					rm -rf efi/*
#				fi
#			done
#			cd ..
#		elif [ "$each" == "home" ]; then
#			echo "EXEMPTING CLEANING OF /home"
#		fi
#	done
	# This should be a much faster and more robust way of performing this action
	rm -vrf --one-file-system $(ls -A | grep -vE "boot|home")
	cd boot
	rm -vrf --one-file-system $(ls -A | grep -v "efi")
	cd ..
} 1>&2
echo "EXTRACTING SQUASHFS" 1>&2
unsquashfs "$SQUASHFS" 1>/dev/null
# While it would be faster to do something like:
#	mv squashfs-root/{.,}* ../
# This keeps throwing errors. So, we use this much more verbose, but easier to control, loop:
file_list=$(ls squashfs-root)
set +Ee
for each in $file_list; do
	mv -v /mnt/squashfs-root/$each /mnt/$each 1>&2
done
rm -rfv squashfs-root 1>&2
mkdir /mnt/boot 2>/dev/null || echo "/mnt/boot already created" 1>&2
cp -Rv /boot/* /mnt/boot 1>&2
echo "32"
#STEP 4: Update fstab
rm /mnt/etc/fstab
genfstab -U /mnt > /mnt/etc/fstab
echo "34"
#STEP 5: copy scripts into chroot
LIST=$(ls /usr/share/system-installer/modules)
LIST=$(echo "$LIST" | grep -v "partitioner")
for each in $LIST; do
	cp "/usr/share/system-installer/modules/$each" "/mnt/$each"
done
echo "35"
#STEP 6: Run Master script inside chroot
#don't run it as a background process so we know when it gets done
mv /mnt/etc/resolv.conf /mnt/etc/resolv.conf.save
cp -v /etc/resolv.conf /mnt/etc/resolv.conf 1>&2
echo "36"
#Check to make sure all these vars are set
#if not, set them to some defaults
if [ "$LANG_SET" == "" ]; then
	echo "\$LANG_SET is not set. Defaulting to english" 1>&2
	LANG_SET="english"
fi
if [ "$TIME_ZONE" == "" ]; then
	echo "\$TIME_ZONE is not set. Defaulting to EST" 1>&2
	TIME_ZONE="EST"
fi
if [ "$USERNAME" == "" ]; then
	echo "\$USERNAME is not set. No default. Prompting user . . ." 1>&2
	USERNAME=$(zenity --entry --text="We're sorry. We lost your username somewhere in the chain. What was it again?")
fi
if [ "$COMP_NAME" == "" ]; then
	echo "\$COMP_NAME is not set. Defaulting to drauger-system-installed" 1>&2
	COMP_NAME="drauger-system-installed"
fi
if [ "$PASS" == "" ]; then
	echo "\$PASS is not set. No default. Prompting user . . ." 1>&2
	PASS=$(zenity --entry --hide-text --text="We're sorry. We lost your password somewhere in the chain. What was it again?")
fi
if [ "$EXTRAS" == "" ]; then
	echo "\$EXTRAS is not set. Defaulting to false." 1>&2
	EXTRAS=false
fi
if [ "$UPDATES" == "" ]; then
	echo "\$UPDATES is not set. Defaulting to false." 1>&2
	UPDATES=false
fi
# we don't check EFI or ROOT cause if they weren't set the script would have failed.
arch-chroot /mnt '/MASTER.sh' "$LANG_SET , $TIME_ZONE , $USERNAME , $PASS , $COMP_NAME , $EXTRAS , $UPDATES , $EFI , $ROOT , $LOGIN , $MODEL , $LAYOUT , $VARIENT"
#STEP 7: Clean up
#I know this isn't the best way of doing this, but it is easier than changing each of the file name in $LIST
echo "Removing installation scripts and resetting resolv.conf" 1>&2
for each in $LIST; do
	rm -v "/mnt/$each"
done
echo "89"
rm -v /mnt/etc/resolv.conf
mv -v /mnt/etc/resolv.conf.save /mnt/etc/resolv.conf
echo "98"
#make sure a kernel got installed
check=$(ls /mnt/boot/vmlinuz*)
if [ "$check" == ""  ]; then
	echo "	### KERNEL NOT INSTALLED. CORRECTING . . .	###	" 1>&2
	cp /usr/share/system-installer/modules/kernel.7z /mnt/
	arch-chroot /mnt "bash -c '7z x /kernel.7z; dpkg -R --install /kernel/'"
	rm -rf /mnt/kernel /mnt/kernel.7z
fi
#check to make sure systemd-boot got configured
contents=$(ls /mnt/boot/efi/loader/entries)
if [ "$contents" == "" ] && [ "$EFI" != "NULL" ]; then
	echo "	### SYSTEMD-BOOT NOT CONFIGURED. CORRECTING . . .	###	" 1>&2
	cp /usr/share/system-installer/modules/systemd_boot_config.py /mnt
	arch-chroot /mnt 'python3' '/systemd_boot_config.py' "$ROOT"
	arch-chroot /mnt "/etc/kernel/postinst.d/zz-update-systemd-boot"
	rm /mnt/systemd_boot_config.py
fi
rm -rf /mnt/home/$USERNAME/.config/xfce4/panel/launcher-3
echo "100"
echo "	###	$0 CLOSED	###	" 1>&2
