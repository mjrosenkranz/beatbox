const std = @import("std");
const fs = std.fs;
const Frame = @import("../sound.zig").Frame;
const notes = @import("notes.zig");

// TODO: functions for converting samples
pub const Sample = struct {
    // TODO change this to an array of frames
    data: []Frame = undefined,
    alloc: *std.mem.Allocator,

    const Self = @This();

    pub fn init(filename: []const u8, a: *std.mem.Allocator) !Self {
        var ret = Self{
            .alloc = a,
        };

        const snareFile = try fs.cwd().openFile(filename, fs.File.OpenFlags{ .read = true });
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

    pub fn deinit(self: Self) void {
        self.alloc.free(self.data);
    }
};

pub const Sampler = struct {
    volume: f32 = 1.0,
    sample: Sample,

    const Self = @This();
    pub fn sound(self: Self, t: f64, n: *notes.Note) Frame {
        const lifeTime = t - n.on;
        // index into the sample based on the time
        const i = @floatToInt(usize, lifeTime * 44100);

        if (i >= self.sample.data.len) {
            n.active = false;
            return .{};
        }

        return self.sample.data[i].times(self.volume);
    }
};
