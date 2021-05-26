const envelope = @import("envelope.zig");
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

    pub fn sound(self: Self, t: f64, freq: f64) f64 {
         //self.soundfn(t, freq);
        return self.env.getAmp(t) * (
            1.0 * osc.osc(freq * 2.0, t, .sin, 5.0, 0.001) +
            0.5 * osc.osc(freq * 3.0, t, .sin, 0.0, 0.0) +
            0.25 * osc.osc(freq * 4.0, t, .sin, 0.0, 0.0)
        );
    }
};
