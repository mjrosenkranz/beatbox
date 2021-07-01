const std = @import("std");
const Frame = @import("../sound.zig").Frame;
const envelope = @import("envelope.zig");
const notes = @import("notes.zig");
const osc = @import("oscillator.zig");

pub const Synth = struct {
    /// The volume of this synth
    volume: f32 = 1.0,
    /// Envelope that controls the way the amplitude of this synth
    env: envelope.ASDR,
    /// Oscilators that this synth uses to generate sound
    /// TODO: should this be a slice or array?
    oscilators: [3]osc.Oscillator,

    const Self = @This();

    /// Return the amplitude of this synth for the given note at the given time
    pub fn sound(self: Self, t: f64, n: *notes.Note) Frame {
        // build the sound
        // start with nothin
        var val: f64 = 0.0;

        // use all the oscillators that this synth has
        for (self.oscilators) |o| {
            val += o.amplitude * o.val(t, notes.freqFromScale(.{.id=n.id, .octave=o.octave}));
        }

        // add envelope
        val *= self.env.getAmp(t, n);

        return .{
            .l = @floatCast(f32, val),
            .r = @floatCast(f32, val),
        };
    }
};

pub fn Bell() Synth {
    return .{
        .env = .{
            .attack  = 0.01,
            .decay   = 1.0,
            .release = 1.0,
        },
        .oscilators = [_]osc.Oscillator{
            .{
                .osc_type = .sin,
            },
            .{
                .osc_type = .sin,
                .amplitude = 0.5,
                .octave = 2,
            },
            .{
                .osc_type = .sin,
                .amplitude = 0.25,
                .octave = 3,
            },
        },
    };
}
//
//fn bellSound(t: f64, env: envelope.ASDR, n: *notes.Note) Frame {
//    const val = env.getAmp(t, n) * (
//        1.0 * osc.osc(t, notes.freqFromScale(.{.id=n.id, .octave=1}), .sin, .{.hertz=5.0, .amp =0.001}) +
//        0.5 * osc.osc(t, notes.freqFromScale(.{.id=n.id, .octave=2}), .sin, .{}) +
//        0.25 * osc.osc(t,notes.freqFromScale(.{.id=n.id, .octave=3}), .sin, .{})
//    );
//
//    return .{
//        .l = @floatCast(f32, val),
//        .r = @floatCast(f32, val),
//    };
//}
