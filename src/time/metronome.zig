const std = @import("std");
const expect = std.testing.expect;
const Note = @import("../instruments/notes.zig").Note;

pub const Metronome = struct {
    /// current subbeat in this measure
    var current: u8 = 0;
    /// wall time for a single beat based on tempo
    var beat_time: f64 = 0;
    /// total beats per measure (accounting for subbeats)
    var total_beats: u8 = 0;
    /// sub_beats
    var sbeats: u8 = 0;
    /// number of beats
    var nbeats: u8 = 0;
    /// accumulator for keeping time between beats
    var acc: f64 = 0;

    const Self = @This();

    /// beat the metronome is on
    beat: u8 = 0,
    /// measure the metronome is on
    measure: u8 = 1,

    /// note to play based on the time
    note: Note = .{},

    time: f64 = 0,

    pub fn init(
        /// sampler for playing the metronome sounds
        //samp: Sampler(2),
        /// beats per minute
        tempo: f64,
        /// beats per measure
        beats: u8,
        /// timing of a single beat
        sub_beats: u8,
    ) Self {
        beat_time = (60 / tempo) / @intToFloat(f64, sub_beats);
        total_beats = beats * sub_beats;
        sbeats = sub_beats;
        nbeats = beats;

        return Self { };
    }

    /// dt is in walltime
    pub fn update(self: *Self, dt: f64, cpu_time: f64) void {
        // add to acc
        acc += dt;
        self.time += dt;
        // check if enough time has passed for a new beat
        while (acc >= beat_time) {
            // if so, we want to subtract beat time to maintain the difference
            acc -= beat_time;

            // a new beat
            if (current % sbeats == 0) {
                self.beat += 1;

                if (self.beat > nbeats) {
                    // 1 is the measure
                    self.beat = 1;
                    self.measure += 1;
                }

                self.note.id = if (self.beat == 1) 1 else 0;
                self.note.active = true;
                self.note.on = cpu_time;
            }

            // increase the current beat and wrap over
            current = (current + 1) % total_beats;
        }
    }
};

test "60 bpm 4/4" {
    var m = Metronome.init(60, 4, 4);
    try expect(m.beat == 0);
    m.update(1, 0);
    try expect(m.beat == 1);
    m.update(1, 0);
    try expect(m.beat == 2);
    m.update(1, 0);
    try expect(m.beat == 3);
    m.update(1, 0);
    try expect(m.beat == 4);
    m.update(1, 0);
    try expect(m.beat == 1);
}

test "60 bpm 3/6" {
    var m = Metronome.init(60, 3, 6);
    try expect(m.beat == 0);
    m.update(1, 0);
    try expect(m.beat == 1);
    m.update(1, 0);
    try expect(m.beat == 2);
    m.update(1, 0);
    try expect(m.beat == 3);
    m.update(1, 0);
    try expect(m.beat == 1);
}

test "measures" {
    var m = Metronome.init(60, 4, 4);
    try expect(m.beat == 0);
    try expect(m.measure == 1);
    m.update(5, 0);
    try expect(m.beat == 1);
    try expect(m.measure == 2);
}
