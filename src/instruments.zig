const envelope = @import("instruments/envelope.zig");
pub const env = envelope.ASDR;

const notes = @import("instruments/notes.zig");
pub const Note = notes.Note;
pub const Scale = notes.Scale;

const oscillator = @import("instruments/oscillator.zig");
pub const osc = oscillator.osc;

const sampler = @import("instruments/sampler.zig");
pub const Sampler = sampler.Sampler;
pub const Sample = sampler.Sample;


const synth = @import("instruments/synth.zig");
pub const Synth = synth.Synth;
pub const Bell = synth.Bell;
