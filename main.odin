package main

import "core:fmt"
import win32 "core:sys/win32"

// TODO @cleanup global
running := true;
bitmap_info: win32.Bitmap_Info;
bitmap_memory: rawptr;
bitmap_handle: win32.Hbitmap;
device_context: win32.Hdc;


main :: proc() {
    using win32;

    module:= get_module_handle_a(nil);
    handle := cast(Hinstance)module;

    window_class := Wnd_Class_A {
        // style = CS_OWNDC|CS_HREDRAW|CS_VREDRAW,
        wnd_proc = win32_window_callback,
        instance = handle,
        // icon = ,
        class_name = "HandmadeHeroWindowClass"
    };

    atom := register_class_a(&window_class);
    
    if atom == 0 {
        // TODO Logging
        return;
    }
    
    window_handle := create_window_ex_a(
        0,
        window_class.class_name,
        "Handmade Hero",
        WS_OVERLAPPEDWINDOW|WS_VISIBLE,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        cast(Hwnd)nil,
        cast(Hmenu)nil,
        handle,
        nil
    );

    if window_handle == nil {
        // TODO Logging
        return;
    }

    message: Msg;
    for running {
        message_result := get_message_a(&message, Hwnd(nil), 0, 0);
        if i32(message_result) > 0 {
            translate_message(&message);
            dispatch_message_a(&message);
        }
        else {
            break;
        }
    }
}


win32_window_callback :: proc "std" (window: win32.Hwnd, message: u32, wparam: win32.Wparam, lparam: win32.Lparam) -> win32.Lresult {
    using win32;
    result := Lresult {};

    switch (message) {
        case WM_SIZE:
            client_rect: Rect ;
            get_client_rect(window, &client_rect);
            width := client_rect.right - client_rect.left;
            height := client_rect.bottom - client_rect.top;
            resize_dib_section(width, height);
        case WM_DESTROY:
            // TODO handle this as an error - recreate window?
            running = false;
        case WM_CLOSE:
            // TODO handle this with a message to the user
            running = false;
        case WM_ACTIVATEAPP:
        case WM_PAINT:
            paint: Paint_Struct;
            device_context := begin_paint(window, &paint);
            x := paint.rc_paint.left;
            y := paint.rc_paint.top;
            width := paint.rc_paint.right - paint.rc_paint.left;
            height := paint.rc_paint.bottom - paint.rc_paint.top;
            win32_update_window(device_context, window, x, y, width, height);

            end_paint(window, &paint);
        case:
            result = def_window_proc_a(window, message, wparam, lparam);
    }
    return result;
}


win32_update_window :: proc "std" (device_context: win32.Hdc, window: win32.Hwnd, x, y, w, h: i32) {
    using win32;
    stretch_dibits(device_context, 
                   x, y, w, h, 
                   x, y, w, h,
                   bitmap_memory, &bitmap_info,
                   DIB_RGB_COLORS,
                   SRCCOPY
    );
}


resize_dib_section :: proc "std" (width: i32, height: i32) {
    using win32;

    // TODO Bulletproof this
    // Maybe don't free first, free after, then free first if that fails

    if bitmap_handle != nil {
        delete_object(Hgdiobj(bitmap_handle));
    }
    
    if device_context == nil {
        // TODO Should we recreate these under special circumstances
        device_context = create_compatible_dc(Hdc(nil));
    }

    bitmap_info.size = size_of(Bitmap_Info_Header);
    bitmap_info.width = width;
    bitmap_info.height = height;
    bitmap_info.planes = 1;
    bitmap_info.bit_count = 32;
    bitmap_info.compression = BI_RGB;
    

    bitmap_handle = create_dib_section(
        device_context,
        &bitmap_info,
        DIB_RGB_COLORS,
        bitmap_memory,
        Handle(nil),
        0
    );
}