const std = @import("std");
const os = std.os;
const fs = std.fs;
const math = std.math;

const Frame = @import("frame.zig").Frame;
const platform = @import("platform/platform.zig");
const inst = @import("instruments/instruments.zig");
const Metronome = @import("time/time.zig").Metronome;

const kbstr = 
\\|   |   |   |   |   | |   |   |   |   | |   | |   |   |   |
\\|   | S |   |   | F | | G |   |   | J | | K | | L |   |   |
\\|   |___|   |   |___| |___|   |   |___| |___| |___|   |   |__
\\|     |     |     |     |     |     |     |     |     |     |
\\|  Z  |  X  |  C  |  V  |  B  |  N  |  M  |  ,  |  .  |  /  |
\\|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|
\\
;

var synth: inst.Synth = inst.Bell();

const alloc = std.heap.page_allocator;
var allNotes: [16]inst.Note = undefined;

var so: platform.Output = undefined;
var sampler: inst.Sampler(16) = undefined;

var metronome_sampler: inst.Sampler(2) = undefined;
var metronome: Metronome = undefined;

fn makeNoise(t: f64) Frame {
    var f: Frame = .{};
    // live notes
    for (allNotes) |*note| {
        if (note.active) {
            f = f.add(sampler.parent.sound(t, note));
        }
    }

    
    // play a metronome noise
    if (metronome.note.active) {
        f = f.add(metronome_sampler.parent.sound(t, &metronome.note));
    }

    return f;
}

pub fn main() anyerror!void {

    so = platform.Output {
        .frames = 256,
        .blocks = 4,
        .user_fn = makeNoise,
    };


    sampler = try inst.Sampler(16).init(alloc);
    defer sampler.deinit();

    try sampler.replaceSample(0, "./samples/808.wav");
    try sampler.replaceSample(1, "./samples/kick.wav");
    try sampler.replaceSample(2, "./samples/snare.wav");
    try sampler.replaceSample(3, "./samples/rim.wav");
    try sampler.replaceSample(4, "./samples/clap.wav");
    try sampler.replaceSample(5, "./samples/ch.wav");
    try sampler.replaceSample(6, "./samples/perc.wav");
    try sampler.replaceSample(7, "./samples/bell.wav");

    metronome = Metronome.init(90, 4, 4);
    metronome_sampler = try inst.Sampler(2).init(alloc);
    try metronome_sampler.replaceSample(0, "./assets/beat.wav");
    try metronome_sampler.replaceSample(1, "./assets/measure.wav");
    defer metronome_sampler.deinit();

    try so.setup();
    defer so.deinit();

    try platform.backend.init();
    defer platform.backend.deinit();


    // change the synth volume
    synth.volume = 0.2;

    metronome_sampler.volume = 1.0;

    // setup notes array
    var i: usize = 0;
    while (i < 16) : (i+=1) { 
        allNotes[i] = .{.id = @intCast(u8, i), .active = false};
    }

    // TODO:clear screen and write the keyboard with other information
    // write our lil keyboard to the screen
    _ = try std.io.getStdErr().write(kbstr);
    //std.log.info("cp: {d:.2} wall: {d:.2} latency: {d:.4}", .{so.gTime, wall_time, wall_time - so.gTime});

    var currKey: i8 = -1;
    var quit = false;
    var wall_time: f64 = 0;
    var old_time: i64 = std.time.milliTimestamp();
    var real_time: i64 = std.time.milliTimestamp();
    var elapsed: f64 = 0;
    while (!quit) {
        if (!platform.backend.update())
            quit = true;

        real_time = std.time.milliTimestamp();
        elapsed = @intToFloat(f64, (real_time - old_time))/1000;
        wall_time += elapsed;
        old_time = real_time;

        metronome.update(elapsed, so.getTime());

        var k: usize = 0;
        while (k < platform.backend.key_states.len) : (k+=1) {
            if (platform.backend.key_states[k] == .Pressed) {
                allNotes[k].on = so.getTime();
                allNotes[k].active = true;
            }
            if (platform.backend.key_states[k] == .Released) {
                allNotes[k].off = so.getTime();
            }
        }

        // display stuff TODO: make an another thread?
        //platform.backend.draw();
    }
}
