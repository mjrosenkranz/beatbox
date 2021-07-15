//! Keeps track of all notes being played and when they were played
//!
const std = @import("std");
const inst = @import("../instruments/instruments.zig");
const Instrumnet = inst.Instrument;
const Note = inst.Note;
const NoteEvent = note.NoteEvent;
const Allocator = std.mem.Allocator; 

const MAX_ACTIVE = 12;

pub const MidiTrack = struct {

    /// note events to play
    /// TODO: flesh this out better
    //buffer: MidiBuffer,

    notes: [MAX_ACTIVE]Note,

    const Self = @This();

    pub fn init() Self {
        return .{
            .notes = [_]Note{.{}} ** MAX_ACTIVE,
        };
    }

    /// update the state given the current time
    pub fn update(self: *Self, t: f64) void {
        // based on the time add notes to the active notes list
        self.notes[0] = Note{
            .id = 0,
            .on = 1,
            .off = 2,
            .active = true,
        };
    }
};

const MidiBuffer = struct {
    allocator: *Allocator,

    data: []NoteEvent,

    const Self = @This();

    pub fn init(allocator: *Allocator) Self {

    }
};

// A Track contains information for an instrument
//pub const Track = struct {
//    /// allocator for adding new data
//    allocator: *Allocator,
//
//    /// instrument to play
//    instrument: ?Instrument,
//
//    data: union {
//        /// Note on and off events
//        /// TODO: what kind of data structure works best?
//        /// Need to be able to insert new notes quickly
//        /// when editing or going back in time
//        events: std.arraylist(NoteEvent),
//        /// If this track is an audio clip then it is a frame
//        /// TODO: is this a waste of space?
//        frames: []Sample,
//    },
//
//    const Self = @This();
//
//    /// create a new instrument track
//    pub fn createInstrument(
//        allocator: *Allocator,
//        instrument: Instrument,
//    ) Self {
//        return .{
//            .data = .{.events = std.arraylist(NoteEvent).init(allocator)},
//        };
//    }
//
//    /// create a new audio track
//    pub fn createAudio(
//        allocator: *Allocator,
//    ) Self {
//        return .{
//            .data = .{.samples = [_]Sample },
//        };
//    }
//};
