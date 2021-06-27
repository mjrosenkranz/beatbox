const std = @import("std");
const fs = std.fs;
const Frame = @import("../sound.zig").Frame;
const notes = @import("notes.zig");

// TODO: functions for converting samples
pub const Sample = struct {
    data: []Frame = undefined,

    const Self = @This();

    pub fn empty() Self {
        return .{
            .data = &[_]Frame{},
        };
    }

    pub fn init(fname: []const u8, a: *std.mem.Allocator) !Self {
        var ret = Self{ };

        const snareFile = try fs.cwd().openFile(fname, fs.File.OpenFlags{ .read = true });
        defer snareFile.close();
        const reader = snareFile.reader;
        const stat = try snareFile.stat();

        ret.data = try a.alloc(Frame, stat.size/@sizeOf(Frame));
        var buf = try a.alloc(u8, stat.size);

        defer a.free(buf);
        _ = try snareFile.readAll(buf);

        var i: usize = 0;
        while (i < ret.data.len):(i+=1) {
            ret.data[i] = .{
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

        return ret;
    }
};

pub const Sampler = struct {
    volume: f32 = 1.0,
    samples: [16]Sample,
    allocator: *std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: *std.mem.Allocator) !Self {
        return Self{
            .allocator = allocator,
            .volume = 1.0,
            .samples = [_]Sample{
                Sample.empty(), Sample.empty(), Sample.empty(), Sample.empty(),
                Sample.empty(), Sample.empty(), Sample.empty(), Sample.empty(),
                Sample.empty(), Sample.empty(), Sample.empty(), Sample.empty(),
                Sample.empty(), Sample.empty(), Sample.empty(), Sample.empty(),
            },
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.samples) |sample| {
            self.allocator.free(sample.data);
        }
    }

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
        // out of range error
        if (i > self.samples.len) return error.IndexOutOfRange;
        // create the new sample (do this first so that if it fails we won't have an empty sample
        var s = try Sample.init(fname, self.allocator);
        // deallocate the sample currently residing there
        self.allocator.free(self.samples[i].data);
        // replace
        self.samples[i] = s;
    }
};
