//! Play recorded sounds with a given note
//! also contains functions for loading wave files

const std = @import("std");
const fs = std.fs;
const Frame = @import("../sound/sound.zig").Frame;
const notes = @import("notes.zig");
const expect = std.testing.expect;

/// A wrapper over a slice of frames
/// will later contain settings for how to play the given sample
pub const Sample = struct {
    data: []Frame = &[_]Frame{},
};

/// A Sampler is an instrument which can play sounds from files
pub const Sampler = struct {
    /// volume of our instrument
    volume: f32 = 1.0,
    /// 16 samples to choose from
    samples: [16]Sample,
    /// allocator for storing these samples
    allocator: *std.mem.Allocator,

    const Self = @This();

    /// Create an empty sampler
    pub fn init(allocator: *std.mem.Allocator) !Self {
        return Self{
            .allocator = allocator,
            .volume = 1.0,
            .samples = [_]Sample{
                Sample{}, Sample{}, Sample{}, Sample{},
                Sample{}, Sample{}, Sample{}, Sample{},
                Sample{}, Sample{}, Sample{}, Sample{},
                Sample{}, Sample{}, Sample{}, Sample{},
            },
        };
    }

    /// shutdown this sampler, deallocates the samples in memory
    pub fn deinit(self: *Self) void {
        for (self.samples) |sample| {
            self.allocator.free(sample.data);
        }
    }

    /// play a sound!
    pub fn sound(self: Self, t: f64, n: *notes.Note) Frame {
        // get the sample we should be playing based on the note id
        const j: usize = n.id;

        const sample = self.samples[j];

        const lifeTime = t - n.on;
        // index into the sample based on the time
        const i = @floatToInt(usize, lifeTime * 44100);

        if (i >= sample.data.len) {
            n.active = false;
            return .{};
        }

        return sample.data[i].times(self.volume);
    }

    /// Replace the sample at index i with a sample under the file given
    pub fn replaceSample(self: *Self, i: usize, fname: []const u8) !void {
        // attempt to open the file
        const file = try fs.cwd().openFile(fname, fs.File.OpenFlags{ .read = true });
        defer file.close();

        // out of range error
        if (i > self.samples.len) return error.IndexOutOfRange;
        // create the new sample (do this first so that if it fails we won't have an empty sample
        var s = Sample{
            .data = try waveToFrames(file, self.allocator),
        };
        // deallocate the sample currently residing there
        self.allocator.free(self.samples[i].data);
        // replace
        self.samples[i] = s;
    }
};

/// Header layout of a wave file
const wave_header = packed struct {
    chunk_id: [4]u8, // (big)
    chunk_size: u32,
    format: [4]u8, // should be WAVE (big)
    // fmt
    fmt_id: [4]u8, // (big)
    fmt_size: u32,
    fmt: u16,
    n_channels: u16,
    sample_rate: u32,
    byte_rate: u32,
    block_align: u16,
    bits_per_sample: u16,
    // data
    data_id: [4]u8, // (big)
    data_size: u32,
};

/// Reads a wave header from a file reader and verifies that it correct
fn readWaveHeader(file: std.fs.File) !wave_header {
    // allocate on stack
    var header: wave_header = undefined;

    // read contents into header
    const b = try file.read(std.mem.asBytes(&header));
    // verify we got the whole thang
    if (b < @sizeOf(wave_header)) {
        return error.FileTooShort;
    }

    // verify RIFF
    if (!std.mem.eql(u8, &header.chunk_id, "RIFF")) {
        return error.NoRIFF;
    }
    // verify WAVE
    if (!std.mem.eql(u8, &header.format, "WAVE")) {
        return error.NoWAVE;
    }
    // verify fmt
    if (!std.mem.eql(u8, &header.fmt_id, "fmt ")) {
        return error.NoFMT;
    }
    // verify data
    if (!std.mem.eql(u8, &header.data_id, "data")) {
        return error.NoData;
    }

    return header;
}

/// read a file into a slice of frames
fn waveToFrames(file: std.fs.File, allocator: *std.mem.Allocator) ![]Frame {
    // TODO: handle mono samples
    // TODO: handle different sample sizes (rn only 16 bit)
    const header = try readWaveHeader(file);
    // allocate a buffer to read from file into
    var buf = try allocator.alloc(u8, header.data_size);
    defer allocator.free(buf);
    // seek to end of header
    try file.seekTo(@sizeOf(wave_header));
    // read into buffer
    _ = try file.read(buf);

    // header.data_size / NumChannels * BitsPerSample/8 = NumSamples 
    const num_samples = header.data_size / (header.n_channels * (header.bits_per_sample / 8));

    // allocate the number of frames we need (do not free)
    var frames = try allocator.alloc(Frame, num_samples);

    // convert and add frames
    var i: usize = 0;
    while (i < frames.len):(i+=1) {
        frames[i] = .{
            .l = @intToFloat(f32, @bitCast(i16, [_]u8{
                buf[0 + 4*i],
                buf[1 + 4*i]
            })) / 32767.0,

            .r = @intToFloat(f32, @bitCast(i16,[_]u8{
                buf[2 + 4*i], 
                buf[3 + 4*i],
            })) / 32767.0,
        };
    }

    return frames;
}

test "read wave header" {
    const file = try fs.cwd().openFile("./samples/Snare_01.wav", fs.File.OpenFlags{ .read = true });
    defer file.close();
    const header = try readWaveHeader(file);

    // check that the header size is correct
    try expect(@sizeOf(wave_header) == 44);

    // check that we have accurate information about the file

    // indicates that we are using a pcm
    try expect(header.fmt == 1);
    // sample rate should be 44100hz
    try expect(header.sample_rate == 44100);
    // should be 16 bits per sample
    try expect(header.bits_per_sample == 16);
    // should be stereo
    try expect(header.n_channels == 2);
}
