const std = @import("std");
const os = std.os;
const fs = std.fs;
const math = std.math;
const soundout = @import("soundout.zig");
const input = @import("input.zig");
const synth = @import("synth.zig");
const sampler = @import("sampler.zig");
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

var sinst: synth.Synth = synth.Bell();

const alloc = std.heap.page_allocator;
var allNotes: [input.key_states.len]notes.Note = undefined;

var ss: soundout.SoundOut = undefined;
var samp: sampler.Sampler = undefined;
fn makeNoise(t: f64) soundout.Frame {
    var frame: soundout.Frame = .{};
    for (allNotes) |*note| {
        if (note.active) {
            frame = frame.add(samp.sound(t, note));
        }
    }
    return frame;
}


pub fn main() anyerror!void {
    // read in a sample
    var s = try sampler.Sample.init("", alloc);
    defer s.deinit();
    std.log.info("frames: {}", .{s.data.len});

    samp = .{
        .volume = 0.8,
        .sample = s,
    };

    sinst.volume = 0.2;

    ss = soundout.SoundOut.init();

    ss.user_fn = makeNoise;

    try ss.setup();
    defer ss.deinit();

    try input.init();
    defer input.deinit();
    // note we are playing


    // setup notes array
    var i: usize = 0;
    while (i < 16) : (i+=1) { 
        allNotes[i] = .{.id = @intCast(u8, i), .active = false};
    }



    // change volue
    //sinst.volume = 0.1;

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
