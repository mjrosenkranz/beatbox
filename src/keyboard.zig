const std = @import("std");
const c = @cImport({
    @cInclude("xcb/xcb.h");
    @cInclude("X11/Xlib-xcb.h");
    @cInclude("X11/Xlib.h");
});

var display: ?*c.Display = null;
var connection: *c.xcb_connection_t = undefined;
var screen: *c.xcb_screen_t = undefined;
var window: c.xcb_window_t = undefined;
var wm_proto: c.xcb_atom_t = undefined;
var wm_del: c.xcb_atom_t = undefined;

const InputError = error {
    Connection,
    FlushError,
};

/// State of a key this frame
const KeyState = enum {
    Pressed,
    Released,
    None
};

/// The keymapping of keys
const keymap = enum(u8){ 
    z = 52,
    s = 39,
    x = 53,
    c = 54, 
    f = 41,
    v = 55,
    g = 42,
    b = 56,
    n = 57,
    j = 44,
    m = 58,
    k = 45,
    comma = 59,
    l = 46,
    dot = 60,
    slash = 61,
};

/// Key edge state
pub var key_states: [@typeInfo(keymap).Enum.fields.len]KeyState = [_]KeyState{.None} ** @typeInfo(keymap).Enum.fields.len;

/// Curent key state
var keys_pressed: [@typeInfo(keymap).Enum.fields.len]bool = [_]bool{false} ** @typeInfo(keymap).Enum.fields.len;

pub fn init() !void {
    // open the display
    display = c.XOpenDisplay(null).?;
    _ = c.XAutoRepeatOff(display);

    // get connection
    connection = c.XGetXCBConnection(display).?;
    
    if (c.xcb_connection_has_error(connection) != 0) {
        return InputError.Connection;
    }

    var itr: c.xcb_screen_iterator_t = c.xcb_setup_roots_iterator(c.xcb_get_setup(connection));
    // Use the last screen
    screen = @ptrCast(*c.xcb_screen_t, itr.data);

    // Allocate an id for our window
    window = c.xcb_generate_id(connection);

    // We are setting the background pixel color and the event mask
    const mask: u32  = c.XCB_CW_BACK_PIXEL | c.XCB_CW_EVENT_MASK;

    // background color and events to request
    const values = [_]u32 {screen.*.black_pixel, c.XCB_EVENT_MASK_BUTTON_PRESS | c.XCB_EVENT_MASK_BUTTON_RELEASE |
                       c.XCB_EVENT_MASK_KEY_PRESS | c.XCB_EVENT_MASK_KEY_RELEASE |
                       c.XCB_EVENT_MASK_EXPOSURE | c.XCB_EVENT_MASK_POINTER_MOTION |
                       c.XCB_EVENT_MASK_STRUCTURE_NOTIFY};

    // Create the window
    const cookie: c.xcb_void_cookie_t = c.xcb_create_window(
        connection,
        c.XCB_COPY_FROM_PARENT,
        window,
        screen.*.root,
        0,
        0,
        200,
        200,
        0,
        c.XCB_WINDOW_CLASS_INPUT_OUTPUT,
        screen.*.root_visual,
        mask,
        values[0..]);

    // Notify us when the window manager wants to delete the window
    const datomname = "WM_DELETE_WINDOW";
    const wm_delete_reply = c.xcb_intern_atom_reply(
        connection,
        c.xcb_intern_atom(
          connection,
          0,
          datomname.len,
          datomname),
        null);
    const patomname = "WM_PROTOCOLS";
    const wm_protocols_reply = c.xcb_intern_atom_reply(
        connection,
        c.xcb_intern_atom(
          connection,
          0,
          patomname.len,
          patomname),
        null);

    //// store the atoms
    wm_del = wm_delete_reply.*.atom;
    wm_proto = wm_protocols_reply.*.atom;

    // ask the sever to actually set the atom
    _ = c.xcb_change_property(
        connection,
        c.XCB_PROP_MODE_REPLACE,
        window,
        wm_proto,
        4,
        32,
        1,
        &wm_del);

    // Map the window to the screen
    _ = c.xcb_map_window(connection, window);

    // flush pending actions to the server
    if (c.xcb_flush(connection) <= 0) {
        return InputError.FlushError;
    }


}

fn updateKey(k: u8, pressed: bool) void {
    var i: usize = 0;
    inline for (@typeInfo(keymap).Enum.fields) |f| {
        if (k == f.value) {
            // if opposites then set
            if (keys_pressed[i] != pressed) {
                key_states[i] = if (pressed) KeyState.Pressed else KeyState.Released;
            }
            keys_pressed[i] = pressed;
        }
        i+=1;
    }
}

pub fn update() bool {
    // reset key_states to none
    key_states = [_]KeyState{.None} ** @typeInfo(keymap).Enum.fields.len;

    // Poll for events until null is returned.
    while (true) {
        const event = c.xcb_poll_for_event(connection);
        if (event == 0) {
            break;
        }

        // Input events
        switch (event.*.response_type & ~@as(u32, 0x80)) {
            c.XCB_KEY_PRESS => {
                const kev = @ptrCast(*c.xcb_key_press_event_t, event);
                updateKey(kev.*.detail, true);
            },
            c.XCB_KEY_RELEASE => {
                const kev = @ptrCast(*c.xcb_key_press_event_t, event);
                updateKey(kev.*.detail, false);
            },
            c.XCB_CLIENT_MESSAGE => {
                const cm = @ptrCast(*c.xcb_client_message_event_t, event);
                // Window close
                if (cm.*.data.data32[0] == wm_del) {
                    return false;
                }
            },
            else => continue,
        }
      _ = c.xcb_flush(connection);
    }
    return true;
}

pub fn deinit() void {
    _ = c.XAutoRepeatOn(display);
    _ = c.xcb_destroy_window(connection, window);
}
