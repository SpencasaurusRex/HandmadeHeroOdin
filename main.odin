package main

import "core:fmt"
import "core:mem"
import win32 "core:sys/win32"

import "xinput"

// TODO @cleanup global
running := true;
buffer: Win32_Offscreen_Buffer;


Win32_Offscreen_Buffer :: struct {
    bitmap_info: win32.Bitmap_Info,
    memory: rawptr,
    width: i32,
    height: i32,
    need_to_resize: bool,
    x_offset: i32,
    y_offset: i32
};


Win32_Window_Dimension :: struct {
    width: i32,
    height: i32
};


win32_get_window_dimension :: proc "std" (window: win32.Hwnd) -> Win32_Window_Dimension {
    using win32;
    client_rect: Rect;
    get_client_rect(window, &client_rect);

    return Win32_Window_Dimension {
        width = client_rect.right - client_rect.left,
        height = client_rect.bottom - client_rect.top
    };
}


render_weird_gradient :: proc(buffer: ^Win32_Offscreen_Buffer, blue_offset, green_offset: i32) {
    pixel_count := int(buffer.width * buffer.height);
    
    Pixel :: [4]u8;
    pixels := mem.slice_ptr(cast(^Pixel)buffer.memory, pixel_count);

    for y in 0..<buffer.height {
        for x in 0..<buffer.width {
            pixels[x + y * buffer.width][0] = cast(u8)(x + blue_offset);
            pixels[x + y * buffer.width][1] = cast(u8)(y + green_offset);
        }
    }
}


resize_dib_section :: proc "std" (buffer: ^Win32_Offscreen_Buffer, width, height: i32) {
    using win32;

    if buffer.memory != nil {
        virtual_free(buffer.memory, 0, MEM_RELEASE);
    }

    buffer.width = width;
    buffer.height = height;

    buffer.bitmap_info.size = size_of(Bitmap_Info_Header);
    buffer.bitmap_info.width = buffer.width;
    buffer.bitmap_info.height = -buffer.height;
    buffer.bitmap_info.planes = 1;
    buffer.bitmap_info.bit_count = 32;
    buffer.bitmap_info.compression = BI_RGB;
    
    pixel_count := int(buffer.width * buffer.height);
    bitmap_memory_size := uint(4 * pixel_count);

    buffer.memory = virtual_alloc(nil, bitmap_memory_size, MEM_COMMIT, PAGE_READWRITE);
}


win32_display_buffer_in_window :: proc "std" (buffer: ^Win32_Offscreen_Buffer, device_context: win32.Hdc, window_width, window_height: i32) {
    using win32;
    
    stretch_dibits(
        device_context,
        0, 0, window_width, window_height,
        0, 0, buffer.width, buffer.height,
        buffer.memory, 
        &buffer.bitmap_info,
        DIB_RGB_COLORS,SRCCOPY
    );
}


win32_window_callback :: proc "std" (window: win32.Hwnd, message: u32, wparam: win32.Wparam, lparam: win32.Lparam) -> win32.Lresult {
    using win32;
    result := Lresult {};

    switch (message) {
        case WM_CLOSE:
            // TODO handle this with a message to the user
            running = false;
        case WM_ACTIVATEAPP:
        case WM_DESTROY:
            // TODO handle this as an error - recreate window?
            running = false;
        case WM_SYSKEYDOWN: fallthrough;
        case WM_SYSKEYUP: fallthrough;
        case WM_KEYDOWN: fallthrough;
        case WM_KEYUP:
            vk_code := rune(wparam);
            was_down := (int(lparam) >> 30) == 1;
            is_down := (int(lparam) >> 31) == 0;
            if was_down == is_down {
                break;
            }

            if vk_code == 'W' {
                
            }
            else if vk_code == 'A' {

            }
            else if vk_code == 'S' {
                
            }
            else if vk_code == 'D' {
                
            }
            else if vk_code == 'Q' {
                
            }
            else if vk_code == 'E' {
                
            }
            else if int(vk_code) == VK_LEFT {

            }
            else if int(vk_code) == VK_UP {

            }
            else if int(vk_code) == VK_RIGHT {

            }
            else if int(vk_code) == VK_DOWN {

            }
            else if int(vk_code) == VK_ESCAPE {
                running = false;
            }
            else if int(vk_code) == VK_SPACE {
                
            }

        case WM_SIZE:
            
        case WM_PAINT:
            paint: Paint_Struct;
            device_context := begin_paint(window, &paint);
            
            dimension := win32_get_window_dimension(window);
            win32_display_buffer_in_window(&buffer, device_context, dimension.width, dimension.height);

            end_paint(window, &paint);
        case:
            result = def_window_proc_a(window, message, wparam, lparam);
    }
    return result;
}

blue_offset := i32(0);
green_offset := i32(0);


main :: proc() {
    using win32;

    xinput.load();

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
    
    window := create_window_ex_a(
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

    if window == nil {
        // TODO Logging
        return;
    }

    dimension := win32_get_window_dimension(window);
    resize_dib_section(&buffer, dimension.width, dimension.height);

    // blue_offset := i32(0);
    // green_offset := i32(0);

    for running {
        message: Msg;
        for {
            message_result := peek_message_a(&message, Hwnd(nil), 0, 0, PM_REMOVE);
            if i32(message_result) <= 0 {
                break;
            }

            if message.message == WM_QUIT {
                running = false;
            }
            translate_message(&message);
            dispatch_message_a(&message);
        }

        {
            using xinput;
            for controller_index in 0..<XUSER_MAX_COUNT {
                state: State;
                result := get_state(0, &state);
                if result == ERROR_SUCCESS {
                    // TODO See if packet_number increments too rapidly
                    up := (state.buttons & GAMEPAD_DPAD_UP) > 0;
                    down := (state.buttons & GAMEPAD_DPAD_DOWN) > 0;
                    left := (state.buttons & GAMEPAD_DPAD_LEFT) > 0;
                    right := (state.buttons & GAMEPAD_DPAD_RIGHT) > 0;
                    start := (state.buttons & GAMEPAD_START) > 0;
                    back := (state.buttons & GAMEPAD_BACK) > 0;
                    a := (state.buttons & GAMEPAD_A) > 0;
                    b := (state.buttons & GAMEPAD_B) > 0;
                    x := (state.buttons & GAMEPAD_X) > 0;
                    y := (state.buttons & GAMEPAD_Y) > 0;

                    stick_x := state.thumb_lx;
                    stick_y := state.thumb_ly;

                    if a {
                        green_offset += 1;
                    }
                }
                else {
                    // Controller is not available
                }
            }    
        }

        render_weird_gradient(&buffer, blue_offset, green_offset);
        
        dc := get_dc(window);
        
        dimension := win32_get_window_dimension(window);
        win32_display_buffer_in_window(&buffer, dc, dimension.width, dimension.height);
        
        release_dc(window, dc);

        blue_offset += 1;
        green_offset += 1;
    }
}