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

var ss: soundout.SoundOut = undefined;

fn makeNoise(t: f64) f64 {

    var mixedout: f64 = 0.0;
    for (allNotes) |*note| {
        if (note.active)
            mixedout += inst.sound(t, note);
    }
    return mixedout * 0.2;
}

const snare = @embedFile("../samples/Snare_s16le.raw");
const one = @embedFile("../samples/One-Shot.raw");
fn makeNoise2(t: f64) soundout.Frame {
    const len = @intToFloat(f64, snare.len);
    const i = @mod(@floatToInt(usize, t * 44100), snare.len/4);
    const snare_bytes = [_]u8{
        snare[0 + 4*i],
        snare[1 + 4*i], 
        snare[2 + 4*i], 
        snare[3 + 4*i],
    };

    const sample_bytes = [_]u8{
        one[0 + 4*i],
        one[1 + 4*i], 
        one[2 + 4*i], 
        one[3 + 4*i],
    };
    const i16s = @bitCast([2]i16, snare_bytes);
    //get number -1 to 1 for each i16
    var frame: soundout.Frame = .{
        .l = @intToFloat(f64, i16s[0]) / 65536.0,
        .r = @intToFloat(f64, i16s[1]) / 65536.0,
    };

    var mixedout: f64 = 0.0;
    for (allNotes) |*note| {
        if (note.active) {
            frame = frame.add(inst.sound(t, note));
        }
    }
    return frame;
}

pub fn main() anyerror!void {
    try input.init();
    defer input.deinit();
    // note we are playing
    ss = soundout.SoundOut.init();
    ss.user_fn = makeNoise2;
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
