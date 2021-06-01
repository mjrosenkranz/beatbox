const math = @import("std").math;
/// A note in an instrument
pub const Note = struct {
    /// the position of the notes in our scale
    id: u8 = 0,
    /// on time
    on: f64 = 0.0,
    /// off time
    off: f64 = 0.0,
    /// is the note active?
    active: bool = false,
    /// what instrument are we sending to?
    channel: u8 = 0,
};

pub const Scale = enum {
    chromatic,
};

pub fn freqFromScale(args: struct {id: u8, scale: Scale = .chromatic, octave: u8 = 0}) f64 {
    return switch (args.scale) {
        .chromatic => 256 * math.pow(f64, 1.0594630943592952645618252949463, @intToFloat(f64, args.id + 12 * args.octave)),
        //else => unreachable,
    };
}
