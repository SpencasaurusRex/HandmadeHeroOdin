package main

import "core:fmt"
import sys "core:sys/win32"

main :: proc() {
    using sys;
    title: cstring = "Handmade Hero";
    message: cstring = "This is Handmade Hero";
    handle := sys.get_active_window();
    message_box_a(handle, message, title, MB_OK | MB_ICONINFORMATION);
}