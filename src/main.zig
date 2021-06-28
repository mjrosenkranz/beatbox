const std = @import("std");
const os = std.os;
const fs = std.fs;
const math = std.math;

const sound = @import("sound.zig");
const keyboard = @import("keyboard.zig");
const inst = @import("instruments.zig");

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

var ss: sound.output = undefined;
var sampler: inst.Sampler = undefined;

fn makeNoise(t: f64) sound.Frame {
    var f: sound.Frame = .{};
    for (allNotes) |*note| {
        if (note.active) {
            f = f.add(sampler.sound(t, note));
        }
    }
    return f;
}

pub fn main() anyerror!void {

    sampler = try inst.Sampler.init(heap);
    defer sampler.deinit();

    try sampler.replaceSample(0, "./samples/snare.raw");

    ss = sound.output.init();
    ss.user_fn = makeNoise;

    try ss.setup();
    defer ss.deinit();

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
    //_ = try std.io.getStdErr().write(kbstr);
    //std.log.info("cp: {d:.2} wall: {d:.2} latency: {d:.4}", .{ss.gTime, wall_time, wall_time - ss.gTime});

    var currKey: i8 = -1;
    var quit = false;
    var wall_time: f64 = 0;
    var old_time: i64 = std.time.milliTimestamp();
    var real_time: i64 = std.time.milliTimestamp();
    while (!quit) {
        if (!keyboard.update())
            quit = true;

        real_time = std.time.milliTimestamp();
        wall_time += @intToFloat(f64, (real_time - old_time))/1000;
        old_time = real_time;

        var k: usize = 0;
        while (k < keyboard.key_states.len) : (k+=1) {
            if (keyboard.key_states[k] == .Pressed) {
                allNotes[k].on = ss.getTime();
                allNotes[k].active = true;
            }
            if (keyboard.key_states[k] == .Released) {
                allNotes[k].off = ss.getTime();
            }
        }

    }
}
