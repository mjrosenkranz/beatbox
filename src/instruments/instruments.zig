const envelope = @import("envelope.zig");
pub const env = envelope.ASDR;

const notes = @import("notes.zig");
pub const Note = notes.Note;
pub const Scale = notes.Scale;

const oscillator = @import("oscillator.zig");
pub const osc = oscillator.osc;

const sampler = @import("sampler.zig");
pub const Sampler = sampler.Sampler;
pub const Sample = sampler.Sample;


const synth = @import("synth.zig");
pub const Synth = synth.Synth;
pub const Bell = synth.Bell;
