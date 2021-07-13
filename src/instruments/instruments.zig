const envelope = @import("envelope.zig");
pub const env = envelope.ASDR;

const notes = @import("notes.zig");
pub const Note = notes.Note;
pub const Scale = notes.Scale;

const oscillator = @import("oscillator.zig");
pub const osc = oscillator.osc;

const sampler = @import("sampler.zig");
/// A sampler holds 16 samples
//pub const Sampler = sampler.Sampler(16);
pub const Sampler = sampler.Sampler;
/// A metronome has two samples, beats and measures
pub const Sample = sampler.Sample;


const synth = @import("synth.zig");
pub const Synth = synth.Synth;
pub const Bell = synth.Bell;

const Frame = @import("../frame.zig").Frame;
/// instrument interface
pub const Instrument = struct {
    volume: f32 = 1.0,
    soundFn: fn sound(self: *Self, t: f64, n: *Note) Frame,

    const Self = @This();

    pub fn sound(self: *Self, t: f64, n: *Note) Frame {
        return self.soundFn(self, t, n);
    }
};
