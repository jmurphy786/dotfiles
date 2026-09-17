#!/usr/bin/env python3
"""Volume slider popup for Waybar - styled to match the theme."""

import gi
import subprocess
import sys

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, Gdk, GObject, GLib

THEME_CSS = """
window {
    background-color: #2C2A24;
    border: 2px solid #D08B57;
    border-radius: 8px;
    padding: 8px;
}

scale {
    min-height: 24px;
}

scale trough {
    background-color: #3A372F;
    border-radius: 6px;
    min-height: 12px;
    min-width: 200px;
}

scale highlight {
    background-color: #D08B57;
    border-radius: 6px;
}

scale slider {
    background-color: #DDD5C4;
    border: 2px solid #BFAA80;
    border-radius: 50%;
    min-width: 18px;
    min-height: 18px;
}

label {
    color: #DDD5C4;
    font-family: "Iosevka Nerd Font";
    font-size: 15px;
}
"""


def get_current_volume():
    try:
        output = subprocess.check_output(
            ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"],
            text=True,
        )
        # Output: "Volume: 0.26"
        vol = float(output.strip().split()[1])
        return int(vol * 100)
    except Exception:
        return 50


def set_volume(value):
    try:
        subprocess.run(
            ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", f"{value}%"],
            check=False,
        )
    except Exception:
        pass


class VolumePopup(Gtk.Window):
    def __init__(self):
        super().__init__()

        GLib.set_prgname("volume-slider")
        self.set_decorated(False)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_resizable(False)
        self.set_default_size(250, 60)
        self.set_position(Gtk.WindowPosition.MOUSE)
        self.set_type_hint(Gdk.WindowTypeHint.DIALOG)

        # Apply theme
        provider = Gtk.CssProvider()
        provider.load_from_data(THEME_CSS.encode())
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_border_width(12)
        self.add(box)

        self.label = Gtk.Label(label="")
        self.label.set_halign(Gtk.Align.CENTER)
        box.pack_start(self.label, False, False, 0)

        self.scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 150, 1)
        self.scale.set_draw_value(False)
        self.scale.set_value(get_current_volume())
        self.scale.set_hexpand(True)
        self.scale.connect("value-changed", self.on_scale_changed)
        box.pack_start(self.scale, True, True, 0)

        self.update_label(self.scale.get_value())

        # Close on focus out (enabled after a short delay to avoid waybar click closing it instantly)
        self.focus_out_enabled = False
        GLib.timeout_add(200, self.enable_focus_out)
        self.connect("focus-out-event", self.on_focus_out)
        self.connect("key-press-event", self.on_key_press)

        self.show_all()

        # Grab focus and keyboard
        self.grab_focus()

    def enable_focus_out(self):
        self.focus_out_enabled = True
        return False

    def on_scale_changed(self, scale):
        value = int(scale.get_value())
        self.update_label(value)
        set_volume(value)

    def update_label(self, value):
        self.label.set_text(f"Volume: {value}%")

    def on_focus_out(self, widget, event):
        if self.focus_out_enabled:
            self.close_window()
        return True

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_window()
            return True
        return False

    def close_window(self):
        Gtk.main_quit()


def main():
    popup = VolumePopup()
    popup.connect("destroy", Gtk.main_quit)
    Gtk.main()


if __name__ == "__main__":
    main()
