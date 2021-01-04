package xinput

import win32 "core:sys/win32"


XUSER_MAX_COUNT : u32 : 4;
ERROR_SUCCESS : u32 : 0;


GAMEPAD_DPAD_UP         : u16 : 1;
GAMEPAD_DPAD_DOWN       : u16 : 2;
GAMEPAD_DPAD_LEFT       : u16 : 4;
GAMEPAD_DPAD_RIGHT      : u16 : 8;
GAMEPAD_START           : u16 : 16;
GAMEPAD_BACK            : u16 : 32;
GAMEPAD_LEFT_THUMB      : u16 : 64;
GAMEPAD_RIGHT_THUMB     : u16 : 128;
GAMEPAD_LEFT_SHOULDER   : u16 : 256;
GAMEPAD_RIGHT_SHOULDER  : u16 : 512;
GAMEPAD_A               : u16 : 4096;
GAMEPAD_B               : u16 : 8192;
GAMEPAD_X               : u16 : 16384;
GAMEPAD_Y               : u16 : 32768;


Gamepad :: struct {
    buttons: u16,
    left_trigger: u8,
    right_trigger: u8,
    thumb_lx: i16,
    thumb_ly: i16,
    thumb_rx: i16,
    thumb_ry: i16,
};


State :: struct {
    packet_number: u32,
    using gamepad: Gamepad
};


Vibration :: struct {
    left_motor_speed: u16,
    right_motor_speed: u16
};


xinput_enable :: #type proc "std" (enable: win32.Bool);
enable: xinput_enable;


xinput_get_state :: #type proc "std" (index: u32, state: ^State) -> u32;
get_state: xinput_get_state;


xinput_set_state :: #type proc "std" (user_index: u32, vibration: ^Vibration) -> u32;
set_state: xinput_set_state;


load :: proc() -> bool {
    using win32;
    module := load_library_a("xinput1_4.dll");

    if module == nil {
        module = load_library_a("xinput1_3.dll");    
    }

    if module == nil {
        module = load_library_a("xinput9_1_0.dll");
    }

    if module == nil {
        return false;
    }

    enable = cast(xinput_enable)get_proc_address(module, "XInputEnable");
    get_state = cast(xinput_get_state)get_proc_address(module, "XInputGetState");
    set_state = cast(xinput_set_state)get_proc_address(module, "XInputSetState");

    return true;
}