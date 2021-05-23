const std = @import("std");
const sound = @import("sound.zig");

const freq: f64 = 440.0;
inline fn wav(x: f64) f64 {
    const y = @sin(2.0 * 3.14159 * freq * x);
    return y;
}

pub fn main() anyerror!void {
    var ss = sound.Sounder.init();
    ss.user_fn = wav;
    try ss.setup();
    defer ss.deinit();
    ss.loop();
    return;
}
