//! Keep track of time signature and play sounds I guess
const std = @import("std");

//const track = struct {
//    /// instrument on this track
//    /// TODO: instrument base class?
//    instrument: *opaque{},
//    // TODO: datatype for track content
//    // should it be midi?
//};

pub const Sequencer = struct {
    /// should we be playing a sound on each beat
    count_on: bool = true,
    /// beats per minute
    tempo: f64 = 120,
    /// beats per measure
    beats: u8,
    /// timing of a single beat
    sub_beats: u8,

    /// wall time for a single beat based on tempo
    beat_time: f64 = 0,
    /// total beats per measure (accounting for subbeats)
    total_beats: u8 = 0,

    const Self = @This();

    pub fn init(tempo: f64, beats: u8, sub_beats: u8) Self {
        return .{
            .tempo = tempo,
            .beats = beats,
            .sub_beats = sub_beats,
            .beat_time = (60 / tempo) / @intToFloat(f64, sub_beats),
            .total_beats = beats * sub_beats,
        };
    }

    /// accumulator for keeping time between beats
    var acc: f64 = 0;
    /// current beat in this measure
    var current: u8 = 0;

    /// Play sounds needed at the corresponding time
    /// for now we will metronome it out
    /// dt is in WALL TIME (not CPU)
    pub fn update(self: Self, dt: f64) void {
        // add to acc
        acc += dt;
        // check if enough time has passed for a new beat
        while (acc >= self.beat_time) {
            // if so, we want to subtract beat time to maintain
            acc -= self.beat_time;
            // increase the current beat and wrap over
            current += 1;
            if (current >= self.total_beats) {
                current = 0;
                std.log.info("new measure", .{});
            }
            // play a noise if we are a new whole beat
            if (current % self.sub_beats == 0) {
                std.log.info("beat", .{});
            }
        }
    }
};
