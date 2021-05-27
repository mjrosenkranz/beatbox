const std = @import("std");
const os = std.os;
const math = std.math;
const sound = @import("sound.zig");
const input = @import("input.zig");
const instrument = @import("instrument.zig");
const notes = @import("note.zig");

const keyboard = 
\\|   |   |   |   |   | |   |   |   |   | |   | |   |   |   |
\\|   | S |   |   | F | | G |   |   | J | | K | | L |   |   |
\\|   |___|   |   |___| |___|   |   |___| |___| |___|   |   |__
\\|     |     |     |     |     |     |     |     |     |     |
\\|  Z  |  X  |  C  |  V  |  B  |  N  |  M  |  ,  |  .  |  /  |
\\|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|
\\
;

var note: notes.Note = undefined;
var inst = instrument.bell.init();
/// osc for our sine wave
fn makeNoise(t: f64) f64 {
    //return myenv.getAmp(t) * osc.osc(freq*1.0, t, .sqr, 5.0, 0.01);
    return inst.sound(t, note) * 0.4;
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
                //@atomicStore(*notes.Note, &freq, baseFreq * std.math.pow(f64, d12thRootOf2, @intToFloat(f64, k)), .SeqCst);
                note.id = @intCast(u8, k);
                inst.env.noteOn(ss.getTime());
            }
            if (input.key_states[k] == .Released) {
                inst.env.noteOff(ss.getTime());
            }
        }

    }
}
