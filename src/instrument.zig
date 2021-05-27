const envelope = @import("envelope.zig");
const notes = @import("note.zig");
const osc = @import("oscillator.zig");

//    env: envelope.ASDR,
//    ) type {
pub const bell = struct {
    volume: f64 = 0.0,
    env: envelope.ASDR,
    //soundfn:  fn (t: f64, f: f64) f64,
    const Self = @This();

    pub fn init() Self {
        return .{
            .env = .{
                .attack  = 0.01,
                .decay   = 1.0,
                .release = 1.0,
            },
        };
    }

    pub fn sound(self: Self, t: f64, n: notes.Note) f64 {
         //self.soundfn(t, freq);
        return self.env.getAmp(t) * (
            1.0 * osc.osc(t, notes.freqFromScale(n.id + 12, .chromatic), .sin, 5.0, 0.001) +
            0.5 * osc.osc(t, notes.freqFromScale(n.id + 24, .chromatic), .sin, 0.0, 0.0) +
            0.25 * osc.osc(t,notes.freqFromScale(n.id + 36, .chromatic), .sin, 0.0, 0.0)
        );
    }
};
