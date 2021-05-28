const std = @import("std");
const soundout = @import("soundout.zig");
const envelope = @import("envelope.zig");
const notes = @import("notes.zig");
const osc = @import("oscillator.zig");

pub const Instrument = struct {
    volume: f64 = 1.0,
    env: envelope.ASDR,
    soundFn: fn (t: f64, env: envelope.ASDR, n: *notes.Note) soundout.Frame,

    const Self = @This();
    pub fn sound(self: Self, t: f64, n: *notes.Note) soundout.Frame {
        return self.soundFn(t, self.env, n).times(self.volume);
    }
};

//const snare = @embedFile("../samples/Snare_s8le.raw");
pub fn Sampler() Instrument {
    return .{
        .env = .{
            .attack  = 0.01,
            .decay   = 0.0,
            .sustainAmp = 1.0,
            .release = 0.0,
        },
        .soundFn = sampleSound,
    };
}

const snare = @embedFile("../samples/Snare_s16le.raw");
fn sampleSound(t: f64, env: envelope.ASDR, n: *notes.Note) soundout.Frame {
    //return env.getAmp(t, n) sample at point;
    // time since sample started playing

    return .{};
}

pub fn Bell() Instrument {
    return .{
        .env = .{
            .attack  = 0.01,
            .decay   = 1.0,
            .release = 1.0,
        },
        .soundFn = bellSound,
    };
}
fn bellSound(t: f64, env: envelope.ASDR, n: *notes.Note) soundout.Frame {
    const val = env.getAmp(t, n) * (
        1.0 * osc.osc(t, notes.freqFromScale(.{.id=n.id, .octave=1}), .sin, .{.hertz=5.0, .amp =0.001}) +
        0.5 * osc.osc(t, notes.freqFromScale(.{.id=n.id, .octave=2}), .sin, .{}) +
        0.25 * osc.osc(t,notes.freqFromScale(.{.id=n.id, .octave=3}), .sin, .{})
    );

    return .{
        .l = val,
        .r = val,
    };
}
