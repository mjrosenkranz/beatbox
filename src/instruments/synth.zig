const std = @import("std");
const Frame = @import("../sound.zig").Frame;
const envelope = @import("envelope.zig");
const notes = @import("notes.zig");
const osc = @import("oscillator.zig");

pub const Synth = struct {
    volume: f32 = 1.0,
    env: envelope.ASDR,
    soundFn: fn (t: f64, env: envelope.ASDR, n: *notes.Note) Frame,

    const Self = @This();
    pub fn sound(self: Self, t: f64, n: *notes.Note) Frame {
        return self.soundFn(t, self.env, n).times(self.volume);
    }
};

pub fn Bell() Synth {
    return .{
        .env = .{
            .attack  = 0.01,
            .decay   = 1.0,
            .release = 1.0,
        },
        .soundFn = bellSound,
    };
}

fn bellSound(t: f64, env: envelope.ASDR, n: *notes.Note) Frame {
    const val = env.getAmp(t, n) * (
        1.0 * osc.osc(t, notes.freqFromScale(.{.id=n.id, .octave=1}), .sin, .{.hertz=5.0, .amp =0.001}) +
        0.5 * osc.osc(t, notes.freqFromScale(.{.id=n.id, .octave=2}), .sin, .{}) +
        0.25 * osc.osc(t,notes.freqFromScale(.{.id=n.id, .octave=3}), .sin, .{})
    );

    return .{
        .l = @floatCast(f32, val),
        .r = @floatCast(f32, val),
    };
}
