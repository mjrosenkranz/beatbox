const std = @import("std");
const os = std.os;
const math = std.math;
const sound = @import("sound.zig");
const input = @import("input.zig");
const osc = @import("oscillator.zig");
const env = @import("envelope.zig");

const keyboard = 
\\|   |   |   |   |   | |   |   |   |   | |   | |   |   |   |
\\|   | S |   |   | F | | G |   |   | J | | K | | L |   |   |
\\|   |___|   |   |___| |___|   |   |___| |___| |___|   |   |__
\\|     |     |     |     |     |     |     |     |     |     |
\\|  Z  |  X  |  C  |  V  |  B  |  N  |  M  |  ,  |  .  |  /  |
\\|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|
\\
;

pub var freq: f64 = 0.0;
/// the base frequency of A2
const baseFreq = 110.0;
/// The 12th root since we are using the western scale
const d12thRootOf2 = std.math.pow(f64, 2.0, 1.0 / 12.0);
var myenv: env.ASDR = .{};
/// osc for our sine wave
fn makeNoise(t: f64) f64 {
    //return myenv.getAmp(t) * osc.osc(freq, t, .sin);
    return myenv.getAmp(t) * osc.osc(freq*1.0, t, .sqr);
}

pub fn main() anyerror!void {
    try input.init();
    defer input.deinit();
    // note we are playing
    var ss = sound.Sounder.init();
    ss.user_fn = makeNoise;
    try ss.setup();
    defer ss.deinit();

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
                @atomicStore(f64, &freq, baseFreq * std.math.pow(f64, d12thRootOf2, @intToFloat(f64, k)), .SeqCst);
                myenv.noteOn(ss.getTime());
            }
            if (input.key_states[k] == .Released) {
                myenv.noteOff(ss.getTime());
            }
        }

    }
}
