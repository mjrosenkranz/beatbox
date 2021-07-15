//! Notes for working with music.
//! so far only have chromatic scale but we can expand from here
const math = @import("std").math;
/// A note in an scale
pub const Note = struct {
    /// the position of the notes in our scale
    /// TODO: default to 60
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

pub fn freqFromScale(args: struct {id: u8, scale: Scale = .chromatic, octave: i8 = 0}) f64 {
    return switch (args.scale) {
        .chromatic => 256 * math.pow(f64, 1.0594630943592952645618252949463, @intToFloat(f64, @intCast(i8, args.id) + 12 * args.octave)),
        //else => unreachable,
    };
}

pub const NoteEvent = union(enum) {
    /// Time the note was pressed
    NoteOn: f64,
    NoteOff: f64,
};
