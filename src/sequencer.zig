//! Keep track of time signature and play sounds I guess
const std = @import("std");
const instrument = @import("instruments/instruments.zig");
const Instrument = instrument.Instrument;
const Note = instrument.Note;
const Metronome = instrument.Metronome;
const Frame = @import("frame.zig").Frame;

const Track = struct {
    /// instrument on this track
    /// TODO: instrument base class?
    instrument: *Instrument,
    // TODO: datatype for track content
    // should it be midi?
};

pub const Sequencer = struct {
    /// Tracks for each instrument being played
    /// TODO: make number of tracks variable
    tracks: [1]Track = undefined,

    /// all currently active notes
    /// TODO: make notes a vector
    notes: [1]Note,

    /// metronome
    metronome: Metronome,

    /// should we be playing a sound on each beat
    metronome_on: bool = true,
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
    
    allocator: *std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: *std.mem.Allocator, tempo: f64, beats: u8, sub_beats: u8) !Self {
        var ret = Self{
            .allocator = allocator,
            .tempo = tempo,
            .beats = beats,
            .sub_beats = sub_beats,
            .beat_time = (60 / tempo) / @intToFloat(f64, sub_beats),
            .total_beats = beats * sub_beats,
            .notes = [_]Note{.{
                .id=0,
                // channel zero will be reserved for the metronome
                .channel=0,
            }},
            .metronome = try Metronome.init(allocator),
        };

        //TODO: should these be "baked in" to the program?
        try ret.metronome.replaceSample(0, "./assets/beat.wav");
        try ret.metronome.replaceSample(1, "./assets/measure.wav");

        return ret;
    }

    /// accumulator for keeping time between beats
    var acc: f64 = 0;
    /// current beat in this measure
    var current: u8 = 0;

    pub fn sound(self: *Self, t: f64) Frame {
        var f: Frame = .{};
        for (self.notes) |*note| {
            if (note.active and note.channel == 0 and self.metronome_on) {
                f = f.add(self.metronome.parent.sound(t, note));
            }
        }
        return f;
    }

    /// Play sounds needed at the corresponding time
    /// for now we will metronome it out
    /// dt is in WALL TIME (not CPU)
    pub fn update(self: *Self, dt: f64, cpu_time: f64) void {
        // add to acc
        acc += dt;
        // check if enough time has passed for a new beat
        while (acc >= self.beat_time) {
            // if so, we want to subtract beat time to maintain
            acc -= self.beat_time;
            // play a noise if we are a new whole beat
            if (current % self.sub_beats == 0) {
                self.notes[0].id = if (current == 0) 1 else 0;
                self.notes[0].active = true;
                self.notes[0].on = cpu_time;
            }

            // increase the current beat and wrap over
            current = (current + 1) % self.total_beats;
        }
    }

    /// Adds a track to the sequencer
    pub fn addTrack(self: *Self, inst: *Instrument) !void {
        self.tracks[0] = .{ .instrument = inst };
    }

    pub fn deinit(self: *Self) void {
        self.metronome.deinit();
    }
};
