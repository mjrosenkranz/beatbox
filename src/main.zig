const std = @import("std");
const os = std.os;
const fs = std.fs;
const math = std.math;

const sound = @import("sound/sound.zig");
const keyboard = @import("keyboard.zig");
const inst = @import("instruments/instruments.zig");
const seq = @import("sequencer.zig");

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

const heap = std.heap.page_allocator;
var allNotes: [keyboard.key_states.len]inst.Note = undefined;

var so: sound.output = undefined;
var sampler: inst.Sampler = undefined;
var sequencer = seq.Sequencer.init(120, 4, 8);

fn makeNoise(t: f64) sound.Frame {
    var f: sound.Frame = .{};
    // live notes
    for (allNotes) |*note| {
        if (note.active) {
            f = f.add(sampler.parent.sound(t, note));
        }
    }

    // sequencer notes
    for (sequencer.notes) |*note| {
        if (note.active) {
            f = f.add(sampler.parent.sound(t, note));
        }
    }
    return f;
}

pub fn main() anyerror!void {

    sampler = try inst.Sampler.init(heap);
    defer sampler.deinit();

    try sampler.replaceSample(0, "./samples/808.wav");
    try sampler.replaceSample(1, "./samples/kick.wav");
    try sampler.replaceSample(2, "./samples/snare.wav");
    try sampler.replaceSample(3, "./samples/rim.wav");
    try sampler.replaceSample(4, "./samples/clap.wav");
    try sampler.replaceSample(5, "./samples/ch.wav");
    try sampler.replaceSample(6, "./samples/perc.wav");
    try sampler.replaceSample(7, "./samples/bell.wav");

    // test the sequencer
    try sequencer.addTrack(&sampler.parent);

    so = sound.output {
        .frames = 256,
        .blocks = 4,
        .user_fn = makeNoise,
    };

    try so.setup();
    defer so.deinit();

    try keyboard.init();
    defer keyboard.deinit();

    // change the synth volume
    synth.volume = 0.2;

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
        if (!keyboard.update())
            quit = true;

        real_time = std.time.milliTimestamp();
        elapsed = @intToFloat(f64, (real_time - old_time))/1000;
        wall_time += elapsed;
        old_time = real_time;


        var k: usize = 0;
        while (k < keyboard.key_states.len) : (k+=1) {
            if (keyboard.key_states[k] == .Pressed) {
                allNotes[k].on = so.getTime();
                allNotes[k].active = true;
            }
            if (keyboard.key_states[k] == .Released) {
                allNotes[k].off = so.getTime();
            }
        }
        sequencer.update(elapsed, so.getTime());
    }
}
