const std = @import("std");
const sound = @import("sound.zig");

/// the base frequency of A2
const baseFreq = 110.0;
/// The 12th root since we are using the western scale
const d12thRootOf2 = std.math.pow(f64, 2.0, 1.0 / 12.0);

var freq: f64 = undefined;
inline fn wav(x: f64) f64 {
    const y = @sin(2.0 * 3.14159 * freq * x);
    return y;
}

pub fn main() anyerror!void {
    // note we are playing
    var key: f64 = 12.0;
    freq = baseFreq * std.math.pow(f64, d12thRootOf2, key);
    var ss = sound.Sounder.init();
    ss.user_fn = wav;
    try ss.setup();
    defer ss.deinit();
    std.os.nanosleep(3, 0);
    freq = 110.0;
}
