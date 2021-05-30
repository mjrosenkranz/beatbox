const soundout = @import("soundout.zig");
const notes = @import("notes.zig");

// TODO: functions for converting samples
pub const Sample = struct {
    // TODO change this to an array of frames
    data: [600076:0]u8 = @embedFile("../samples/snare.raw").*,
};

pub const Sampler = struct {
    volume: f64 = 1.0,
    sample: Sample,

    const Self = @This();
    pub fn sound(self: Self, t: f64, n: *notes.Note) soundout.Frame {
        const lifeTime = t - n.on;
        // index into the sample based on the time
        const i = @floatToInt(usize, lifeTime * 44100);

        if (i >= self.sample.data.len/4) {
            n.active = false;
            return .{};
        }

        const sample_bytes = [_]u8{
            self.sample.data[0 + 4*i],
            self.sample.data[1 + 4*i], 
            self.sample.data[2 + 4*i], 
            self.sample.data[3 + 4*i],
        };


        const i16s = @bitCast([2]i16, sample_bytes);

        //get number -1 to 1 for each i16
        var frame: soundout.Frame = .{
            .l = @intToFloat(f64, i16s[0]) / 65536.0,
            .r = @intToFloat(f64, i16s[1]) / 65536.0,
        };

        return frame.times(self.volume);
    }
};
