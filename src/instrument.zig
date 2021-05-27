const envelope = @import("envelope.zig");
const notes = @import("note.zig");
const osc = @import("oscillator.zig");

pub const Instrument = struct {
    volume: f64 = 1.0,
    env: envelope.ASDR,
    soundFn: fn (t: f64, env: envelope.ASDR, n: notes.Note) f64,

    const Self = @This();
    pub fn sound(self: Self, t: f64, n: notes.Note) f64 {
        return self.soundFn(t, self.env, n) * self.volume;
    }
};

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
fn bellSound(t: f64, env: envelope.ASDR, n: notes.Note) f64 {
    return env.getAmp(t) * (
        1.0 * osc.osc(t, notes.freqFromScale(n.id + 12, .chromatic), .sin, 5.0, 0.001) +
        0.5 * osc.osc(t, notes.freqFromScale(n.id + 24, .chromatic), .sin, 0.0, 0.0) +
        0.25 * osc.osc(t,notes.freqFromScale(n.id + 36, .chromatic), .sin, 0.0, 0.0)
    );
}
