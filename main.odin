package main

import "core:fmt"
import win32 "core:sys/win32"

main :: proc() {
    using win32;

    zero: i64 = 0;
    null := transmute(^i64)zero;
    null_string := transmute(cstring)zero;
    null_hwnd := transmute(Hwnd)zero;
    module:= get_module_handle_a(null_string);
    handle := cast(Hinstance)module;

    window_class := Wnd_Class_A {
        // style = CS_OWNDC|CS_HREDRAW|CS_VREDRAW,
        wnd_proc = window_callback,
        instance = handle,
        // icon = ,
        class_name = "HandmadeHeroWindowClass"
    };

    atom := register_class_a(&window_class);
    if (atom != 0) {
        window_handle := 
        create_window_ex_a(
            0,
            window_class.class_name,
            "Handmade Hero",
            WS_OVERLAPPEDWINDOW|WS_VISIBLE,
            CW_USEDEFAULT,
            CW_USEDEFAULT,
            CW_USEDEFAULT,
            CW_USEDEFAULT,
            cast(Hwnd)null,
            cast(Hmenu)null,
            handle,
            null
        );

        message: Msg;
        for { 
            message_result := get_message_a(&message, null_hwnd, 0, 0);
            if i32(message_result) > 0 {
                translate_message(&message);
                dispatch_message_a(&message);
            }
            else {
                break;
            }
        }
    }
}

operation := u32(win32.WHITENESS);

window_callback :: proc "std" (window: win32.Hwnd, message: u32, wparam: win32.Wparam, lparam: win32.Lparam) -> win32.Lresult {
    using win32;
    result := Lresult {};

    switch (message) {
        case WM_SIZE:
            output_debug_string_a("WM_SIZE");
        case WM_DESTROY:
            output_debug_string_a("WM_DESTROY");
        case WM_CLOSE:
            output_debug_string_a("WM_CLOSE");
        case WM_ACTIVATEAPP:
            output_debug_string_a("WM_ACTIVATEAPP");
        case WM_PAINT:
            paint: Paint_Struct;
            device_context := begin_paint(window, &paint);
            x := paint.rc_paint.left;
            y := paint.rc_paint.top;
            width := paint.rc_paint.right - paint.rc_paint.left;
            height := paint.rc_paint.bottom - paint.rc_paint.top;

            if operation == WHITENESS {
                operation = BLACKNESS;
            }
            else {
                operation = WHITENESS;
            }
            pat_blt(device_context, x, y, width, height, operation);

            end_paint(window, &paint);
        case:
            result = def_window_proc_a(window, message, wparam, lparam);
            // output_debug_string_a("other";)
    }
    return result;
}

// def_window_proc_a :: proc(hwnd: Hwnd, msg: u32, wparam: Wparam, lparam: Lparam) -> Lresult ---