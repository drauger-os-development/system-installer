#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  partition-type.py
#  
#  Copyright 2019 Thomas Castleman <contact@draugeros.org>
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
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk
from subprocess import Popen

class main(Gtk.Window):

	def __init__(self):
		Gtk.Window.__init__(self, title="System Installer")
		self.grid=Gtk.Grid(orientation=Gtk.Orientation.VERTICAL)
		self.add(self.grid)
		
		self.label = Gtk.Label()
		self.label.set_markup("""
	Please select how you would like your system to be partioned:		
	""")
		self.label.set_justify(Gtk.Justification.LEFT)
		self.grid.attach(self.label, 1, 1, 5, 1)
		
		self.link = Gtk.Button.new_with_label("Open Gparted")
		self.link.connect("clicked", self.opengparted)
		self.grid.attach(self.link, 3, 5, 1, 1)
		

		# a new radiobutton with a label
		button1 = Gtk.RadioButton(label="Use Entire Disk")
		# connect the signal "toggled" emitted by the radiobutton
		# with the callback function toggled_cb
		button1.connect("toggled", self.toggled_cb)
		self.grid.attach(button1, 1, 3, 1, 1)

		# another radiobutton, in the same group as button1
		button2 = Gtk.RadioButton.new_from_widget(button1)
		# with label "Button 2"
		button2.set_label("Manually Set Up Partitions")
		# connect the signal "toggled" emitted by the radiobutton
		# with the callback function toggled_cb
		button2.connect("toggled", self.toggled_cb)
		# set button2 not active by default
		button2.set_active(False)
		self.grid.attach(button2, 1, 4, 1, 1)
		
		self.button1 = Gtk.Button.new_with_label("Okay -->")
		self.button1.connect("clicked", self.onnextclicked)
		self.grid.attach(self.button1, 5, 5, 1, 1)
			
		self.button2 = Gtk.Button.new_with_label("Exit")
		self.button2.connect("clicked", self.onexitclicked)
		self.grid.attach(self.button2, 4, 5, 1, 1)
			
	def onnextclicked(self,button):
			exit(0)
	def onexitclicked(self,button):
			exit(1)
	def opengparted(self,button):
		Popen("gparted")
			
	# callback function
	def toggled_cb(self, button):
		# a string to describe the state of the button
		state = "unknown"
		# whenever the button is turned on, state is on
		if button.get_active():
			state = "on"
		# else state is off
		else:
			state = "off"
		# whenever the function is called (a button is turned on or off)
		# print on the terminal which button was turned on/off
		print(button.get_label() + " was turned " + state)


def show_main():
	window = main()
	window.set_decorated(False)
	window.set_resizable(False)
	window.set_opacity(0.0)
	window.set_position(Gtk.WindowPosition.CENTER)
	window.show_all()
	Gtk.main() 
	window.connect("delete-event", Gtk.main_quit)

show_main()