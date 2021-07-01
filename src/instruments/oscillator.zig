const std = @import("std");
const math = std.math;
//TODO: make this a struct


var r = std.rand.DefaultPrng.init(12345);
/// Types of oscillators we can use
const OscType = enum {
    /// normal sin wave
    sin,
    /// square wave
    sqr,
    /// triangle wave
    tri,
    /// analog saw wave
    asaw,
    /// digital saw wave
    dsaw,
    /// random noise
    noise,
};

/// angular velocity helper func
fn w(hertz: f64) callconv(.Inline) f64 {
    return 2.0 * math.pi * hertz;
}

/// An oscillator (duh)
pub const Oscillator = struct {
    /// The type of oscilator this is
    osc_type: OscType,
    // what octave is this targeting relative to the given one
    octave: i8 = 0,
    /// how much influence this osc has on the overal sound
    amplitude: f64 = 1.0,
    //TODO another oscilator to be an LFO?
    /// LFO is a struct of values for now at least
    lfo: struct {
        hertz: f64 = 0,
        amp: f64 = 0,
    } = .{.hertz=0, .amp =0},
    
    const Self = @This();

    pub fn val(self: Self, t: f64, hertz: f64) callconv(.Inline)  f64 {
        const freq = w(hertz) * t + self.lfo.amp * hertz * @sin(w(self.lfo.hertz) * t);
        //const freq = w(hertz) * t;
        return self.amplitude * switch (self.osc_type) {
            .sin => @sin(freq),
            .sqr => {
                if (@sin(freq) > 0) {
                    return 1 * self.amplitude;
                } else {
                    return 0 * self.amplitude;
                }
            },
            .tri => math.asin(@sin(freq)) * 2.0 / math.pi,
            .dsaw => (2.0 / math.pi) * (hertz * math.pi * @mod(t, 1.0/hertz) - (2.0 / math.pi)),
            .asaw => {
                // TODO: fix this
                var output: f64 = 0.0;
                var n: f64 = 0;
                while(n < 40) : (n+=1) {
                    output += (@sin(n * freq)) / n;
                }
                return output * (2.0 / math.pi) * self.amplitude;
            },
            .noise => r.random.float(f64),
        };
    }
};
