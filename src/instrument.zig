const std = @import("std");
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
fn sampleSound(t: f64, env: envelope.ASDR, n: *notes.Note) f64 {
    //return env.getAmp(t, n) sample at point;
    // time since sample started playing
    const i = @mod(@floatToInt(usize, (t - n.on) / 44100.0), snare.len/4);
    const sample_bytes = [_]u8{snare[i], snare[i+1], snare[i+2], snare[i+3]};
    // index into sample array for appropriate sample
 //   const sample = @ptrCast([*]const f64, snare);
 //   var i = @floatToInt(usize, lifeTime / 44100.0);
 //   if (i > snare.len / 4) {
 //       n.active = false;
 //   }
 //   return sample[i];
    //return @bitCast(f64, sample_bytes);
    return 0.0;
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
