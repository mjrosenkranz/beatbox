const std = @import("std");
const os = std.os;
const math = std.math;
const soundout = @import("soundout.zig");
const input = @import("input.zig");
const instrument = @import("instrument.zig");
const notes = @import("notes.zig");

const keyboard = 
\\|   |   |   |   |   | |   |   |   |   | |   | |   |   |   |
\\|   | S |   |   | F | | G |   |   | J | | K | | L |   |   |
\\|   |___|   |   |___| |___|   |   |___| |___| |___|   |   |__
\\|     |     |     |     |     |     |     |     |     |     |
\\|  Z  |  X  |  C  |  V  |  B  |  N  |  M  |  ,  |  .  |  /  |
\\|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|
\\
;

var inst: instrument.Instrument = instrument.Bell();

const alloc = std.heap.page_allocator;
var allNotes: [input.key_states.len]notes.Note = undefined;

fn makeNoise(t: f64) f64 {
    var mixedout: f64 = 0.0;
    for (allNotes) |*note| {
        if (note.active)
            mixedout += inst.sound(t, note);
    }
    //mixedout = if (allNotes[3].active) inst.sound(t, &allNotes[3]) else 0.0;
    return mixedout * 0.2;
}

pub fn main() anyerror!void {
    try input.init();
    defer input.deinit();
    // note we are playing
    var ss = soundout.SoundOut.init();
    ss.user_fn = makeNoise;
    try ss.setup();
    defer ss.deinit();


    // setup notes array
    var i: usize = 0;
    while (i < input.key_states.len) : (i+=1) { 
        allNotes[i] = .{.id = @intCast(u8, i), .active = false};
    }

    // change volue
    inst.volume = 0.1;

    // TODO:clear screen and write the keyboard with other information
    // write our lil keyboard to the screen
    _ = try std.io.getStdErr().write(keyboard);

    var currKey: i8 = -1;
    var quit = false;
    while (!quit) {
        if (!input.update())
            quit = true;

        var k: usize = 0;
        while (k < input.key_states.len) : (k+=1) {
            if (input.key_states[k] == .Pressed) {
                allNotes[k].on = ss.getTime();
                allNotes[k].active = true;
            }
            if (input.key_states[k] == .Released) {
                allNotes[k].off = ss.getTime();
            }
        }
    }
}
