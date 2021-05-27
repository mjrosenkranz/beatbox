const envelope = @import("envelope.zig");
const notes = @import("notes.zig");
const osc = @import("oscillator.zig");

pub const Instrument = struct {
    volume: f64 = 1.0,
    env: envelope.ASDR,
    soundFn: fn (t: f64, env: envelope.ASDR, n: *notes.Note) f64,

    const Self = @This();
    pub fn sound(self: Self, t: f64, n: *notes.Note) f64 {
        return self.soundFn(t, self.env, n) * self.volume;
    }
};

pub fn Test() Instrument {
    return .{
        .env = .{
            .attack  = 0.01,
            .decay   = 1.0,
            .release = 1.0,
        },
        .soundFn = testSound,
    };
}

fn testSound(t: f64, env: envelope.ASDR, n: *notes.Note) f64 {
    return env.getAmp(t, n) * osc.osc(t, notes.freqFromScale(.{.id=n.id, .octave=1}), .asaw, .{});
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
fn bellSound(t: f64, env: envelope.ASDR, n: *notes.Note) f64 {
    return env.getAmp(t, n) * (
        1.0 * osc.osc(t, notes.freqFromScale(.{.id=n.id, .octave=1}), .sin, .{.hertz=5.0, .amp =0.001}) +
        0.5 * osc.osc(t, notes.freqFromScale(.{.id=n.id, .octave=2}), .sin, .{}) +
        0.25 * osc.osc(t,notes.freqFromScale(.{.id=n.id, .octave=3}), .sin, .{})
    );
}
