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
fn w(hertz: f64) f64 {
    return 2.0 * math.pi * hertz;
}

pub fn osc(t: f64, hertz: f64, oscType: OscType, LFOHertz: f64, LFOAmp: f64) f64 {
    const freq = w(hertz) * t + LFOAmp * hertz * @sin(w(LFOHertz) * t);
    return switch (oscType) {
        .sin => @sin(freq),
        .sqr => {
            if (@sin(freq) > 0) {
                return 1;
            } else {
                return 0;
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
            return output * (2.0 / math.pi);
        },
        .noise => r.random.float(f64),
    };
}
