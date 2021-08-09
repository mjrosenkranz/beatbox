const std = @import("std");
const expect = std.testing.expect;

const EventType = enum {
    NoteOn,
    NoteOff,
    // TODO: add more?
};

/// A buffer of a certain length in time of midi events
/// trying this a data oriented way
const MidiBuffer = struct {
    /// Allocator for growing and shrinking
    allocator: *std.mem.Allocator,

    /// number of notes we have so far
    len: usize = 0,

    /// type of event
    event_type: []EventType,
    /// the node that is being played,
    id: []u8,
    /// number of ticks since the beginning of this buffer
    start: []u32,
    /// number of ticks this note lasts
    duration: []u32,
    /// velocity of the note
    velocity: []u8,


    const Self = @This();

    /// number of elements to allocate at the beginning
    const start_amt = 10;

    /// Creat a new midibuffer
    /// this allocates the starting buffers with a size of 10 lets say
    pub fn init(allocator: *std.mem.Allocator) !Self {
        return Self{
            .allocator = allocator,
            .event_type = try allocator.alloc(EventType, start_amt),
            .start = try allocator.alloc(u32, start_amt),
            .duration = try allocator.alloc(u32, start_amt),
            .velocity = try allocator.alloc(u8, start_amt),
            .id = try allocator.alloc(u8, start_amt),
        };
    }

    /// Deallocates the midi buffer
    pub fn deinit(self: Self) void {
        self.allocator.free(self.event_type);
        self.allocator.free(self.start);
        self.allocator.free(self.duration);
        self.allocator.free(self.velocity);
        self.allocator.free(self.id);
    }

    /// Adds a new note
    /// We assume here that this note occured after all notes in the buffer or the same time
    pub fn pushBack(self: *Self, t: EventType, i: u8, s: u32, d: u32, v: u8) !void {
        // check if we have enough room
        if (self.len == self.event_type.len - 1) {
            return error.MidiBufferFull;
        }

        self.event_type[self.len] = t;
        self.id[self.len] = i;
        self.start[self.len] = s;
        self.duration[self.len] = d;
        self.velocity[self.len] = v;

        self.len += 1;
    }

    /// Insert a note at a given time
    /// If the time is greater than that of the last note then we append
    /// otherwise O(n) insert time because I'm lazy
    pub fn insert(self: *Self, t: EventType, i: u8, s: u32, d: u32, v: u8) !void {
        // check if we have enough room
        if (self.len == self.event_type.len - 1) {
            return error.MidiBufferFull;
        }

        // if there are no notes then we can just push it
        if (self.len == 0) {
            return self.pushBack(t, i, s, d, v);
        }

        // if the last note occurs before this one then we can just push it
        if (self.start[self.len] < s) {
            return self.pushBack(t, i, s, d, v);
        }

        // otherwise we need to find the last note that starts before this one
        // and move all the rest of the notes up

        // we can assume that the list is already sorted so far
        // TODO: binary search
        // for now finna do a lazy loop
        var counter: usize = 0;
        //var last_time: u32 = self.start[0];
        while (true) {
            if (self.start[counter] > s)
                break;
            counter += 1;
        }

        var j: usize = counter+1;
        var old_s = self.start[counter];
        self.start[counter] = s;
        //var old_t = self.event_type[i];
        //var old_i = self.id[i];
        //var old_d = self.duration[i];
        //var old_v = self.velocity[i];
        while(j <= self.len) : (j+=1) {
            const new_s = self.start[j];
            self.start[j] = old_s;
            old_s = new_s;
            //self.start[j+1] = ;
        }

        self.len += 1;
    }
};


test "init" {
    // create and destroy a midibuffer
    var buf = try MidiBuffer.init(std.testing.allocator);
    defer buf.deinit();
}

test "push" {
    // create and destroy a midibuffer
    var buf = try MidiBuffer.init(std.testing.allocator);
    defer buf.deinit();

    try expect(buf.len == 0);

    // add a note
    try buf.pushBack(.NoteOn, 60, 0, 8, 100);
    try expect(buf.len == 1);

    try expect(buf.event_type[0] == .NoteOn);
    try expect(buf.id[0] == 60);
    try expect(buf.start[0] == 0);
    try expect(buf.duration[0] == 8);
    try expect(buf.velocity[0] == 100);


    try buf.pushBack(.NoteOn, 54, 0, 8, 100);
    try buf.pushBack(.NoteOn, 54, 0, 8, 100);
    try buf.pushBack(.NoteOn, 54, 0, 8, 100);
    try buf.pushBack(.NoteOn, 54, 0, 8, 100);
    try buf.pushBack(.NoteOn, 54, 0, 8, 100);
    try buf.pushBack(.NoteOn, 54, 0, 8, 100);
    try buf.pushBack(.NoteOn, 54, 0, 8, 100);
    try buf.pushBack(.NoteOn, 54, 0, 8, 100);


    try std.testing.expectError(error.MidiBufferFull, buf.pushBack(.NoteOn, 54, 0, 8, 100));
}

test "insert" {

    // create and destroy a midibuffer
    var buf = try MidiBuffer.init(std.testing.allocator);
    defer buf.deinit();
    try buf.pushBack(.NoteOn, 60, 0, 8, 100);
    try buf.pushBack(.NoteOn, 60, 10, 8, 100);
    try buf.pushBack(.NoteOn, 60, 20, 8, 100);
    try buf.insert(.NoteOn, 50, 5, 8, 100);
    try expect(buf.start[0] == 0);
    try expect(buf.start[1] == 5);
    try expect(buf.start[2] == 10);
    try expect(buf.start[3] == 20);
}
